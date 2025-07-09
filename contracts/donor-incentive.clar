;; Donor Incentive Contract
;; Rewards regular blood donation participation with tokens

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_DONOR_NOT_FOUND (err u401))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_INVALID_AMOUNT (err u403))
(define-constant ERR_MILESTONE_NOT_REACHED (err u404))

;; Reward amounts
(define-constant BASE_DONATION_REWARD u100)
(define-constant MILESTONE_5_REWARD u500)
(define-constant MILESTONE_10_REWARD u1200)
(define-constant MILESTONE_25_REWARD u3000)
(define-constant MILESTONE_50_REWARD u7500)

;; Token supply
(define-constant TOTAL_SUPPLY u1000000000) ;; 1 billion tokens

;; Data structures
(define-map donor-rewards
  { donor-id: principal }
  {
    total-earned: uint,
    available-balance: uint,
    total-redeemed: uint,
    last-reward-time: uint,
    milestone-level: uint,
    bonus-multiplier: uint
  }
)

(define-map reward-history
  { transaction-id: uint }
  {
    donor-id: principal,
    reward-type: (string-ascii 20),
    amount: uint,
    timestamp: uint,
    donation-count: uint
  }
)

(define-map milestone-achievements
  { donor-id: principal, milestone: uint }
  {
    achieved-at: uint,
    reward-claimed: bool,
    donation-count: uint
  }
)

(define-data-var next-transaction-id uint u1)
(define-data-var total-rewards-distributed uint u0)

;; Public functions

;; Reward donor for successful donation
(define-public (reward-donation
  (donor-id principal)
  (donation-count uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (let ((reward-amount (calculate-donation-reward donor-id donation-count)))
      (match (map-get? donor-rewards { donor-id: donor-id })
        existing-rewards
        (begin
          (map-set donor-rewards
            { donor-id: donor-id }
            (merge existing-rewards {
              total-earned: (+ (get total-earned existing-rewards) reward-amount),
              available-balance: (+ (get available-balance existing-rewards) reward-amount),
              last-reward-time: block-height
            })
          )
          (record-reward-transaction donor-id "donation" reward-amount donation-count)
          (check-and-award-milestones donor-id donation-count)
          (var-set total-rewards-distributed
            (+ (var-get total-rewards-distributed) reward-amount))
          (ok reward-amount)
        )
        ;; Initialize new donor rewards
        (begin
          (map-set donor-rewards
            { donor-id: donor-id }
            {
              total-earned: reward-amount,
              available-balance: reward-amount,
              total-redeemed: u0,
              last-reward-time: block-height,
              milestone-level: u0,
              bonus-multiplier: u100
            }
          )
          (record-reward-transaction donor-id "donation" reward-amount donation-count)
          (var-set total-rewards-distributed
            (+ (var-get total-rewards-distributed) reward-amount))
          (ok reward-amount)
        )
      )
    )
    ERR_UNAUTHORIZED
  )
)

;; Claim milestone reward
(define-public (claim-milestone-reward (milestone uint))
  (let ((milestone-key { donor-id: tx-sender, milestone: milestone }))
    (match (map-get? milestone-achievements milestone-key)
      achievement-data
      (if (get reward-claimed achievement-data)
        (err u405) ;; Already claimed
        (let ((reward-amount (get-milestone-reward-amount milestone)))
          (match (map-get? donor-rewards { donor-id: tx-sender })
            donor-data
            (begin
              (map-set donor-rewards
                { donor-id: tx-sender }
                (merge donor-data {
                  total-earned: (+ (get total-earned donor-data) reward-amount),
                  available-balance: (+ (get available-balance donor-data) reward-amount)
                })
              )
              (map-set milestone-achievements
                milestone-key
                (merge achievement-data { reward-claimed: true })
              )
              (record-reward-transaction tx-sender "milestone" reward-amount milestone)
              (ok reward-amount)
            )
            ERR_DONOR_NOT_FOUND
          )
        )
      )
      ERR_MILESTONE_NOT_REACHED
    )
  )
)

;; Transfer rewards between donors
(define-public (transfer-rewards
  (recipient principal)
  (amount uint))
  (if (> amount u0)
    (match (map-get? donor-rewards { donor-id: tx-sender })
      sender-data
      (if (>= (get available-balance sender-data) amount)
        (match (map-get? donor-rewards { donor-id: recipient })
          recipient-data
          (begin
            ;; Update sender balance
            (map-set donor-rewards
              { donor-id: tx-sender }
              (merge sender-data {
                available-balance: (- (get available-balance sender-data) amount)
              })
            )
            ;; Update recipient balance
            (map-set donor-rewards
              { donor-id: recipient }
              (merge recipient-data {
                available-balance: (+ (get available-balance recipient-data) amount)
              })
            )
            (ok true)
          )
          ;; Initialize recipient if not exists
          (begin
            (map-set donor-rewards
              { donor-id: recipient }
              {
                total-earned: amount,
                available-balance: amount,
                total-redeemed: u0,
                last-reward-time: block-height,
                milestone-level: u0,
                bonus-multiplier: u100
              }
            )
            (map-set donor-rewards
              { donor-id: tx-sender }
              (merge sender-data {
                available-balance: (- (get available-balance sender-data) amount)
              })
            )
            (ok true)
          )
        )
        ERR_INSUFFICIENT_BALANCE
      )
      ERR_DONOR_NOT_FOUND
    )
    ERR_INVALID_AMOUNT
  )
)

;; Redeem rewards (mark as used)
(define-public (redeem-rewards (amount uint))
  (if (> amount u0)
    (match (map-get? donor-rewards { donor-id: tx-sender })
      donor-data
      (if (>= (get available-balance donor-data) amount)
        (begin
          (map-set donor-rewards
            { donor-id: tx-sender }
            (merge donor-data {
              available-balance: (- (get available-balance donor-data) amount),
              total-redeemed: (+ (get total-redeemed donor-data) amount)
            })
          )
          (record-reward-transaction tx-sender "redemption" amount u0)
          (ok true)
        )
        ERR_INSUFFICIENT_BALANCE
      )
      ERR_DONOR_NOT_FOUND
    )
    ERR_INVALID_AMOUNT
  )
)

;; Read-only functions

;; Check donor reward balance
(define-read-only (check-rewards (donor-id principal))
  (map-get? donor-rewards { donor-id: donor-id })
)

;; Get reward transaction history
(define-read-only (get-reward-history (transaction-id uint))
  (map-get? reward-history { transaction-id: transaction-id })
)

;; Check milestone achievement
(define-read-only (check-milestone (donor-id principal) (milestone uint))
  (map-get? milestone-achievements { donor-id: donor-id, milestone: milestone })
)

;; Get total rewards distributed
(define-read-only (get-total-distributed)
  (var-get total-rewards-distributed)
)

;; Calculate potential reward for donation count
(define-read-only (calculate-potential-reward (donor-id principal) (donation-count uint))
  (ok (calculate-donation-reward donor-id donation-count))
)

;; Get available milestones for donor
(define-read-only (get-available-milestones (donor-id principal))
  (match (map-get? donor-rewards { donor-id: donor-id })
    donor-data
    (ok (filter-available-milestones (get milestone-level donor-data)))
    ERR_DONOR_NOT_FOUND
  )
)

;; Private functions

;; Calculate reward amount based on donation count and multipliers
(define-private (calculate-donation-reward (donor-id principal) (donation-count uint))
  (match (map-get? donor-rewards { donor-id: donor-id })
    donor-data
    (let ((base-reward BASE_DONATION_REWARD)
          (multiplier (get bonus-multiplier donor-data))
          (loyalty-bonus (calculate-loyalty-bonus donation-count)))
      (/ (* (+ base-reward loyalty-bonus) multiplier) u100)
    )
    BASE_DONATION_REWARD
  )
)

;; Calculate loyalty bonus based on donation count
(define-private (calculate-loyalty-bonus (donation-count uint))
  (if (>= donation-count u50)
    u200
    (if (>= donation-count u25)
      u150
      (if (>= donation-count u10)
        u100
        (if (>= donation-count u5)
          u50
          u0
        )
      )
    )
  )
)

;; Record reward transaction
(define-private (record-reward-transaction
  (donor-id principal)
  (reward-type (string-ascii 20))
  (amount uint)
  (donation-count uint))
  (let ((transaction-id (var-get next-transaction-id)))
    (map-set reward-history
      { transaction-id: transaction-id }
      {
        donor-id: donor-id,
        reward-type: reward-type,
        amount: amount,
        timestamp: block-height,
        donation-count: donation-count
      }
    )
    (var-set next-transaction-id (+ transaction-id u1))
    transaction-id
  )
)

;; Check and award milestone achievements
(define-private (check-and-award-milestones (donor-id principal) (donation-count uint))
  (begin
    (if (and (>= donation-count u5) (is-none (map-get? milestone-achievements { donor-id: donor-id, milestone: u5 })))
      (award-milestone donor-id u5 donation-count)
      true
    )
    (if (and (>= donation-count u10) (is-none (map-get? milestone-achievements { donor-id: donor-id, milestone: u10 })))
      (award-milestone donor-id u10 donation-count)
      true
    )
    (if (and (>= donation-count u25) (is-none (map-get? milestone-achievements { donor-id: donor-id, milestone: u25 })))
      (award-milestone donor-id u25 donation-count)
      true
    )
    (if (and (>= donation-count u50) (is-none (map-get? milestone-achievements { donor-id: donor-id, milestone: u50 })))
      (award-milestone donor-id u50 donation-count)
      true
    )
  )
)

;; Award milestone achievement
(define-private (award-milestone (donor-id principal) (milestone uint) (donation-count uint))
  (map-set milestone-achievements
    { donor-id: donor-id, milestone: milestone }
    {
      achieved-at: block-height,
      reward-claimed: false,
      donation-count: donation-count
    }
  )
)

;; Get milestone reward amount
(define-private (get-milestone-reward-amount (milestone uint))
  (if (is-eq milestone u5)
    MILESTONE_5_REWARD
    (if (is-eq milestone u10)
      MILESTONE_10_REWARD
      (if (is-eq milestone u25)
        MILESTONE_25_REWARD
        (if (is-eq milestone u50)
          MILESTONE_50_REWARD
          u0
        )
      )
    )
  )
)

;; Filter available milestones (simplified)
(define-private (filter-available-milestones (current-level uint))
  (list u5 u10 u25 u50) ;; Simplified - would filter based on current level
)

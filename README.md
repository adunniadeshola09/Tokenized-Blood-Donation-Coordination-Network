# Tokenized Blood Donation Coordination Network

A decentralized blockchain-based system for coordinating blood donations, managing inventory, and incentivizing donors using Clarity smart contracts on the Stacks blockchain.

## Overview

This system consists of five interconnected smart contracts that work together to create a comprehensive blood donation management platform:

### Smart Contracts

1. **Donor Eligibility Contract** (`donor-eligibility.clar`)
    - Verifies health requirements for blood donation
    - Manages donor registration and eligibility status
    - Tracks donation history and health screenings

2. **Inventory Management Contract** (`inventory-management.clar`)
    - Tracks blood supply levels by type (A+, A-, B+, B-, AB+, AB-, O+, O-)
    - Manages blood unit expiration dates
    - Monitors critical supply levels

3. **Emergency Allocation Contract** (`emergency-allocation.clar`)
    - Prioritizes blood distribution during crisis situations
    - Manages emergency requests and allocations
    - Implements priority-based distribution algorithms

4. **Donor Incentive Contract** (`donor-incentive.clar`)
    - Rewards regular blood donation participation
    - Issues tokens for successful donations
    - Manages loyalty programs and milestone rewards

5. **Quality Assurance Contract** (`quality-assurance.clar`)
    - Ensures blood safety testing standards
    - Tracks testing results and certifications
    - Manages quality control processes

## Features

### For Donors
- Register and maintain eligibility status
- Earn tokens for donations
- Track donation history
- Receive milestone rewards

### For Blood Banks
- Manage inventory levels
- Track blood unit quality and expiration
- Handle emergency allocation requests
- Monitor supply chain integrity

### For Healthcare Providers
- Request blood units based on patient needs
- Access emergency allocation during crises
- Verify blood quality and safety standards

## Token Economics

The system uses a native token to incentivize participation:
- **Donation Rewards**: Tokens earned per successful donation
- **Milestone Bonuses**: Additional rewards for regular donors
- **Quality Incentives**: Extra tokens for maintaining high-quality donations

## Getting Started

### Prerequisites
- Stacks blockchain node
- Clarity development environment
- Node.js and npm for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to Stacks testnet

### Testing

The project includes comprehensive test suites using Vitest:

\`\`\`bash
npm test
\`\`\`

### Contract Deployment

Deploy contracts in the following order:
1. donor-eligibility.clar
2. inventory-management.clar
3. quality-assurance.clar
4. donor-incentive.clar
5. emergency-allocation.clar

## Architecture

### Data Flow
1. Donors register through the eligibility contract
2. Successful donations are recorded in inventory management
3. Quality assurance validates blood safety
4. Incentive contract rewards donors with tokens
5. Emergency allocation handles crisis situations

### Security Features
- Multi-signature requirements for critical operations
- Time-locked functions for sensitive actions
- Role-based access control
- Comprehensive error handling

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please open an issue in the GitHub repository.
\`\`\`



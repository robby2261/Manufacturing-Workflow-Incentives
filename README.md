# 🏭 Manufacturing Workflow Incentives

[![Smart Contract](https://img.shields.io/badge/Smart%20Contract-Clarity-blue.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Blockchain-Stacks-orange.svg)](https://www.stacks.co/)

A **tokenized incentive system** for manufacturing employees that automatically rewards quality and delivery performance with STX bonuses! 💰

## 🎯 Overview

This smart contract creates a decentralized incentive system where manufacturing employees and operators can earn automatic STX rewards for meeting quality scores and delivery targets. The system tracks performance, calculates bonuses using weighted scoring, and auto-triggers payments when targets are achieved.

## ✨ Key Features

- 👥 **Employee Management**: Register and track manufacturing workers
- 🎯 **Dual Target System**: Quality scores (60% weight) + Delivery targets (40% weight)  
- 💰 **Automatic STX Rewards**: Auto-triggered payments when targets are met
- 📊 **Performance Tracking**: Real-time monitoring of employee metrics
- 🔐 **Secure Access Control**: Owner-only administrative functions
- 📈 **Period-based System**: Organized tracking across time periods

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- STX tokens for contract funding

### Deployment
```bash
# Clone the repository
git clone <repository-url>
cd Manufacturing-Workflow-Incentives

# Check contract syntax
clarinet check

# Run tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## 📋 Usage Guide

### For Contract Owners (Management)

#### 1. Register an Employee
```clarity
(contract-call? .manufacturing-workflow-incentives register-employee 
    'SP1EMPLOYEE123... 
    "John Smith" 
    "Assembly Line A")
```

#### 2. Set Quality Target
```clarity
(contract-call? .manufacturing-workflow-incentives set-quality-target 
    'SP1EMPLOYEE123... 
    u95           ;; Target quality score (out of 100)
    u1000000      ;; Reward amount in microSTX (1 STX)
    u144          ;; Deadline in blocks
)
```

#### 3. Set Delivery Target  
```clarity
(contract-call? .manufacturing-workflow-incentives set-delivery-target 
    'SP1EMPLOYEE123... 
    u50           ;; Target deliveries
    u500000       ;; Reward amount in microSTX (0.5 STX)
    u144          ;; Deadline in blocks
)
```

#### 4. Update Performance
```clarity
;; Update quality score
(contract-call? .manufacturing-workflow-incentives update-quality-score 
    'SP1EMPLOYEE123... 
    u98)

;; Update delivery count
(contract-call? .manufacturing-workflow-incentives update-delivery-count 
    'SP1EMPLOYEE123... 
    u52)
```

#### 5. Fund the Contract
```clarity
(contract-call? .manufacturing-workflow-incentives fund-contract u10000000) ;; 10 STX
```

### For Employees

#### Claim Quality Reward
```clarity
(contract-call? .manufacturing-workflow-incentives claim-quality-reward)
```

#### Claim Delivery Reward
```clarity
(contract-call? .manufacturing-workflow-incentives claim-delivery-reward)
```

#### Check Your Stats
```clarity
(contract-call? .manufacturing-workflow-incentives get-employee-stats tx-sender)
```

## 🔍 Read-Only Functions

### Employee Information
```clarity
;; Get employee details
(contract-call? .manufacturing-workflow-incentives get-employee 'SP1EMPLOYEE123...)

;; Get employee statistics and eligibility
(contract-call? .manufacturing-workflow-incentives get-employee-stats 'SP1EMPLOYEE123...)
```

### Target Information
```clarity
;; Get quality target for current period
(contract-call? .manufacturing-workflow-incentives get-quality-target 'SP1EMPLOYEE123... u1)

;; Get delivery target for current period  
(contract-call? .manufacturing-workflow-incentives get-delivery-target 'SP1EMPLOYEE123... u1)
```

### Contract Status
```clarity
;; Check contract balance
(contract-call? .manufacturing-workflow-incentives get-contract-balance)

;; Get total employees
(contract-call? .manufacturing-workflow-incentives get-total-employees)

;; Get total rewards distributed
(contract-call? .manufacturing-workflow-incentives get-total-rewards-distributed)

;; Check current period
(contract-call? .manufacturing-workflow-incentives get-current-period)
```

## 💡 How It Works

### Bonus Calculation Formula
The contract uses a **weighted scoring system**:
- **Quality Score**: 60% weight
- **Delivery Score**: 40% weight  
- **Bonus Multiplier**: Applied based on performance level

```
Final Score = (Quality Score × 0.6) + (Delivery Score × 0.4)
Bonus = Base Reward × Multiplier (based on final score)
```

### Performance Thresholds
- **🥇 Excellent** (95-100): 1.5x multiplier
- **🥈 Good** (85-94): 1.2x multiplier  
- **🥉 Satisfactory** (75-84): 1.0x multiplier

### Automatic Reward Distribution
When both quality and delivery targets are met:
1. ✅ Contract validates target completion
2. 💰 Calculates weighted bonus amount
3. 🚀 Auto-transfers STX to employee wallet
4. 📝 Updates employee's total rewards counter

## 🛡️ Security Features

- **Owner-only Controls**: Administrative functions restricted to contract owner
- **Input Validation**: All parameters validated before processing
- **Balance Checks**: Ensures sufficient funds before reward distribution
- **Double-claim Prevention**: Prevents claiming rewards multiple times
- **Active Employee Verification**: Only active employees can receive targets

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | ERR_UNAUTHORIZED | Caller not authorized for this action |
| u101 | ERR_EMPLOYEE_NOT_FOUND | Employee not registered |
| u102 | ERR_EMPLOYEE_EXISTS | Employee already registered |
| u103 | ERR_INVALID_TARGET | Invalid target parameters |
| u104 | ERR_INSUFFICIENT_BALANCE | Contract balance too low |
| u105 | ERR_REWARD_ALREADY_CLAIMED | Reward already claimed |
| u106 | ERR_TARGET_NOT_MET | Performance target not achieved |
| u107 | ERR_INVALID_AMOUNT | Invalid amount specified |
| u108 | ERR_PERIOD_NOT_FOUND | Period not found |
| u109 | ERR_CALCULATION_ERROR | Error in bonus calculation |

## 🔧 Development

### Testing
```bash
# Run all tests
clarinet test

# Run specific test
clarinet test tests/manufacturing_test.ts
```

### Local Development
```bash
# Start local Clarinet console
clarinet console

# Test contract functions interactively
>> (contract-call? .manufacturing-workflow-incentives get-total-employees)
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) smart contract language
- Powered by [Stacks](https://www.stacks.co/) blockchain
- Inspired by modern manufacturing best practices

---

**🎉 Ready to revolutionize your manufacturing incentives? Deploy this contract and start rewarding excellence today!**


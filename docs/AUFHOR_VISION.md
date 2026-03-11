# AUFHOR (AH) – Vision & Deployment Guide

## 1. Overview

**AUFHOR** is an ERC-20 token deployed on Optimism L2 that represents *sovereign time* —
the idea that every hour invested in genuine, value-creating work carries measurable,
transferable worth.

| Property          | Value                         |
|-------------------|-------------------------------|
| Token Name        | AUFHOR                        |
| Symbol            | AH                            |
| Decimals          | 18                            |
| Initial Supply    | 144,000 AH (symbolic 144k nodes) |
| Network           | Optimism L2 (Chain ID: 10)    |
| Solidity Version  | ^0.8.24                       |
| Standard          | ERC-20 (OpenZeppelin v5)      |

---

## 2. Core Principles

### Lex Amoris Compliance
Every token transfer is validated through the `checkLexAmorisCompliance` hook inside
`AufhorToken.sol`. In its current form the hook is a placeholder that approves all
transfers; future iterations can embed S-ROI (Spiritual Return on Investment) or any
other governance rule without changing the public interface.

### Resonance Frequency Reference
`RESONANCE_FREQ = 3215` (representing 321.5 Hz) is stored as a public constant on-chain,
providing a permanent, immutable reference to the project's foundational frequency.

### Governance
Token minting beyond the genesis supply requires the contract owner (initially the
deployer). For production use, ownership should be transferred to a multi-sig wallet
(e.g. Gnosis Safe) controlled by the project governance council.

---

## 3. Smart Contract: `contracts/AufhorToken.sol`

```solidity
// Key interface (simplified)
contract AufhorToken is ERC20, Ownable {
    uint256 public constant RESONANCE_FREQ = 3215;

    constructor(address initialOwner);      // mints 144,000 AH to initialOwner
    function mint(address to, uint256 amount) external onlyOwner;
    function burn(uint256 amount) external;
    function checkLexAmorisCompliance(address from, address to) internal pure virtual returns (bool);
}
```

### Extending Compliance Logic
Override `checkLexAmorisCompliance` in a derived contract to enforce custom rules:

```solidity
contract AufhorTokenV2 is AufhorToken {
    mapping(address => bool) public approved;

    constructor(address owner) AufhorToken(owner) {}

    function checkLexAmorisCompliance(address from, address to)
        internal view override returns (bool)
    {
        return approved[from] && approved[to];
    }
}
```

---

## 4. Deployment

### Prerequisites
```bash
npm install --save-dev hardhat @openzeppelin/contracts ethers
```

Configure `hardhat.config.js` with the Optimism network:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.24",
  networks: {
    optimism: {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
    "optimism-sepolia": {
      url: "https://sepolia.optimism.io",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
  },
};
```

### Deploy to Optimism Testnet (recommended first)
```bash
npx hardhat run scripts/deploy.js --network optimism-sepolia
```

### Deploy to Optimism Mainnet
```bash
npx hardhat run scripts/deploy.js --network optimism
```

### Verify on Etherscan
```bash
npx hardhat verify --network optimism <CONTRACT_ADDRESS> "<OWNER_ADDRESS>"
```

---

## 5. Roadmap

| Phase | Feature |
|-------|---------|
| 1 | Genesis deployment — 144,000 AH minted, Lex Amoris hook active |
| 2 | Transfer ownership to multi-sig governance wallet |
| 3 | Implement S-ROI validation inside `checkLexAmorisCompliance` |
| 4 | Cross-chain bridge integration (Optimism Standard Bridge) |
| 5 | Time-lock staking and reward-loop mechanics |
| 6 | DAO governance for minting & parameter changes |

---

## 6. Security Notes

- Never commit private keys to source control. Use `.env` files and add them to `.gitignore`.
- Before mainnet deployment, conduct a full audit of any custom compliance logic added to `checkLexAmorisCompliance`.
- Transfer contract ownership to a multi-sig wallet immediately after deployment to prevent single-point-of-failure governance.

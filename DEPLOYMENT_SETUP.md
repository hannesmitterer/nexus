# Deployment Infrastructure Setup

This directory contains the deployment infrastructure for the Universal Liquidity Pool (ULP) smart contract on Polygon network.

## 📁 Files Added

### Configuration Files
- **package.json** - Node.js project configuration with Hardhat dependencies
- **hardhat.config.js** - Hardhat configuration for Polygon mainnet and testnet
- **.env.example** - Template for environment variables (copy to `.env`)
- **.gitignore** - Updated to exclude build artifacts and secrets

### Deployment Scripts
- **scripts/deploy.js** - Main deployment script with validation and verification
- **scripts/validate-env.js** - Environment configuration validation utility

### Contract Files
- **contracts/UniversalLiquidityPool.sol** - Main ULP smart contract (copied for Hardhat)

### Documentation
- **ULP_DEPLOYMENT_GUIDE.md** - Complete deployment guide with workflow steps

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
```bash
# Copy template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

Required environment variables:
- `DEPLOYER_PRIVATE_KEY` - Private key of deployment wallet
- `SAIN_TOKEN_ADDRESS` - SAIN token contract address
- `STABLECOIN_ADDRESS` - USDC address (Polygon: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
- `GGC_MULTISIG_ADDRESS` - GGC 7/9 multisig wallet address
- `POLYGON_RPC_URL` - Polygon RPC endpoint
- `POLYGONSCAN_API_KEY` - API key for contract verification

### 3. Validate Configuration
```bash
npm run validate
```

### 4. Compile Contracts
```bash
npm run compile
```

### 5. Deploy

**Testnet (Mumbai):**
```bash
npm run deploy:testnet
```

**Mainnet (Polygon):**
```bash
npm run deploy:mainnet
```

### 6. Verify Contract
```bash
npx hardhat verify --network polygon <CONTRACT_ADDRESS> <SAIN_TOKEN> <STABLECOIN> <GGC_MULTISIG>
```

## 📚 Documentation

See [ULP_DEPLOYMENT_GUIDE.md](./ULP_DEPLOYMENT_GUIDE.md) for:
- Complete deployment workflow
- Pre-deployment checklist
- Post-deployment verification
- Troubleshooting guide
- Environment configuration reference

## 🔒 Security Notes

- **Never commit `.env` file** - It contains sensitive private keys
- Always use `.env.example` as a template
- Test on Mumbai testnet before mainnet deployment
- Verify all addresses before deployment
- Use a secure RPC endpoint for production

## 🛠️ Available Scripts

| Command | Description |
|---------|-------------|
| `npm run compile` | Compile all smart contracts |
| `npm run deploy:testnet` | Deploy to Polygon Mumbai testnet |
| `npm run deploy:mainnet` | Deploy to Polygon mainnet |
| `npm run validate` | Validate environment configuration |
| `npm run verify` | Verify contract on Polygonscan |
| `npm test` | Run contract tests |

## 📋 Deployment Checklist

- [ ] Install dependencies (`npm install`)
- [ ] Configure environment (`.env`)
- [ ] Validate configuration (`npm run validate`)
- [ ] Compile contracts (`npm run compile`)
- [ ] Deploy to testnet (`npm run deploy:testnet`)
- [ ] Test testnet deployment
- [ ] Deploy to mainnet (`npm run deploy:mainnet`)
- [ ] Verify contract (`npm run verify`)
- [ ] Update deployment documentation
- [ ] Configure monitoring

## 🆘 Troubleshooting

### Common Issues

**Issue: "Missing environment variables"**
- Copy `.env.example` to `.env`
- Fill in all required values
- Run `npm run validate` to check

**Issue: "Insufficient funds for gas"**
- Ensure deployer wallet has at least 0.1 MATIC
- Check balance with Hardhat console

**Issue: "Compilation failed"**
- Run `npx hardhat clean`
- Delete `cache/` and `artifacts/` directories
- Run `npm run compile` again

**Issue: "Verification failed"**
- Ensure constructor arguments are correct
- Check compiler version matches (0.8.0)
- Verify optimization settings (200 runs)

For more details, see the Troubleshooting section in [ULP_DEPLOYMENT_GUIDE.md](./ULP_DEPLOYMENT_GUIDE.md).

## 📞 Support

- Technical Documentation: [ULP_README.md](./ULP_README.md)
- Protocol Documentation: [SAIN-Protocol-V1.0.md](./SAIN-Protocol-V1.0.md)
- Deployment Guide: [ULP_DEPLOYMENT_GUIDE.md](./ULP_DEPLOYMENT_GUIDE.md)

## 📄 License

MIT License - See repository root for details.

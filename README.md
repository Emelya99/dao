## AYEM DAO Contracts

On-chain governance system built with Foundry and OpenZeppelin Contracts. Implements an ERC20 governance token and a minimal DAO that creates and executes proposals through dedicated proposal contracts.

**Part of a full-stack DAO project:**
- [Live Demo](https://dao-front.vercel.app) - Try the DAO in action
- [Frontend Repository](https://github.com/Emelya99/dao-front) - Web interface for interacting with the DAO
- [Backend Repository](https://github.com/Emelya99/dao-backend) - API and backend services

### Features

- **Governance token (`AYEMToken`)**: Fixed-supply ERC20 with 8 decimals, burnable functionality, and owner-only minting
- **DAO core (`DAOContract`)**: Manages proposal lifecycle, enforces minimum token threshold for proposal creation, and executes successful proposals via low-level calls
- **Proposal instances (`ProposalContract`)**: Each proposal is deployed as a separate contract instance. This approach is gas-inefficient compared to storing proposals in a mapping, but was intentionally chosen for this educational project to practice contract deployment patterns and separation of concerns
- **Token-weighted voting**: Voting power is proportional to token balance at the time of voting
- **Quorum mechanism**: 50% quorum requirement on total votes cast
- **Comprehensive test suite**: 22 tests covering proposal creation, voting, execution, parameter updates, and integration scenarios

### Tech stack

- **Language**: Solidity `^0.8.26`
- **Framework/tooling**: Foundry (`forge-std`)
- **Libraries**: OpenZeppelin Contracts `^5.5.0`

### Deployed Contracts (Hoodi Network)

- **AYEMToken**: [`0x1f36deeC5c3cBeef59c2eaFDc4fF299980855648`](https://hoodi.etherscan.io/address/0x1f36deeC5c3cBeef59c2eaFDc4fF299980855648)
- **DAOContract**: [`0xd51396979c21a48fa211602b82442fA879ce6878`](https://hoodi.etherscan.io/address/0xd51396979c21a48fa211602b82442fA879ce6878)

### Testing

```bash
forge test
```

**Test results:** 22 tests passed, 0 failed (3 test suites covering DAO core, proposals, and integration scenarios)

<div align="center">

# Authorization-AUTHD

### ERC-20 Token Authorization Protocol

*Grant delegates the power to approve token transfers on your behalf — fully on-chain, fully auditable.*

[![Solidity](https://img.shields.io/badge/Solidity-0.8.28-363636?style=for-the-badge&logo=solidity)](https://soliditylang.org)
[![Hardhat](https://img.shields.io/badge/Hardhat-3.1.10-FFF100?style=for-the-badge&logo=hardhat)](https://hardhat.org)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.6.1-4E5EE4?style=for-the-badge&logo=openzeppelin)](https://openzeppelin.com)
[![Network](https://img.shields.io/badge/Network-Sepolia-6F4CFF?style=for-the-badge&logo=ethereum)](https://sepolia.etherscan.io)
[![License](https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge)](LICENSE)

<br/>

[**Live Demo**](https://sepolia.etherscan.io/address/0x610d238a77821229abae94df738da97811ea014a) · [**Server Contract**](https://sepolia.etherscan.io/address/0xfeb91ced20b008f6f5bebc9189ec7837894584a1) · [**Client Contract**](https://sepolia.etherscan.io/address/0x610d238a77821229abae94df738da97811ea014a)

</div>

---

## What Is This?

Authorization-AUTHD extends the ERC-20 standard to introduce **structured, capped delegation**. Instead of a simple unlimited allowance, an owner can authorize a delegate with a hard cap — the delegate can then approve token transfers on the owner's behalf, but never beyond what they were granted.

Think of it as a **limited power of attorney for ERC-20 tokens**.

```
Owner ──authorize(delegate, cap)──► CustomClient ──► AuthorizedToken Server
                                                              │
Delegate ──approveFor(owner, spender, amount)──► CustomClient ┘
                                                (enforces cap ≥ amount)
```

---

## Architecture

The system is composed of two contracts:

| Contract | Role |
|----------|------|
| `ERC20Authorized.sol` | Authorization server — stores caps, enforces rules, emits events |
| `ERC20AuthorizedClient.sol` | Abstract client — proxies calls to the server, manages local ERC-20 state |
| `CustomClient.sol` | Concrete demo client — adds `buyTokens()` for testnet use |

> **Key design:** Only registered clients can call the server's state-changing functions. Your wallet always talks to the client, never the server directly.

---

## Security Model

- **Reentrancy protection** — all internal state changes happen *before* any external server call in every public function
- **Hardcoded server address** — clients immutably bind to the server at deploy time, preventing spoofing
- **Client-only server access** — unregistered callers cannot modify server state
- **Admin revocation** — the server owner can revoke suspicious clients, halting their ability to issue new authorizations

---

## Project Structure

```
contracts/
├── interfaces/
│   └── IERC20Authorized.sol      # Server interface + events
├── lib/
│   ├── AddressArrayUtils.sol     # Address array helpers
│   └── LinearRate.sol            # Math utility
├── ERC20Authorized.sol           # Authorization server
├── ERC20AuthorizedClient.sol     # Abstract client
├── ERC20AuthorizedErrors.sol     # Shared custom errors
└── CustomClient.sol              # Demo client (Sepolia)

test/
├── ERC20Authorized.t.sol         # Server unit tests
├── ERC20AuthorizedClient.t.sol   # Client unit tests
└── DemoClient.sol                # Test client implementation

frontend/
└── src/                          # React + wagmi demo UI
```

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 22.19.13 |
| TypeScript | 5.8.0 |
| Hardhat | 3.1.10 |

### Install

```bash
# Clone the repo
git clone https://github.com/orSolocate/Authorization-AUTHD
cd Authorization-AUTHD

# Install dependencies
npm install

# Install OpenZeppelin contracts
npm install @openzeppelin/contracts@5.6.1

# Install Forge-std assertion library (follow Hardhat 3 tutorial, pin to v1.9.7)
# https://hardhat.org/docs/tutorial/assertions-library
```

### Build

```bash
npx hardhat build
```

### Test

```bash
npx hardhat test
```

### Run the Frontend Demo

```bash
cd frontend
cp .env.example .env   # fill in your RPC URL and contract addresses
npm install
npm run dev
```

---

## Demo Flow

The Sepolia demo walks through the full authorization lifecycle:

```
1. registerClient()          — pay 0.01 ETH, register with the server
2. buyTokens(10)             — mint CUST tokens to your wallet
3. authorize(delegate, cap)  — grant a delegate a spending cap
4. approveFor(owner,         — delegate approves a spender (uses cap)
              spender, amt)
5. transferFrom(...)         — spender pulls tokens using the allowance
6. increaseAuthorizedCap()   — owner raises the delegate's cap
7. revokeAuthorization()     — owner revokes the delegation entirely
```

---

## Deployed Contracts (Sepolia)

| Contract | Address |
|----------|---------|
| AuthorizedToken (Server) | [`0xfEB91CED...584a1`](https://sepolia.etherscan.io/address/0xfeb91ced20b008f6f5bebc9189ec7837894584a1) |
| CustomClient | [`0x610D238A...014A`](https://sepolia.etherscan.io/address/0x610d238a77821229abae94df738da97811ea014a) |

---

## Tests

| Test File | Coverage |
|-----------|----------|
| `ERC20Authorized.t.sol` | Server interface, events, errors — direct contract calls |
| `ERC20AuthorizedClient.t.sol` | Client interface, approve logic, authorization events and errors |

```bash
npx hardhat test
```

---

## Dependencies

```json
{
  "@openzeppelin/contracts": "5.6.1",
  "hardhat": "3.1.10",
  "typescript": "5.8.0",
  "forge-std": "1.9.7"
}
```

---

<div align="center">

Built on Ethereum · Sepolia Testnet · Solidity 0.8.28

</div>
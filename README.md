# Adcoin

A simple SIP-010–style fungible token implemented in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language) and managed with [Clarinet](https://docs.hiro.so/clarinet).

This project defines an `Adcoin` token (`ADCOIN`) with on-chain minting and burning, designed for local development and experimentation on Stacks devnet/simnet.

---

## Prerequisites

- **Clarinet** (tested with `clarinet 3.x`)
- **Node.js & npm** (for the generated Clarinet test tooling)

You already have Clarinet installed if the following shows a version:

```sh path=null start=null
clarinet --version
```

If you need installation instructions, see the official docs: <https://docs.hiro.so/clarinet>

---

## Project structure

Key files and directories in this repo:

- `Clarinet.toml` – Clarinet project configuration
- `contracts/adcoin.clar` – Adcoin fungible token smart contract
- `settings/Devnet.toml` – Local devnet configuration
- `settings/Testnet.toml`, `settings/Mainnet.toml` – Network configuration templates
- `tests/` – Placeholder for Clarinet / JavaScript tests
- `package.json`, `tsconfig.json`, `vitest.config.ts` – TypeScript + Vitest test tooling

---

## Adcoin contract overview

**Contract:** `contracts/adcoin.clar`

The contract implements a SIP-010–style fungible token trait defined locally in the same contract (`sip010-ft-trait`). It exposes:

### Read-only functions

- `get-name` → `(ok "Adcoin")`
- `get-symbol` → `(ok "ADCOIN")`
- `get-decimals` → `(ok u6)`
- `get-total-supply` → current token supply as `uint`
- `get-balance (who principal)` → balance of `who`
- `get-token-uri` → optional metadata URI

### Public entrypoints

- `transfer (amount sender recipient memo)`
  - Moves `amount` tokens from `sender` to `recipient`.
  - The transaction sender **must** equal `sender`, otherwise it fails with `ERR-NOT-AUTHORIZED`.
- `mint (amount recipient memo)`
  - Mints `amount` tokens to `recipient`.
  - Only the **contract owner** (the deployer) can call this successfully.
- `burn (amount sender memo)`
  - Burns `amount` tokens from `sender`.
  - The transaction sender must equal `sender`.

### State & permissions

- The contract tracks balances in a `balances` map.
- `total-supply` holds the total number of minted minus burned tokens.
- `owner` is set to the deploying principal on contract deployment and controls `mint`.

Error codes used:

- `u100` – `ERR-NOT-AUTHORIZED`
- `u101` – `ERR-INSUFFICIENT-BALANCE`
- `u102` – `ERR-INSUFFICIENT-SUPPLY` (reserved for potential future use)

---

## Using Clarinet

From the project root (`/home/anthony/Documents/GitHub/adcoin`):

### 1. Check the contract

```sh path=null start=null
clarinet check
```

This runs Clarinet’s static analysis and type checks against all contracts in `contracts/`.

### 2. Open a Clarinet console

You can experiment with the contract in an interactive REPL:

```sh path=null start=null
clarinet console
```

Once inside the console, you can call the contract functions. For example, after deploying `adcoin`:

```clarity path=null start=null
;; Mint 1,000,000 ADCOIN to the deployer (replace with the actual principal if needed)
(contract-call? .adcoin mint u1000000 tx-sender none)

;; Check your balance
(contract-call? .adcoin get-balance tx-sender)

;; Transfer 100 ADCOIN to another principal
(contract-call? .adcoin transfer u100 tx-sender 'ST3...RECIPIENT none)
```

### 3. Running tests (optional)

Install dependencies once:

```sh path=null start=null
npm install
```

Then run the (scaffolded) Vitest test suite:

```sh path=null start=null
npm test
```

You can add new tests under `tests/` to validate contract behavior.

---

## Development notes

- Modify `contracts/adcoin.clar` to extend the token (e.g., add admin functions, pausing, or custom logic).
- Update `settings/Devnet.toml` if you want to customize the local devnet behavior.
- Use `clarinet format contracts/adcoin.clar` to auto-format the contract.

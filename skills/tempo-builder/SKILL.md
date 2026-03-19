---
name: tempo-builder
description: Generates TypeScript code for Tempo network. TIP-20 tokens, stablecoin
  DEX swaps, Machine Payments Protocol (MPP/mppx), fee sponsorship. Corrects common
  LLM misconceptions about Tempo. Use when: "create stablecoin", "swap tokens",
  "paid API", "machine payments", "MPP", "mppx", "HTTP 402", "Tempo", "TIP-20".
---

# Tempo Builder

## What You Probably Got Wrong

**Prefer `viem` with Tempo extensions.** Tempo is EVM-compatible and supports ethers.js, Hardhat, Foundry, and more. But for Tempo-native flows (TIP-20 tokens, DEX, faucet), `viem` + `.extend(tempo())` gives you first-class actions like `client.token.*` and `client.dex.*`. This skill generates code using that path.

**Your decimals are wrong.** Tempo stablecoins use 6 decimals (USD), NOT 18 (ETH).
$1.00 = 1_000000n, not 1_000000000000000000n.

**Your chain config is wrong.** Tempo is EVM-compatible but uses its own chain.
- Testnet: tempoModerato, chain ID 42431, RPC https://rpc.moderato.tempo.xyz
- Mainnet: tempo, chain ID 4217

**You don't need a native token for gas.** Tempo fees are paid in any USD stablecoin.
No ETH, no native token. Just stablecoins.

**Finality is ~0.5 seconds.** Not 12 seconds like Ethereum.

**Check before you set up.** Before running any install or config steps, check if the project already has `viem` in `package.json` and a Tempo client config (look for `.extend(tempo())` or `tempoModerato` in the codebase). If setup exists, skip to the reference file for your task.

**If setup is needed**, read `references/quickstart.md` first for client setup. Then read the specific reference for your task.

## Feature References

| Feature | Reference | When to Read |
|---------|-----------|-------------|
| Setup & Config | `references/quickstart.md` | Chain config, client setup, wallets, faucet |
| TIP-20 Tokens | `references/tip20-tokens.md` | Create, mint, transfer, burn, roles, memos |
| DEX Trading | `references/dex.md` | Swap, quote, create pair, orderbook |
| Machine Payments (MPP) | `references/mpp.md` | HTTP 402, mppx client/server, sessions, Stripe, CLI |
| Payments & Memos | Use MCP: `mcp__tempo__search_docs query="payments"` | Send/accept, memos, fee sponsorship |
| Rewards | Use MCP: `mcp__tempo__search_docs query="rewards"` | Distribute, claim rewards |

## Predeployed Contract Addresses (TempoModerato Testnet)

| Contract | Address |
|----------|---------|
| pathUSD | 0x20c0000000000000000000000000000000000000 |
| TIP-20 Factory | 0x20fc000000000000000000000000000000000000 |
| Stablecoin DEX | 0xdec0000000000000000000000000000000000000 |
| Fee Manager | 0xfeec000000000000000000000000000000000000 |
| Account Keychain | 0xaAAAaaAA00000000000000000000000000000000 |
| Nonce Manager | 0x4e4F4E4345000000000000000000000000000000 |
| TIP-403 Registry | 0x403c000000000000000000000000000000000000 |

## Verifying with MCP

The reference files contain hardcoded function signatures and params. If you're unsure whether a signature is current, verify against the SDK source:

- `mcp__tempo__search_source` with query `"Token.create"` or `"Dex.sell"` in source `tempoxyz/tempo-ts`
- `mcp__tempo__search_docs` for protocol-level questions beyond what the references cover

The references optimize for common cases and misconception correction. MCP gives you the full picture.

## Security Guardrails for AI Agents

- NEVER commit or print private keys, seed phrases, or raw signing material.
- Prefer `process.env.*` for secrets and keep them out of prompts and generated code.
- Use least-privilege patterns for wallet permissions and role-based actions.
- When generating transactions, validate addresses, decimals, and units before signing.
- When asking users for values, ask for non-sensitive data only (names, amounts, public addresses).

## Data Freshness

> Last verified: 2026-03-19 | Testnet RPC: https://rpc.moderato.tempo.xyz

## Key Technical Details

| Item | Value |
|------|-------|
| Chain | tempoModerato, ID `42431` |
| RPC | `https://rpc.moderato.tempo.xyz` |
| Explorer | `https://explore.testnet.tempo.xyz` (testnet) / `https://explore.mainnet.tempo.xyz` (mainnet) |
| Native currency | USD, 6 decimals |
| SDK | `viem` + `viem/tempo` extensions, `tempo.ts/server` |
| Token actions | `Token.create`, `transfer`, `mint`, `burn`, `getBalance`, `grantRoles`, `pause`, `setSupplyCap` |
| DEX actions | `Dex.sell`, `buy`, `getSellQuote`, `getBuyQuote`, `createPair`, `place`, `placeFlip`, `cancel`, `getOrder`, `getTickLevel` |
| Faucet | `Faucet.fund`, `fundSync` |
| MPP SDK | `mppx/client` (pay), `mppx/server` (charge), `mppx/hono`, `mppx/nextjs` |
| MPP CLI | `npx mppx <url>`, `npx mppx account create/fund` |


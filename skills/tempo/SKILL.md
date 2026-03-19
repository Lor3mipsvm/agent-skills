---
name: tempo
description: Browse Tempo documentation and source code via MCP.
  Use when exploring protocol specs, reading SDK source, or searching
  Tempo docs. NOT for code generation — use tempo-builder for that.
---

# Tempo

Research and exploration skill for the Tempo network.
For generating code, use **tempo-builder** instead.

## What You Probably Got Wrong

**You searched docs when you needed source.**
`mcp__tempo__search_docs` searches prose documentation.
`mcp__tempo__search_source` searches actual code.
If you want a function signature, parameter type, or implementation detail, search source in `tempoxyz/tempo-ts`.

**You read a page without searching first.**
Tempo docs are structured by topic, not by SDK method.
Always `search_docs` before `read_page` — the page paths are not guessable.

**You searched source in the wrong repo.**
- `tempoxyz/tempo-ts` — TypeScript SDK, viem extensions, examples. **Start here** for anything about `client.token.*`, `client.dex.*`, `client.faucet.*`, or MPP.
- `tempoxyz/tempo` — Rust node implementation. Use for consensus, block production, transaction format internals.
- `wevm/viem` — upstream viem. Only needed if you're debugging viem itself, not Tempo extensions.

**You used `list_pages` to browse.**
`list_pages` returns every page. It's noisy.
Use `search_docs` with a specific query instead.

**You forgot `get_file_tree` exists.**
When you need to understand a repo's layout before diving in, `get_file_tree` with a `source` and optional `path` gives you the full directory structure. Much faster than repeated `list_source_files` calls.

## MCP Tools

| Tool | Use When |
| --- | --- |
| `mcp__tempo__search_docs` | Finding docs on a topic. Always try this first. |
| `mcp__tempo__read_page` | Reading a specific doc page (use the path from search results). |
| `mcp__tempo__list_pages` | Last resort — lists all pages. Prefer `search_docs`. |
| `mcp__tempo__search_source` | Finding function signatures, implementations, or usage patterns in code. |
| `mcp__tempo__read_source_file` | Reading a specific source file (use paths from search or file tree). |
| `mcp__tempo__get_file_tree` | Understanding repo structure before exploring. |
| `mcp__tempo__list_source_files` | Listing files in a specific directory. |
| `mcp__tempo__list_sources` | Seeing all available repos (rarely needed). |

## Common Queries

**"What parameters does X accept?"**
→ `mcp__tempo__search_source` with query `"X"` in source `tempoxyz/tempo-ts`

**"How does the DEX orderbook work?"**
→ `mcp__tempo__search_docs` with query `"DEX orderbook"`, then `read_page`

**"What's the transaction format?"**
→ `mcp__tempo__search_source` with query `"transaction"` in source `tempoxyz/tempo`

**"Show me an example of token creation"**
→ `mcp__tempo__search_source` with query `"token create"` in source `tempoxyz/tempo-ts`

**"What events does a transfer emit?"**
→ `mcp__tempo__search_source` with query `"transfer event"` in source `tempoxyz/tempo-ts`

## Available Sources

| Source | Language | Contains |
| --- | --- | --- |
| `tempoxyz/tempo-ts` | TypeScript | SDK, viem extensions, examples, tests |
| `tempoxyz/tempo` | Rust | Node, consensus, block production, transaction types |
| `wevm/viem` | TypeScript | Upstream viem (not Tempo-specific) |
| `wevm/wagmi` | TypeScript | React hooks (not Tempo-specific) |
| `paradigmxyz/reth` | Rust | Reth Ethereum client (not Tempo-specific) |
| `foundry-rs/foundry` | Rust | Foundry toolkit (not Tempo-specific) |

## Workflow

1. **Start with docs** — `search_docs` to orient yourself on the topic.
2. **Read the relevant page** — `read_page` with the path from search results.
3. **Dive into source** — `search_source` in `tempoxyz/tempo-ts` for SDK details, or `tempoxyz/tempo` for protocol internals.
4. **Map the repo** — `get_file_tree` if you need to understand where things live before reading specific files.

## Key Concepts

- **TIP-20**: Protocol-native stablecoin standard. Like ERC-20 but built into Tempo — no Solidity contract deployment needed.
- **Tempo Transactions**: Enhanced transaction format supporting sub-blocks and parallel execution. Not the same as Ethereum transactions.
- **Fee Sponsorship**: Third parties can pay transaction fees on behalf of users. Fees are in stablecoins, not a native gas token.
- **Stablecoin DEX**: Native orderbook exchange for stablecoin pairs. Not an AMM — uses explicit limit orders and tick-based pricing.
- **MPP (Machine Payments Protocol)**: HTTP 402-based payment standard for APIs. Co-authored with Stripe.
- **Finality**: ~0.5 seconds, not 12 seconds like Ethereum.
- **Decimals**: Stablecoins use 6 decimals (USD), not 18 (ETH).

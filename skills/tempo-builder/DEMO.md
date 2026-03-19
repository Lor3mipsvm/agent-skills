# tempo-builder Demo Script (5 minutes)

Goal: show that an LLM fails to generate correct Tempo code without the skill, and succeeds with it.

## Setup (30s)

1. Install the skill from your fork (replace with your fork URL):

```bash
npx skills add [fork-url]
```

2. Open a Claude Code (or Amp/Codex-style) session with the skill enabled.

## Without the skill (60s)

Run this prompt in a session where `tempo-builder` is NOT installed/enabled:

Prompt:

```text
Write TypeScript to create a TIP-20 stablecoin called TestUSD on Tempo testnet, then swap it on the stablecoin DEX.
```

What you should highlight from the output (typical hallucinations):
- Uses `ethers.js` (or plain viem) instead of Tempo-aware Viem actions
- Uses the wrong chain (often chain ID `1`)
- Uses 18 decimals for stablecoins (instead of 6)
- Assumes a native gas token is ETH (instead of stablecoin fees)
- Tries to deploy an ERC-20 contract instead of using `client.token.create*`
- Uses AMM-style DEX patterns instead of orderbook-style quoting + slippage bounds

## With the skill (90s)

Run the exact same prompt in a session where `tempo-builder` IS installed/enabled:

```text
Write TypeScript to create a TIP-20 stablecoin called TestUSD on Tempo testnet, then swap it on the stablecoin DEX.
```

What you should highlight from the output (expected “skill-correct” deltas):
- Uses Tempo-aware Viem setup (`tempoActions()` extension)
- Uses correct testnet config (`tempoModerato`, chain ID `42431`, RPC `https://rpc.moderato.tempo.xyz`)
- Uses 6-decimal math (`parseUnits(..., 6)`)
- Uses TIP-20 actions (no ERC-20 deployment):
  - `client.token.createSync`
  - `client.token.grantRolesSync` (e.g., `issuer`)
  - `client.token.mintSync`
- Uses memo handling as a `Hex` value (when included)
- Uses orderbook DEX actions with slippage bounds:
  - quote via `client.dex.getSellQuote` / `client.dex.getBuyQuote`
  - trade via `client.dex.sellSync` / `client.dex.buySync`
- Includes guardrails like “NEVER commit keys”

## Architecture (30s)

Say:
- “This is ethskills-style guidance for Tempo.”
- “Each reference file leads with a ‘What you probably got wrong’ section to correct common LLM misconceptions.”
- “Three compact reference files cover the 80% path (quickstart, TIP-20, DEX), and everything else routes to Tempo docs via MCP.”

## Close (30s)

Say:
- “Install: `npx skills add [fork-url]`.”
- “It works with Claude Code, Amp, and similar agent frameworks.”

## What differences to look for (quick checklist)

- Imports: `viem/tempo` usage vs plain viem/ethers
- Chain: `42431` and Moderato RPC vs chain ID `1`
- Units: `parseUnits(..., 6)` vs `18`
- Token actions: `client.token.create/mint/transfer` vs ERC-20 deploy
- DEX style: `get*Quote` + `sellSync/buySync` vs Uniswap/AMM assumptions


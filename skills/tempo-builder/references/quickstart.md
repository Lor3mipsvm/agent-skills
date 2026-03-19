# Quickstart

## What You Probably Got Wrong

**You’re using plain viem without Tempo extensions.** The Tempo actions live behind `tempoActions()`. If you don’t extend your Viem client with `tempoActions()`, you won’t have access to `client.token.*`, `client.dex.*`, `client.faucet.*`, etc.

**You’re targeting the wrong chain.** Tempo testnet is `tempoModerato` with chain ID `42431` (not Ethereum mainnet chain ID `1`).

**You tried to get ETH for gas.** Tempo has no native gas token; transaction fees are paid in stablecoins (USD-denominated TIP-20 tokens). On testnet, use the faucet to fund stablecoins.

**You used 18 decimals.** Tempo stablecoins use 6 decimals:
$1.00 = 1_000000n

## Real Data

Testnet:
- Network: `tempoModerato`
- Chain ID: `42431`
- RPC: `https://rpc.moderato.tempo.xyz`
- Explorer: `https://explore.testnet.tempo.xyz`

Mainnet:
- Network: `tempo`
- Chain ID: `4217`
- RPC: `https://rpc.tempo.xyz`
- Explorer: `https://explore.tempo.xyz`

Predeployed stablecoin (TIP-20):
- `pathUSD`: `0x20c0000000000000000000000000000000000000`
- Decimals: `6`

Testnet faucet:
- The faucet provides TIP-20 test stablecoins (for example `pathUSD`) for development.
- Landing page: `https://faucet.tempo.xyz/quickstart/faucet`

## Setup & Config (Viem + Tempo Actions)

### Install

```bash
npm i viem
```

### `viem.config.ts` (Testnet)

```ts
import { createClient, http, publicActions, walletActions } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { tempoModerato } from 'viem/chains'
import { tempoActions } from 'viem/tempo'

// Never hardcode private keys in commits.
const privateKey = process.env.TEMPO_PRIVATE_KEY
if (!privateKey) throw new Error('Missing TEMPO_PRIVATE_KEY')

export const client = createClient({
  account: privateKeyToAccount(privateKey as `0x${string}`),
  chain: tempoModerato,
  transport: http('https://rpc.moderato.tempo.xyz'),
})
  .extend(publicActions)
  .extend(walletActions)
  .extend(tempoActions())
```

### `viem.config.ts` (Mainnet)

```ts
import { createClient, http, publicActions, walletActions } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { tempo } from 'viem/chains'
import { tempoActions } from 'viem/tempo'

const privateKey = process.env.TEMPO_PRIVATE_KEY
if (!privateKey) throw new Error('Missing TEMPO_PRIVATE_KEY')

export const client = createClient({
  account: privateKeyToAccount(privateKey as `0x${string}`),
  chain: tempo,
  transport: http('https://rpc.tempo.xyz'),
})
  .extend(publicActions)
  .extend(walletActions)
  .extend(tempoActions())
```

## Sync vs Non-Sync Actions

All Tempo actions have two variants:
- **`*Sync`** (e.g., `client.token.transferSync`): Waits for the transaction receipt. Use in scripts, CLIs, and sequential flows.
- **Non-Sync** (e.g., `client.token.transfer`): Returns the transaction hash immediately. Use in UIs or when you handle confirmation separately.

All examples in this skill use `*Sync` for clarity. Drop the `Sync` suffix when you need fire-and-forget.

## Faucet: Fund an Account (Testnet only)

Use `client.faucet.fund` (async) or `client.faucet.fundSync` (waits for inclusion).

```ts
import { client } from './viem.config'

const account = client.account
if (!account) throw new Error('Client account missing')

// Wait for testnet funding transactions to be confirmed.
const receipts = await client.faucet.fundSync({
  account: account.address,
})

console.log('Faucet receipts:', receipts)
```

## First Transfer (Testnet or Mainnet)

This example transfers `pathUSD` using 6-decimal units.

```ts
import { parseUnits, toHex } from 'viem'
import { client } from './viem.config'

const token = '0x20c0000000000000000000000000000000000000' as const // pathUSD
const to = process.env.TEMPO_RECIPIENT_ADDRESS as `0x${string}`
if (!to) throw new Error('Missing TEMPO_RECIPIENT_ADDRESS')

const receipt = await client.token.transferSync({
  token,
  to,
  amount: parseUnits('1.00', 6), // 6 decimals on Tempo stablecoins
  memo: toHex('hello tempo'),
})

console.log('Transfer tx:', receipt.transactionHash)
```

## Common Errors

- **`Cannot read properties of undefined (reading 'token')`**: You forgot `.extend(tempoActions())` on your client.
- **Chain ID mismatch**: You imported `mainnet` instead of `tempoModerato`. Use `import { tempoModerato } from 'viem/chains'`.
- **`insufficient funds for gas`**: Tempo has no native gas token. Fund your account with the faucet first — it provides stablecoins for fees.
- **18-decimal overflow**: You used `parseUnits('1', 18)` instead of `parseUnits('1', 6)`. Tempo stablecoins are 6 decimals.

## Data Freshness

> Last verified: 2026-03-19

Verification commands:

```bash
cast chain-id --rpc-url https://rpc.moderato.tempo.xyz
cast block-number --rpc-url https://rpc.moderato.tempo.xyz
cast chain-id --rpc-url https://rpc.tempo.xyz
cast block-number --rpc-url https://rpc.tempo.xyz
```

If unsure about any import path or chain config, verify via `mcp__tempo__search_source` in `tempoxyz/tempo-ts`.


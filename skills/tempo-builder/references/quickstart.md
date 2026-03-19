# Quickstart

## Already Set Up?

Before running install or config steps, check the project first:
1. Is `viem` in `package.json`? → Skip `npm i viem`
2. Does a file already import `tempo` from `viem/tempo` or `tempo`/`tempoModerato` from `viem/chains`? → Skip client setup, reuse the existing config
3. Does the account already have a balance? (`client.token.getBalance`) → Skip funding

Only follow the steps below for what's actually missing.

## What You Probably Got Wrong

**You’re using plain viem without Tempo extensions.** The Tempo actions live behind `.extend(tempo())`. If you don’t extend your Viem client with `tempo()` from `viem/tempo`, you won’t have access to `client.token.*`, `client.dex.*`, `client.faucet.*`, etc.

**You’re targeting the wrong chain.** Tempo mainnet is `tempo` with chain ID `4217` (not Ethereum mainnet chain ID `1`). For development, testnet is `tempoModerato` with chain ID `42431`.

**You tried to get ETH for gas.** Tempo has no native gas token; transaction fees are paid in stablecoins (USD-denominated TIP-20 tokens).

**You used 18 decimals.** Tempo stablecoins use 6 decimals:
$1.00 = 1_000000n

## Real Data

Mainnet:
- Network: `tempo`
- Chain ID: `4217`
- RPC: `https://rpc.tempo.xyz`
- Explorer: `https://explore.tempo.xyz`

Testnet (for development only):
- Network: `tempoModerato`
- Chain ID: `42431`
- RPC: `https://rpc.moderato.tempo.xyz`
- Explorer: `https://explore.tempo.xyz`

Predeployed stablecoin (TIP-20):
- Verify current addresses via `mcp__tempo__search_docs` query `"stablecoin addresses"` — addresses may differ between mainnet and testnet.
- Decimals: `6`

Testnet faucet (testnet only):
- The faucet provides TIP-20 test stablecoins for development.
- Landing page: `https://faucet.tempo.xyz/quickstart/faucet`

## Setup & Config (Viem + Tempo Actions)

### Install

```bash
npm i viem
```

### `viem.config.ts` (Mainnet)

```ts
import { createClient, http, publicActions, walletActions } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { tempo } from 'viem/chains'
import { tempo as tempoActions } from 'viem/tempo'

// Never hardcode private keys in commits.
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

### `viem.config.ts` (Testnet — for development only)

```ts
import { createClient, http, publicActions, walletActions } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { tempoModerato } from 'viem/chains'
import { tempo } from 'viem/tempo'

const privateKey = process.env.TEMPO_PRIVATE_KEY
if (!privateKey) throw new Error('Missing TEMPO_PRIVATE_KEY')

export const client = createClient({
  account: privateKeyToAccount(privateKey as `0x${string}`),
  chain: tempoModerato,
  transport: http('https://rpc.moderato.tempo.xyz'),
})
  .extend(publicActions)
  .extend(walletActions)
  .extend(tempo())
```

## Sync vs Non-Sync Actions

All Tempo actions have two variants:
- **`*Sync`** (e.g., `client.token.transferSync`): Waits for the transaction receipt. Use in scripts, CLIs, and sequential flows.
- **Non-Sync** (e.g., `client.token.transfer`): Returns the transaction hash immediately. Use in UIs or when you handle confirmation separately.

All examples in this skill use `*Sync` for clarity. Drop the `Sync` suffix when you need fire-and-forget.

## Faucet: Fund an Account (Testnet only)

Use `client.faucet.fund` (async) or `client.faucet.fundSync` (waits for inclusion). Only available on testnet.

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

## First Transfer

This example transfers a TIP-20 stablecoin using 6-decimal units. Replace `TOKEN_ADDRESS` with the actual token address for your network.

```ts
import { parseUnits, toHex } from 'viem'
import { client } from './viem.config'

const token = process.env.TEMPO_TOKEN_ADDRESS as `0x${string}` // your TIP-20 stablecoin
const to = process.env.TEMPO_RECIPIENT_ADDRESS as `0x${string}`
if (!token) throw new Error('Missing TEMPO_TOKEN_ADDRESS')
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

- **`Cannot read properties of undefined (reading 'token')`**: You forgot `.extend(tempoActions())` (or `.extend(tempo())`) on your client.
- **Chain ID mismatch**: You imported `mainnet` (Ethereum) instead of `tempo` from `viem/chains`. Use `import { tempo } from 'viem/chains'` for mainnet or `import { tempoModerato } from 'viem/chains'` for testnet.
- **Name collision**: When importing both the chain and actions extension, rename one: `import { tempo } from 'viem/chains'` and `import { tempo as tempoActions } from 'viem/tempo'`.
- **`insufficient funds for gas`**: Tempo has no native gas token. Fees are paid in stablecoins. Ensure your account has stablecoin balance (on testnet, use the faucet).
- **18-decimal overflow**: You used `parseUnits('1', 18)` instead of `parseUnits('1', 6)`. Tempo stablecoins are 6 decimals.

## Data Freshness

> Last verified: 2026-03-19

Verification commands:

```bash
cast chain-id --rpc-url https://rpc.tempo.xyz
cast block-number --rpc-url https://rpc.tempo.xyz
cast chain-id --rpc-url https://rpc.moderato.tempo.xyz
cast block-number --rpc-url https://rpc.moderato.tempo.xyz
```

If unsure about any import path or chain config, verify via `mcp__tempo__search_source` in `tempoxyz/tempo-ts`.


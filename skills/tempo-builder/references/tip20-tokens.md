# TIP-20 Tokens

## What You Probably Got Wrong

**”TIP-20 is just an ERC-20 contract I have to deploy.”** On Tempo, TIP-20 tokens are protocol-native. You don’t deploy your own Solidity ERC-20; you create tokens via the Tempo actions.

**“I used 18 decimals.”** Tempo stablecoins use 6 decimals:
$1.00 = 1_000000n

**“I forgot memos (or used the wrong type).”** Tempo TIP-20 actions accept an optional `memo` as `Hex`. If you include a memo, convert it to hex (for example with `toHex('...')`).

**“I minted without the right role.”** `client.token.mint*` requires the `issuer` role. `client.token.pause*` requires the `pause` role. `client.token.setSupplyCap*` requires the default admin role.

## Real Data

On Tempo:
- TIP-20 “currency” examples: `USD`
- Stablecoin decimals: `6`
- Predeployed quote stablecoin example: `pathUSD = 0x20c0000000000000000000000000000000000000`

Testnet:
- `tempoModerato` chain ID `42431`
- RPC: `https://rpc.moderato.tempo.xyz`

Mainnet:
- `tempo` chain ID `4217`

## Operation: Create a TIP-20 Stablecoin

WHEN:
- You want a new stablecoin-like token that follows Tempo’s TIP-20 rules.

Function:
- `client.token.createSync({ admin, currency, name, symbol, quoteToken? })` → `{ token: Address, tokenId: bigint, admin: Address }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `admin` | `Address` | Receives the admin role |
| `currency` | `string` | Example: `"USD"` |
| `name` | `string` | Human-readable token name |
| `symbol` | `string` | Short symbol |
| `quoteToken` (optional) | `Address | bigint` | Quote token address or ID |

Example:
```ts
import { client } from './viem.config'

const { token, tokenId, admin } = await client.token.createSync({
  admin: client.account!.address,
  currency: 'USD',
  name: 'TestUSD',
  symbol: 'tUSD',
  // quoteToken is optional; omit unless you have a specific quote token strategy
})

console.log({ token, tokenId, admin })
```

Common errors:
- Using `currency: 'ETH'` or another non-supported value.
- Confusing the token “address” (`token`) with the token “ID” (`tokenId`).

## Operation: Grant Roles (e.g., issuer)

WHEN:
- Your token admin must grant the `issuer` role before minting.

Function:
- `client.token.grantRolesSync({ roles, token, to })` → `{ receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `roles` | `Array<"defaultAdmin"|"pause"|"unpause"|"issuer"|"burnBlocked">` | Role identifiers |
| `token` | `Address | bigint` | Token address or ID |
| `to` | `Address` | Address receiving the role |

Example:
```ts
import { client } from './viem.config'

await client.token.grantRolesSync({
  roles: ['issuer'],
  token: '0x20c0000000000000000000000000000000000000', // replace with your TIP-20 token address
  to: client.account!.address,
})
```

Common errors:
- Minting before granting `issuer`.
- Using a role string that isn’t one of the accepted role identifiers.

## Operation: Mint TIP-20 Tokens

WHEN:
- You want to create new supply for an existing TIP-20 token.

Function:
- `client.token.mintSync({ amount, to, token, memo? })` → `{ receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amount` | `bigint` | Use 6 decimals (see `parseUnits(..., 6)`) |
| `to` | `Address` | Recipient address |
| `token` | `Address | bigint` | Token address or ID |
| `memo` (optional) | `Hex` | Attach a memo if your app needs it |

Example:
```ts
import { parseUnits, toHex } from 'viem'
import { client } from './viem.config'

const { token } = await client.token.createSync({
  admin: client.account!.address,
  currency: 'USD',
  name: 'TestUSD',
  symbol: 'tUSD',
})

// Grant issuer so minting will succeed
await client.token.grantRolesSync({
  roles: ['issuer'],
  token,
  to: client.account!.address,
})

await client.token.mintSync({
  token,
  to: client.account!.address,
  amount: parseUnits('1000', 6),
  memo: toHex('initial mint'),
})
```

Common errors:
- Using 18 decimals in `parseUnits`.
- Trying to mint from an address without the `issuer` role.

## Operation: Transfer Tokens (with optional memo)

WHEN:
- You want to send TIP-20 stablecoins to another address.

Function:
- `client.token.transferSync({ token, to, amount, memo? })` → `{ transactionHash, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `token` | `Address | bigint` | Token address or ID |
| `to` | `Address` | Recipient |
| `amount` | `bigint` | 6-decimal units |
| `memo` (optional) | `Hex` | Memo included in the transfer event |

Example:
```ts
import { parseUnits, toHex } from 'viem'
import { client } from './viem.config'

await client.token.transferSync({
  token: '0x20c0000000000000000000000000000000000000', // your TIP-20 address (or replace with your token)
  to: process.env.TEMPO_RECIPIENT_ADDRESS as `0x${string}`,
  amount: parseUnits('10.5', 6),
  memo: toHex('invoice #123'),
})
```

Common errors:
- Using `memo` as a plain string (must be `Hex`).
- Forgetting the memo conversion when your app expects it.

## Operation: Burn Tokens

WHEN:
- You want to reduce circulating supply.

Function:
- `client.token.burnSync({ token, amount, memo? })` → `{ receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `token` | `Address | bigint` | Token address or ID |
| `amount` | `bigint` | 6-decimal units |
| `memo` (optional) | `Hex` | Memo included in the burn event |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

await client.token.burnSync({
  token: '0x20c0000000000000000000000000000000000000',
  amount: parseUnits('25', 6),
})
```

Common errors:
- Burning without enough balance.

## Operation: Read Balance

WHEN:
- You want to check an account’s TIP-20 balance.

Function:
- `client.token.getBalance({ account, token })` → `bigint`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `account` | `Address` | Address whose balance you want |
| `token` | `Address | bigint` | TIP-20 token address or ID |

Example:
```ts
import { client } from './viem.config'

const balance = await client.token.getBalance({
  account: client.account!.address,
  token: '0x20c0000000000000000000000000000000000000',
})

console.log('Balance:', balance)
```

## Operation: Pause a TIP-20 Token

WHEN:
- You need to temporarily stop transfers for compliance or risk management.

Function:
- `client.token.pauseSync({ token })` → `{ isPaused: boolean }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `token` | `Address | bigint` | TIP-20 token address or ID |

Example:
```ts
import { client } from './viem.config'

const { isPaused } = await client.token.pauseSync({
  token: '0x20c0000000000000000000000000000000000000',
})

console.log('Is paused:', isPaused)
```

Common errors:
- Calling from an address without the `pause` role.

## Operation: Set a Supply Cap

WHEN:
- You want to enforce a maximum total supply.

Function:
- `client.token.setSupplyCapSync({ token, supplyCap })` → `{ newSupplyCap: bigint }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `token` | `Address | bigint` | TIP-20 token address or ID |
| `supplyCap` | `bigint` | Maximum total supply in 6-decimal units |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

const { newSupplyCap } = await client.token.setSupplyCapSync({
  token: '0x20c0000000000000000000000000000000000000',
  supplyCap: parseUnits('1000000', 6),
})

console.log('New supply cap:', newSupplyCap)
```

Common errors:
- Using 18 decimals in `supplyCap`.

## Data Freshness

> Last verified: 2026-03-19

Verification commands:

```bash
cast chain-id --rpc-url https://rpc.moderato.tempo.xyz
cast block-number --rpc-url https://rpc.moderato.tempo.xyz
```

If unsure about any Token action signature, verify via `mcp__tempo__search_source` with query `"token"` in `tempoxyz/tempo-ts`.


# DEX Trading

## What You Probably Got Wrong

**You’re using an AMM (Uniswap-style) mental model.** Tempo’s stablecoin DEX is an **orderbook**. You should quote via `client.dex.get*Quote`, then trade with slippage bounds (`minAmountOut` / `maxAmountIn`), and place/cancel explicit limit orders.

**You forgot slippage.** For `dex.sell*`, use `minAmountOut`. For `dex.buy*`, use `maxAmountIn`.

**You used the wrong token role.** `tokenIn`/`tokenOut` in quotes and swaps are explicit, while orderbook actions use `token` + `type` + `tick` (and `Tick.fromPrice()` conversions).

**You used 18 decimals.** Stablecoins are 6 decimals on Tempo; use `parseUnits(amount, 6)`.

## Real Data

Mainnet:
- `tempo` chain ID `4217`
- RPC: `https://rpc.tempo.xyz`
- Explorer: `https://explore.tempo.xyz`

Testnet (development only):
- `tempoModerato` chain ID `42431`
- RPC: `https://rpc.moderato.tempo.xyz`

Stablecoins and DEX contract addresses:
- Verify current addresses via `mcp__tempo__search_docs` query `"stablecoin addresses"` or `"DEX contract"`.
- Addresses may differ between mainnet and testnet.

## Operation: Get Sell Quote

WHEN:
- You’re about to sell `tokenIn` and want to estimate how much `tokenOut` you’ll receive.

Function:
- `client.dex.getSellQuote({ amountIn, tokenIn, tokenOut })` → `bigint` (estimated amountOut)

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amountIn` | `bigint` | 6-decimal units of `tokenIn` to sell |
| `tokenIn` | `Address` | Token you sell |
| `tokenOut` | `Address` | Token you receive |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

const amountOut = await client.dex.getSellQuote({
  amountIn: parseUnits('100', 6),
  tokenIn: TOKEN_A, // e.g. pathUSD — use your actual token address
  tokenOut: TOKEN_B, // e.g. alphaUSD — use your actual token address
})

console.log('Amount received (quote):', amountOut)
```

## Operation: Sell on the Stablecoin DEX

WHEN:
- You want to execute a sell trade with explicit slippage protection.

Function:
- `client.dex.sellSync({ amountIn, minAmountOut, tokenIn, tokenOut })` → `{ transactionHash, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amountIn` | `bigint` | Amount of `tokenIn` to sell |
| `minAmountOut` | `bigint` | Minimum `tokenOut` you require |
| `tokenIn` | `Address` | Token you sell |
| `tokenOut` | `Address` | Token you receive |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

const receipt = await client.dex.sellSync({
  amountIn: parseUnits('100', 6),
  minAmountOut: parseUnits('95', 6),
  tokenIn: TOKEN_A, // e.g. pathUSD — use your actual token address
  tokenOut: TOKEN_B, // e.g. alphaUSD — use your actual token address
})

console.log('Sell tx:', receipt.transactionHash)
```

Common errors:
- Using `minAmountOut` computed with 18 decimals.

## Operation: Get Buy Quote

WHEN:
- You’re about to buy `tokenOut` and want to estimate how much `tokenIn` you’ll need.

Function:
- `client.dex.getBuyQuote({ amountOut, tokenIn, tokenOut })` → `bigint` (estimated amountIn needed)

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amountOut` | `bigint` | 6-decimal units of `tokenOut` you want |
| `tokenIn` | `Address` | Token you pay with |
| `tokenOut` | `Address` | Token you buy |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

const amountInNeeded = await client.dex.getBuyQuote({
  amountOut: parseUnits('100', 6),
  tokenIn: TOKEN_A, // e.g. pathUSD — use your actual token address
  tokenOut: TOKEN_B, // e.g. alphaUSD — use your actual token address
})

console.log('Amount needed (quote):', amountInNeeded)
```

## Operation: Buy on the Stablecoin DEX

WHEN:
- You want to execute a buy trade with explicit slippage protection.

Function:
- `client.dex.buySync({ amountOut, maxAmountIn, tokenIn, tokenOut })` → `{ transactionHash, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amountOut` | `bigint` | Amount of `tokenOut` to buy |
| `maxAmountIn` | `bigint` | Maximum `tokenIn` you’re willing to pay |
| `tokenIn` | `Address` | Token you pay with |
| `tokenOut` | `Address` | Token you buy |

Example:
```ts
import { parseUnits } from 'viem'
import { client } from './viem.config'

const receipt = await client.dex.buySync({
  amountOut: parseUnits('100', 6),
  maxAmountIn: parseUnits('105', 6),
  tokenIn: TOKEN_A, // e.g. pathUSD — use your actual token address
  tokenOut: TOKEN_B, // e.g. alphaUSD — use your actual token address
})

console.log('Buy tx:', receipt.transactionHash)
```

Common errors:
- Swapping `minAmountOut`/`maxAmountIn` between sell and buy flows.

## Advanced: Orderbook Operations

Most tasks only need the swap operations above (getSellQuote, sell, getBuyQuote, buy). Read below only if you need to create pairs, place limit orders, or read orderbook data.

## Operation: Create a Pair

WHEN:
- You need the DEX pair for a base token (the quote token is determined by the base token).

Function:
- `client.dex.createPairSync({ base })` → `{ key: bigint, base: Address, quote: Address, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `base` | `Address` | Base token for the trading pair |

Example:
```ts
import { client } from './viem.config'

const { key, base, quote, receipt } = await client.dex.createPairSync({
  base: TOKEN_A, // e.g. pathUSD — use your actual token address
})

console.log({ key, base, quote, receipt })
```

## Operation: Place a Limit Order

WHEN:
- You want to place an order on the DEX orderbook rather than immediately swapping via `sell/buy`.

Function:
- `client.dex.placeSync({ amount, tick, token, type })` → `{ orderId: bigint, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amount` | `bigint` | 6-decimal units of `token` |
| `tick` | `number` | Use `Tick.fromPrice('...')` |
| `token` | `Address` | Base token for the order |
| `type` | `'buy' | 'sell'` | Order direction |

Example:
```ts
import { parseUnits } from 'viem'
import { Tick } from 'viem/tempo'
import { client } from './viem.config'

const { orderId, receipt } = await client.dex.placeSync({
  amount: parseUnits('100', 6),
  tick: Tick.fromPrice('0.99'),
  token: TOKEN_A, // e.g. pathUSD — use your actual token address
  type: 'sell',
})

console.log('Order ID:', orderId)
console.log('Place receipt:', receipt.transactionHash)
```

Common errors:
- Passing a raw price string as `tick` instead of converting with `Tick.fromPrice()`.

## Operation: Place a Flip Order

WHEN:
- You want an order that auto-flips when it gets filled.

Function:
- `client.dex.placeFlipSync({ amount, flipTick, tick, token, type })` → `{ orderId: bigint, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `amount` | `bigint` | 6-decimal units |
| `tick` | `number` | Current price tick (`Tick.fromPrice(...)`) |
| `flipTick` | `number` | Target tick to flip to |
| `token` | `Address` | Base token for the order |
| `type` | `'buy' | 'sell'` | Order direction |

Example:
```ts
import { parseUnits } from 'viem'
import { Tick } from 'viem/tempo'
import { client } from './viem.config'

const { orderId } = await client.dex.placeFlipSync({
  amount: parseUnits('100', 6),
  flipTick: Tick.fromPrice('1.01'),
  tick: Tick.fromPrice('0.99'),
  token: TOKEN_A, // e.g. pathUSD — use your actual token address
  type: 'buy',
})

console.log('Flip order ID:', orderId)
```

## Operation: Cancel an Order

WHEN:
- You want to remove an existing order from the orderbook.

Function:
- `client.dex.cancelSync({ orderId })` → `{ orderId: bigint, receipt }`

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `orderId` | `bigint` | The ID returned by `place*` |

Example:
```ts
import { client } from './viem.config'

const { orderId, receipt } = await client.dex.cancelSync({
  orderId: 123n,
})

console.log('Cancelled order ID:', orderId)
console.log('Cancel tx:', receipt.transactionHash)
```

## Operation: Read Order Details (Orderbook)

WHEN:
- You want to inspect an order’s status/remaining amount.

Function:
- `client.dex.getOrder({ orderId })` → order object (status, remaining amount, tick, type)

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `orderId` | `bigint` | Order ID |

Example:
```ts
import { client } from './viem.config'

const order = await client.dex.getOrder({
  orderId: 123n,
})

console.log('Order details:', order)
```

## Operation: Read Tick Level (Orderbook Snapshot)

WHEN:
- You want a snapshot of liquidity at a specific price tick.

Function:
- `client.dex.getTickLevel({ base, tick, isBid })` → tick level object (total liquidity at this price)

Parameters:

| Param | Type | Notes |
|------|------|-------|
| `base` | `Address` | Base token address |
| `tick` | `number` | Use `Tick.fromPrice('...')` |
| `isBid` | `boolean` | `true` for bid side, `false` for ask side |

Example:
```ts
import { Tick } from 'viem/tempo'
import { client } from './viem.config'

const level = await client.dex.getTickLevel({
  base: TOKEN_A, // e.g. pathUSD — use your actual token address
  tick: Tick.fromPrice('1.001'),
  isBid: true,
})

console.log('Tick level:', level)
```

## Data Freshness

> Last verified: 2026-03-19

Verification commands:

```bash
cast chain-id --rpc-url https://rpc.tempo.xyz
cast block-number --rpc-url https://rpc.tempo.xyz
```

If unsure about any DEX action signature, verify via `mcp__tempo__search_source` with query `"dex"` in `tempoxyz/tempo-ts`.


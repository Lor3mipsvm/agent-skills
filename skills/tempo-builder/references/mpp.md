# Machine Payments Protocol (MPP)

## What You Probably Got Wrong

**You're building a custom payment flow.** MPP is an open standard (co-authored by Stripe and Tempo) that adds inline payments to any HTTP endpoint via HTTP 402. Don't build signup forms, API key dashboards, or billing systems. Use `mppx`.

**You're using `viem/tempo` for payments.** MPP has its own SDK: `mppx`. It's a separate package from viem. `import { Mppx, tempo } from 'mppx/client'` for paying, `import { Mppx, tempo } from 'mppx/server'` for charging.

**You're handling the 402 flow manually.** `mppx.fetch()` is a drop-in replacement for `fetch()` that auto-handles the entire 402 challenge → pay → retry flow. You don't need to parse headers yourself.

**You forgot that MPP is multi-rail.** The same endpoint can accept Tempo stablecoins, Stripe cards, and Lightning. Don't assume Tempo-only.

## Real Data

SDK:
- Package: `mppx` (install: `npm install mppx viem`)
- Client: `mppx/client`
- Server: `mppx/server`, `mppx/hono`, `mppx/nextjs`, `mppx/express`
- CLI: `npx mppx`

Payment currencies (Tempo):
- Testnet (pathUSD): `0x20c0000000000000000000000000000000000000`
- Mainnet: verify via `mcp__tempo__search_docs` query `"TEMPO_USD address"` (format differs from testnet)

Two payment intents:
- **Charge** (one-time): ~500ms latency, per-request on-chain. Best for single API calls.
- **Session** (pay-as-you-go): Near-zero latency after first request, off-chain vouchers. Best for streaming, LLM APIs, metered services.

Protocol spec: `https://mpp.dev` | IETF draft: `draft-ryan-httpauth-payment`

## Operation: Pay for an API (Client)

WHEN:
- Your app or agent needs to call a paid HTTP endpoint.

Function:
- `mppx.fetch(url, init?)` → standard `Response` (auto-handles 402 + payment + retry)

Setup:
```ts
import { Mppx, tempo } from 'mppx/client'
import { privateKeyToAccount } from 'viem/accounts'

const mppx = Mppx.create({
  methods: [
    tempo({
      account: privateKeyToAccount(process.env.TEMPO_PRIVATE_KEY as `0x${string}`),
      maxDeposit: '1',  // max tokens to lock in escrow (for sessions)
    })
  ],
})
```

Example:
```ts
// Drop-in replacement for fetch — handles 402 automatically
const response = await mppx.fetch('https://api.example.com/paid-resource')
const data = await response.json()
```

Common errors:
- Using plain `fetch()` instead of `mppx.fetch()` — you'll get a 402 you don't know how to handle.
- Forgetting `viem` as a peer dependency (`npm install mppx viem`).

## Operation: Monetize an API (Server — Fetch API)

WHEN:
- You want to charge per-request for an HTTP endpoint using the generic Fetch API pattern (works with Hono, Deno, Cloudflare Workers, Bun).

Function:
- `mppx.charge({ amount, description? })(request)` → `{ status, challenge, withReceipt }`

Setup:
```ts
import { Mppx, tempo } from 'mppx/server'

const mppx = Mppx.create({
  methods: [
    tempo.charge({
      currency: '0x20c0000000000000000000000000000000000000', // pathUSD (testnet)
      recipient: process.env.MPP_RECIPIENT as `0x${string}`,
      testnet: true,
    })
  ],
  secretKey: process.env.MPP_SECRET_KEY!,  // base64 string for HMAC challenge signing
})
```

Example:
```ts
export default {
  async fetch(request: Request) {
    const result = await mppx.charge({
      amount: '0.01',
      description: 'API access',
    })(request)

    if (result.status === 402) return result.challenge  // Return 402 + WWW-Authenticate header
    return result.withReceipt(Response.json({ data: '...' }))  // 200 + Payment-Receipt header
  }
}
```

Common errors:
- Forgetting `secretKey` — needed to HMAC-sign challenges and prevent replay.
- Using the wrong currency address (testnet vs mainnet).

## Operation: Monetize an API (Server — Hono)

WHEN:
- You're using Hono and want payment as middleware.

Function:
- `payment(mppx.charge, { amount, description? })` → Hono middleware

```ts
import { payment } from 'mppx/hono'
import { Mppx, tempo } from 'mppx/server'

const mppx = Mppx.create({
  methods: [tempo.charge({
      currency: '0x20c0000000000000000000000000000000000000', // pathUSD (testnet)
      recipient: process.env.MPP_RECIPIENT as `0x${string}`,
      testnet: true,
    })],
  secretKey: process.env.MPP_SECRET_KEY!,
})

app.use('/paid/*', payment(mppx.charge, { amount: '0.01', description: 'Paid resource' }))
```

## Operation: Monetize an API (Server — Next.js)

WHEN:
- You're using Next.js route handlers.

```ts
import { Mppx, tempo } from 'mppx/nextjs'

const mppx = Mppx.create({
  methods: [
    tempo.charge({
      currency: '0x20c0000000000000000000000000000000000000',
      recipient: process.env.MPP_RECIPIENT as `0x${string}`,
    })
  ],
})

export const GET = mppx.charge({ amount: '0.1' })(async () => {
  return Response.json({ data: '...' })
})
```

## Operation: Pay-as-you-go Sessions (Client)

WHEN:
- You're calling a metered API repeatedly (LLM tokens, streaming, many small requests) and want to avoid per-request on-chain costs.

Function:
- `tempo.session({ account, maxDeposit })` → session object with `.fetch()` and `.close()`

```ts
import { tempo } from 'mppx/client'
import { privateKeyToAccount } from 'viem/accounts'

const session = tempo.session({
  account: privateKeyToAccount(process.env.TEMPO_PRIVATE_KEY as `0x${string}`),
  maxDeposit: '5',
})

// First request opens an on-chain payment channel.
// Subsequent requests use off-chain vouchers (near-zero latency).
const res1 = await session.fetch('https://api.example.com/photo/1')
const res2 = await session.fetch('https://api.example.com/photo/2')

// Close the channel and reclaim unspent deposit:
await session.close()
```

Common errors:
- Not calling `session.close()` — unspent deposit stays locked in escrow.
- Setting `maxDeposit` too low for the total session cost.

## Operation: Accept Stripe Payments (Server)

WHEN:
- You want to accept card payments alongside or instead of Tempo stablecoins.

```ts
import { Mppx, stripe } from 'mppx/server'

const mppx = Mppx.create({
  methods: [
    stripe.charge({
      secretKey: process.env.STRIPE_SECRET_KEY!,
      paymentMethodTypes: ['card', 'link'],
    })
  ],
  secretKey: process.env.MPP_SECRET_KEY!,
})

const result = await mppx.charge({
  amount: '1',
  currency: 'usd',
  decimals: 2,
  description: 'Premium API access',
})(request)
```

## Operation: Sponsor Gas Fees (Server)

WHEN:
- You want clients to only need stablecoins — the server pays gas.

```ts
import { privateKeyToAccount } from 'viem/accounts'

tempo.charge({
  currency: '0x20c0000000000000000000000000000000000000', // pathUSD (testnet)
  recipient: process.env.MPP_RECIPIENT as `0x${string}`,
  feePayer: privateKeyToAccount(process.env.FEE_PAYER_KEY as `0x${string}`),
})
```

The `feePayer` account sponsors on-chain gas for pull-mode clients. Clients sign the tx, server broadcasts and pays gas.

## Operation: CLI — Make a Paid Request

WHEN:
- You want to test a paid endpoint from the terminal.

```bash
# Create an account and fund it (testnet):
npx mppx account create
npx mppx account fund

# Make a paid GET request (auto-handles 402):
npx mppx https://api.example.com/paid-resource

# POST with JSON body:
npx mppx https://api.example.com/search --method POST -J '{"query":"tempo"}'

# Inspect a server's challenge without paying:
npx mppx --inspect https://api.example.com/paid-resource
```

## Protocol Flow (HTTP 402)

For when you need to understand what happens under the hood:

```
Client                              Server
  |  GET /resource                    |
  |  -------------------------------->|
  |                                   |
  |  402 Payment Required             |
  |  WWW-Authenticate: Payment        |
  |    id="...", method="tempo",      |
  |    intent="charge", amount="0.01" |
  |  <--------------------------------|
  |                                   |
  |  [Client signs payment on-chain]  |
  |                                   |
  |  GET /resource                    |
  |  Authorization: Payment <cred>    |
  |  -------------------------------->|
  |                                   |
  |  [Server verifies payment]        |
  |                                   |
  |  200 OK                           |
  |  Payment-Receipt: <receipt>       |
  |  { data: "..." }                  |
  |  <--------------------------------|
```

You almost never need to implement this manually — `mppx` handles it.

## Common Errors

- **`402 Payment Required` in your app**: You're using plain `fetch()`. Switch to `mppx.fetch()`.
- **`method-unsupported`**: Server and client don't share a payment method. Check that both configure `tempo()`.
- **`invalid-challenge` / `payment-expired`**: Challenge timed out. Retry the original request to get a fresh challenge.
- **`verification-failed`**: Payment didn't settle on-chain. Check the account has sufficient stablecoin balance.
- **Wrong import path**: Client is `mppx/client`, server is `mppx/server`. Don't mix them.

## Data Freshness

> Last verified: 2026-03-19

If unsure about any MPP API, verify via `mcp__tempo__search_docs` with query `"machine payments"` or check `https://mpp.dev`.

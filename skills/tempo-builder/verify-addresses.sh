#!/usr/bin/env bash
# Verify that all predeployed contract addresses exist on Tempo Moderato testnet.
# Requires: cast (from Foundry)
# Usage: bash verify-addresses.sh

set -euo pipefail

RPC="https://rpc.moderato.tempo.xyz"

NAMES=(
  "pathUSD"
  "TIP-20 Factory"
  "Stablecoin DEX"
  "Fee Manager"
  "Account Keychain"
  "Nonce Manager"
  "TIP-403 Registry"
)

ADDRS=(
  "0x20c0000000000000000000000000000000000000"
  "0x20fc000000000000000000000000000000000000"
  "0xdec0000000000000000000000000000000000000"
  "0xfeec000000000000000000000000000000000000"
  "0xaAAAaaAA00000000000000000000000000000000"
  "0x4e4F4E4345000000000000000000000000000000"
  "0x403c000000000000000000000000000000000000"
)

echo "Verifying addresses on $RPC ..."
echo ""

FAILURES=0
for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  addr="${ADDRS[$i]}"
  code=$(cast code "$addr" --rpc-url "$RPC" 2>/dev/null || echo "ERROR")
  if [[ "$code" == "0x" || "$code" == "ERROR" ]]; then
    echo "FAIL  $name ($addr) — no code at address"
    FAILURES=$((FAILURES + 1))
  else
    echo "OK    $name ($addr)"
  fi
done

echo ""
if [[ $FAILURES -gt 0 ]]; then
  echo "$FAILURES address(es) failed verification."
  exit 1
else
  echo "All addresses verified."
fi

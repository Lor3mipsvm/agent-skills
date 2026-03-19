## Agent Skills

This repo contains skills for AI coding agents building on the Tempo network.

### Structure

- `skills/tempo/` — Research and exploration via MCP (docs + source browsing)
- `skills/tempo-builder/` — Code generation with mainnet-first examples and misconception correction

### Conventions

- Each skill has a `SKILL.md` (agent instructions) and `mcp.json` (MCP server config)
- MCP server key is `tempo` in both skills — tool names follow `mcp__tempo__*`
- Reference files in `references/` contain per-topic operation guides
- All code examples target mainnet by default; testnet is secondary
- Stablecoin decimals are 6, not 18

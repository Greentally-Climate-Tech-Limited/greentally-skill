# Greentally Skills

This repository contains agent skills for working with Greentally through MCP.

## `match-greentally-factors`

This skill reproduces the Greentally Direct Upload review flow inside a user's own AI agent:

1. The local agent reads and recognizes the source.
2. It extracts reviewable activity or spend rows.
3. It queries the organization-visible Greentally factor catalog through MCP.
4. It matches factors and prepares the standard emission CSV.
5. It validates the CSV and shows the exact result.
6. It stops and waits for a new explicit user confirmation before any MCP submission.
7. Only after confirmation, it submits the confirmed rows through MCP.

Original files remain local. The workflow is not limited to the formats accepted by the Greentally web uploader: it can process PDFs, images, spreadsheets, CSV, email, text, and other formats whenever the local agent can read them reliably.

## Install with an AI Agent

Give your agent this instruction:

```text
Fetch and follow the instructions from https://raw.githubusercontent.com/Greentally-Climate-Tech-Limited/greentally-skill/refs/heads/main/README.md to configure Greentally MCP and install the skill.
```

## Instructions for the Installing Agent

Complete these steps autonomously. Stop only when credentials or user authorization are required.

1. Check whether a Streamable HTTP MCP server named `greentally` is already configured.
2. If it is missing or unauthorized, ask the user for:
   - the Greentally service URL;
   - a Greentally API key beginning with `sk_`.
3. Never guess, echo, log, commit, or store the key outside the agent application's protected MCP credential/configuration mechanism.
4. Normalize a host-only service value to `https://<host>/mcp`. Preserve an explicit `http://` or `https://` scheme and append `/mcp` only when missing.
5. Configure stateless Streamable HTTP with this header:

   ```http
   Authorization: Bearer <greentally-api-key>
   ```

6. Verify the connection by listing tools. Expect:
   - `list_factor_categories`
   - `list_factor_libraries`
   - `list_factor_releases`
   - `list_factor_entries`
   - `get_factor_entry`
   - `create_factor_entry`
   - `update_factor_entry`
   - `import_factor_entries_csv`
   - `validate_emission_import_csv`
   - `submit_emission_import_csv`
7. Install or update the `match-greentally-factors` directory using the instructions below.
8. Verify that `SKILL.md`, `agents/openai.yaml`, and the three reference files are present.
9. Report MCP connection and skill installation status. Mention that a restart or reload may be required before the skill appears.

Never send an original source document to Greentally MCP. The installed skill keeps recognition and extraction in the local agent and sends only factor queries and finalized CSV text.

Never submit emission data proactively. The agent must validate first, display the exact submission summary, and wait for a new explicit confirmation. The user's initial request to process or upload a source is not final submission confirmation.

### Codex

```bash
git clone --depth 1 https://github.com/Greentally-Climate-Tech-Limited/greentally-skill.git /tmp/greentally-skill
mkdir -p ~/.codex/skills ~/.agents/skills
cp -R /tmp/greentally-skill/match-greentally-factors ~/.codex/skills/
ln -sfn ~/.codex/skills/match-greentally-factors ~/.agents/skills/match-greentally-factors
```

For an update, fetch a fresh copy and replace the installed skill directory. Do not keep credentials inside the skill directory.

### Claude Code

```bash
git clone --depth 1 https://github.com/Greentally-Climate-Tech-Limited/greentally-skill.git /tmp/greentally-skill
mkdir -p ~/.claude/skills
cp -R /tmp/greentally-skill/match-greentally-factors ~/.claude/skills/
```

### Other Agent Applications

1. Clone `https://github.com/Greentally-Climate-Tech-Limited/greentally-skill.git` to a temporary directory.
2. Copy `match-greentally-factors` into the application's skill directory.
3. Configure the Greentally MCP endpoint and Bearer header using the application's protected MCP configuration mechanism.
4. Restart or reload the application if necessary.

Invoke the installed skill as `$match-greentally-factors` or select it from the agent application's skill picker.

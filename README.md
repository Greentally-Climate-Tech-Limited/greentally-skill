# Greentally Skills

## version

0.0.1

Greentally Skills let a local AI agent analyze source documents, match organization-visible
emission factors, review the result, and save or submit it through the `greentally` CLI. The
local workflow is an enhancement to the Greentally Web workflow; Web analysis remains available
and both workflows use the same validation and storage contracts.

| Skill | Use it for | Reads source | Writes analysis | Submits |
| --- | --- | --- | --- | --- |
| `greentally-analyze-document` | Recognize or reanalyze a document | Yes | No | No |
| `greentally-match-factors` | Match or replace factors for existing analysis | No | No | No |
| `greentally-submit-analysis` | Review, save, or submit analysis | Only when a required fact must be reanalyzed | On explicit save or submit | On explicit confirmation |
| `greentally-process-document` | Run the complete workflow from source to optional submission | Yes | On explicit save or submit | On explicit confirmation |

Each Skill is self-contained. Install all four by default, or install an individual directory
when only one stage is needed.

## Install with an AI Agent

Give your agent this instruction:

```text
Fetch and follow the instructions from https://raw.githubusercontent.com/Greentally-Climate-Tech-Limited/greentally-skill/refs/heads/main/README.md to install the Greentally CLI and Greentally skills.
```

## Instructions for the Installing Agent

Complete these steps autonomously. Stop only when credentials or user authorization are required.

1. Clone `https://github.com/Greentally-Climate-Tech-Limited/greentally-skill.git` into a new
   system temporary directory.
2. Install all four Skill directories into the agent application's Skill directory. Do not copy
   `shared/`, `tools/`, or this README into a Skill directory.
3. Run `scripts/install.sh` from any installed Skill on Linux or macOS, or
   `scripts/install.ps1` on Windows. The script uses an existing CLI when available; otherwise it
   downloads the latest release for the current platform and verifies its SHA-256 checksum.
4. Run `greentally version` using the path printed by the installer.
5. Run `greentally auth status`. If authentication is not configured, run
   `greentally auth configure` and ask the user to enter a Greentally API key beginning with `sk_`
   directly into the command's hidden prompt. Never ask the user to send the key in chat.
6. Never echo, log, commit, pass on a command line, or store the API key in a normal text file.
   In headless or CI environments, instruct the user to set `GREENTALLY_API_KEY`.
7. Report the installed Skill names, CLI version, and authentication status. Mention that the
   agent application may need to reload before new Skills appear.
8. Remove only the temporary clone created in step 1.

### Codex

Install the four directories under `${CODEX_HOME:-$HOME/.codex}/skills`. When compatibility with
agents that discover `~/.agents/skills` is needed, create links from that directory to the four
installed Skill directories.

### Claude Code

Install the four directories under `~/.claude/skills`.

### Other Agent Applications

Use the application's documented Skill directory. Do not assume a global installation path.

To install only one Skill, copy only its directory and run its bundled installer. Every Skill can
install and use the CLI independently.

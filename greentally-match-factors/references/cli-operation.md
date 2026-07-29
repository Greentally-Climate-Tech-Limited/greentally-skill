# CLI Operation

## Installation and discovery

Run the bundled `scripts/install.sh` on Linux or macOS and `scripts/install.ps1` on Windows when
the CLI is unavailable. The installer checks, in order:

1. `GREENTALLY_CLI_PATH`;
2. the platform user cache;
3. `greentally` on `PATH`;
4. the latest `greentally-skill` GitHub Release.

It does not update an existing CLI. The Skill Release records the independently versioned latest
CLI in `cli-version.txt`. The installer selects that versioned archive, verifies it against
`checksums.txt`, extracts only the executable, and requires `greentally version` to report the
recorded CLI version.

Capture the executable path printed by the installer and invoke that exact path for the task.
Command examples use `greentally` as a readable placeholder; do not assume the cache directory was
added to `PATH`.

Use these cache locations:

- Linux: `${XDG_CACHE_HOME:-$HOME/.cache}/greentally/cli/greentally`
- macOS: `~/Library/Caches/Greentally/cli/greentally`
- Windows: `%LOCALAPPDATA%\Greentally\cli\greentally.exe`

## Authentication

Use the existing `sk_` API key flow. Resolve credentials from `GREENTALLY_API_KEY`, then from the
operating system credential store. Never request a `--api-key` flag, put a key in JSON input, or
write it to a normal configuration file. Use hidden input through `greentally auth configure`.
Never ask the user to send an API key in chat.
The default service URL is `https://api.greentally.ai`. Use `GREENTALLY_API_URL` or ordinary
non-secret CLI configuration for a non-default service URL.

Treat `UNAUTHORIZED` and `FORBIDDEN` as terminal until credentials or permissions change.

## Command surface

Use only:

```text
greentally version
greentally auth configure [--api-url URL]
greentally auth status
greentally auth logout

greentally document upload --file PATH
    [--location-id ID] [--department-id ID] [--currency CODE]
    [--file-type TYPE] [--factor-type TYPE]
greentally document get --document-id ID
greentally document download --document-id ID --output PATH

greentally factors categories
greentally factors libraries
greentally factors releases --library-id ID
    [--release-year YEAR] [--region-code CODE] [--published-only]
greentally factors search --release-id ID
    [--page NUMBER] [--size NUMBER] [--category-id ID] [--scope SCOPE]
    [--region-code CODE] [--query TEXT] [--published-only]
greentally factors get --factor-id ID [--published-only]

greentally analysis build --document-id ID --source-file PATH --input <file|->
greentally analysis prepare --document-id ID --input <file|->
greentally analysis get --document-id ID
greentally analysis upsert --document-id ID --input <file|->
greentally submit --document-id ID --analysis-version-id UUID --y [--confirm]
```

Analysis commands with structured JSON accept `--input <file>` or `--input -`; they do not accept
inline JSON. Submit reads the authoritative saved analysis by version and does not accept
`--input`.

Do not use Factor writes, document list/delete, AI/OCR, stream/history, emission management, draft
management, or direct REST calls.

## Output protocol

Except for `version`, parse exactly one stdout JSON object:

```json
{
  "schemaVersion": "greentally-cli-result/v1",
  "ok": true,
  "data": {}
}
```

Errors use:

```json
{
  "schemaVersion": "greentally-cli-result/v1",
  "ok": false,
  "error": {
    "code": "ANALYSIS_CHANGED",
    "message": "Analysis changed after review.",
    "details": {},
    "retryable": false
  }
}
```

Read required state only from stdout. Treat stderr as diagnostics. Exit code `0` means success,
`1` means an API, network, permission, business-state, or file error, and `2` means invalid CLI
arguments or local input. Branch primarily on `error.code`.

A successful build uses `data.schemaVersion: "emission-source-analysis-build/v1"` and returns
`documentId`, `sourceFileSha256`, `status`, `analysis`, and `diagnostics`. Preserve that
`sourceFileSha256` exactly for preparation and upsert.

Never suppress `SOURCE_FILE_MISMATCH`, `ANALYSIS_CHANGED`, `CONFIRMATION_REQUIRED`, `VALIDATION`,
`UNAUTHORIZED`, `FORBIDDEN`, or `NOT_FOUND`.

## Temporary workspace

Create a randomly named directory under the operating system temporary directory for each task.
Keep downloaded source, observation, analysis, preparation, and review artifacts there.
This is task-scoped transfer storage, not a recovery cache.

Delete only the directory created by the Skill when the task completes, is discarded, or cannot
continue. Never delete or replace a source supplied by the user. Never promise recovery after an
agent interruption. Save to the service only when the user explicitly chooses temporary save or
submit.

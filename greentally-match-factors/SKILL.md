---
name: greentally-match-factors
description: Match or replace organization-visible Greentally emission factors for an existing emission-source-analysis/v2 artifact, build bounded candidates and a selected factor for every carbon item, run local preparation, and present a review. Use when the user asks to find, compare, choose, rematch, or change factors without re-recognizing the source document, saving analysis, or submitting it.
---

# Greentally Match Factors

Match factors to an existing analysis and build a review locally. Do not reanalyze business facts,
save analysis, or submit data.

## Prepare

1. Read [references/cli-operation.md](references/cli-operation.md).
2. Read [references/factor-matching.md](references/factor-matching.md).
3. Read [references/emission-source-contract-v2.schema.json](references/emission-source-contract-v2.schema.json).
4. Locate or install the CLI with the bundled platform installer when necessary.
5. Verify authentication with `greentally auth status`.
6. Require an `emission-source-analysis/v2` artifact produced by `analysis build`. An
   `analysis get` result is a prepared `direct-upload-factor-review/v2`, not a build artifact; do
   not convert it by hand. When only a Document ID is available and rematching is required, use
   the complete document workflow to download and rebuild from the bound source first.
7. Create a random task directory under the operating system temporary directory.

## Match

1. Query categories and libraries, then filter releases with
   `greentally factors releases --library-id <id>`.
   Search one release at a time with `greentally factors search --release-id <id>` and inspect a
   candidate with `greentally factors get --factor-id <id>`. Use `--published-only` for
   operational matching.
2. Match every carbon record against visible published factors. Keep at most three candidates and
   one optional `selectedFactorId` per record.
3. Exclude non-carbon records from matches while preserving them in analysis.
4. Write a strict preparation object into the task directory and run:

   ```text
   greentally analysis prepare --document-id <id> --input <preparation.json>
   ```

5. Treat the CLI's factor metadata, compatibility checks, calculations, status, diagnostics, and
   warnings as authoritative.
6. If only the factor selection changes, edit `matches` and rerun `analysis prepare`.
7. If an amount, unit, date, currency, name, region, or carbon classification changes, stop and
   return to observation plus `analysis build`; never hand-edit the final `sourceRecord`.
8. Present the complete prepared review as a Markdown table, including non-carbon rows and amount
   reconciliation warnings. Return `needs_input` when no defensible compatible factor exists.
9. State clearly that nothing was saved or submitted, then remove the task directory.

Never invent factor IDs, factor values, units, currencies, categories, releases, or visibility.
Never use Factor write operations.

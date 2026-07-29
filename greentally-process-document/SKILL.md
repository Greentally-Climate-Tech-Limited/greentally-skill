---
name: greentally-process-document
description: Run the complete local Greentally document workflow from a local bill, invoice, receipt, utility statement, travel or waste document, spreadsheet, image, PDF, or an existing Document ID through analysis, factor matching, Markdown review, and an explicit choice to save, submit, or discard. Use when the user requests two or more stages, asks to process or import a document from start to finish, or asks to analyze, match, and submit in one workflow.
---

# Greentally Process Document

Run the complete workflow independently. Do not require the analyze, match, or submit Skills to be
installed.

## Prepare

1. Read [references/cli-operation.md](references/cli-operation.md).
2. Read [references/extraction-rules.md](references/extraction-rules.md).
3. Read [references/factor-matching.md](references/factor-matching.md).
4. Read [references/review-and-submit.md](references/review-and-submit.md).
5. Read [references/document-observation-v2.schema.json](references/document-observation-v2.schema.json)
   and [references/emission-source-contract-v2.schema.json](references/emission-source-contract-v2.schema.json).
6. Locate or install the CLI with the bundled platform installer when necessary.
7. Verify authentication with `greentally auth status`.
8. Create one random task directory under the operating system temporary directory. Store
   observation, analysis, preparation, review, submission, and any downloaded source there.

## Process

1. Upload a local source first with `greentally document upload --file <path>`, or fetch a supplied
   Document ID with `greentally document get --document-id <id>`.
2. Call `greentally analysis get --document-id <id>`. Reuse existing `completed` analysis by
   default. Download and reanalyze only when analysis is missing, is `needs_input`, or the user
   explicitly asks to reanalyze or correct a business fact. When the completed result already
   contains prepared candidates and selections, proceed directly to Review unless the user asks
   to rematch. If rematching is requested and no local `emission-source-analysis/v2` build
   artifact exists, download the bound source and rebuild it before matching; never hand-convert
   a prepared review into a build artifact.
3. When analyzing, query organization-visible factor categories, read the bound source locally,
   generate strict `document-observation/v2` using only visible category IDs in its hints, and run
   `greentally analysis build --document-id <id> --source-file <path> --input <observation.json>`.
   Preserve the returned `sourceFileSha256` through preparation and review.
4. Resolve `needs_input` by correcting observed facts and rebuilding. Never hand-edit a final
   `sourceRecord`.
5. For a newly built or explicitly rematched analysis, query organization-visible categories,
   libraries, releases, and entries. Build bounded matches for carbon records and run
   `greentally analysis prepare --document-id <id> --input <preparation.json>`.
6. Change only `matches` and rerun prepare when a factor changes. Return to observation and build
   when any business fact changes.
7. Present the complete Markdown review with carbon and non-carbon rows, candidates, selected
   factors, preview emissions, diagnostics, and amount warnings.
8. Ask whether to **save temporarily, submit, or discard**. Do not write before this post-review
   choice. When status is `needs_input` or the document is pure non-carbon, offer only temporary
   save or discard.
9. On save, strip server-owned fields, upsert the writable review snapshot, and report its new
   `versionId`.
10. On submit, upsert first. When the response has no `confirmationMessage`, submit its new
    `versionId` with
    `greentally submit --document-id <id> --analysis-version-id <versionId> --y`. Never reuse an
    older local version or construct submission items.
11. When upsert returns a non-empty `confirmationMessage`, display it and ask one separate
    confirmation question before submitting. Add `--confirm` only after the user confirms.
12. On discard, perform no write.
13. Report authoritative CLI results and remove the task directory in every terminal path. Never
    delete a user-provided source.

Do not auto-save, create a local recovery cache, upload outside the standard document flow, use
Factor write operations, or call Greentally APIs directly.

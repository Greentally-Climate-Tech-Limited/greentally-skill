---
name: greentally-analyze-document
description: Analyze or reanalyze a local bill, invoice, receipt, utility statement, travel document, waste document, spreadsheet, image, PDF, or an existing Greentally Document ID into document-observation/v2 and emission-source-analysis/v2. Use when the user asks to recognize, extract, analyze, correct business facts in, or locally reprocess one document, and stop before factor matching, saving, or submission.
---

# Greentally Analyze Document

Analyze the source locally and use the `greentally` CLI to enforce the same deterministic contract
as Greentally Web. Do not match factors, save analysis, or submit data.

## Prepare

1. Read [references/cli-operation.md](references/cli-operation.md).
2. Read [references/extraction-rules.md](references/extraction-rules.md).
3. Read [references/document-observation-v2.schema.json](references/document-observation-v2.schema.json)
   and [references/emission-source-contract-v2.schema.json](references/emission-source-contract-v2.schema.json).
4. Locate or install the CLI with the bundled platform installer when necessary.
5. Verify authentication with `greentally auth status`.
6. Create a random task directory under the operating system temporary directory. Delete only
   this directory when the task ends.

## Analyze

1. For a local source, upload it first with `greentally document upload --file <path>`; retain the
   returned Document ID.
2. For a Document ID, call `greentally document get --document-id <id>` and
   `greentally analysis get --document-id <id>`.
3. Reuse an existing `completed` analysis by default. Download and reanalyze the source only when
   analysis is missing, is `needs_input`, or the user explicitly requests reanalysis or a fact
   correction. When reusing it, return the fetched result and stop after cleanup; do not continue
   extraction.
4. When source access is required for a Document ID, use
   `greentally document download --document-id <id> --output <temporary-path>`. Never use an
   unrelated local file for that ID.
5. Query organization-visible factor categories and use only their exact IDs and names in optional
   observation matching hints.
6. Read the source with available local file, OCR, spreadsheet, archive, email, or application
   tools. Generate one strict `document-observation/v2` object from observed facts.
7. Write the observation into the task directory and run:

   ```text
   greentally analysis build --document-id <id> --source-file <path> --input <observation.json>
   ```

8. Parse the CLI JSON envelope. On `needs_input`, show the diagnostics and ask one focused
   question or reread the evidence; do not patch the final source record.
9. When a business fact changes, update the observation and rerun `analysis build`.
10. Return the resulting `emission-source-analysis/v2`, `sourceFileSha256`, diagnostics, and
   warnings. Clearly state that nothing was saved or submitted.
11. Remove the task directory after reading the outputs. Never delete a user-provided source.

Never call Greentally APIs directly or reproduce CLI validation in ad hoc scripts.

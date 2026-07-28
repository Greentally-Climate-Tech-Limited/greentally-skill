---
name: greentally-submit-analysis
description: Review a prepared Greentally direct-upload analysis or an existing Document ID, then explicitly offer to save, submit, or discard it. Use when the user asks to review, temporarily save, upsert, finalize, or submit analysis; enforce the final review gate, source-file binding, analysis version, upsert-before-submit, and greentally submit --y confirmation without redoing factor matching unless the review is stale or incomplete.
---

# Greentally Submit Analysis

Review the exact result and ask whether to save, submit, or discard. Never write before the user
makes that choice.

## Prepare

1. Read [references/cli-operation.md](references/cli-operation.md).
2. Read [references/review-and-submit.md](references/review-and-submit.md).
3. Locate or install the CLI with the bundled platform installer when necessary.
4. Verify authentication with `greentally auth status`.
5. Create a random task directory under the operating system temporary directory.
6. Require a prepared `direct-upload-factor-review/v2` object or a Document ID. For a Document ID,
   fetch the latest state with `greentally analysis get`.

## Review and Decide

1. Validate status and preserve every carbon and non-carbon item. For `completed`, verify that
   every carbon item has one compatible selected factor. For `needs_input`, preserve diagnostics
   and allow temporary save or discard, but not submit.
2. Present the exact source rows, amounts, units or currencies, dates, selected factors, candidates,
   emissions preview, diagnostics, and warnings in a Markdown table.
3. Highlight amount reconciliation warnings. Do not treat them as submission blockers.
4. Ask exactly one focused choice after the review: **save temporarily, submit, or discard**.
   Offer submit only when status is `completed`, every carbon item has a compatible factor, and the
   document contains at least one carbon item. The user's earlier request to process or submit the
   document is not confirmation for this gate.
5. On discard, perform no write and remove the task directory.
6. On temporary save, strip server-owned fields, write the dedicated upsert snapshot, run
   `greentally analysis upsert --document-id <id> --input <upsert.json>`, report the returned
   `versionId`, and stop.
7. On submit, first run the same upsert. Build the submission from the analysis and new `versionId`
   returned by that upsert, never from an older local review, then run:

   ```text
   greentally submit --document-id <id> --input <submission.json> --y
   ```

8. Report the server result, not a local prediction. Remove the task directory.

If any reviewed content changes, show the revised review and ask again. On `ANALYSIS_CHANGED`,
fetch the latest analysis, display what changed, and require a new review decision. Never bypass
`CONFIRMATION_REQUIRED`, `SOURCE_FILE_MISMATCH`, permissions, or server validation.

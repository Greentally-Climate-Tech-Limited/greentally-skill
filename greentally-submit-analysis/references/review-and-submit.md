# Review, Upsert, and Submit

## Review contract

Require a complete `direct-upload-factor-review/v2` result produced by `analysis prepare` or
returned by `analysis get`. Preserve:

- carbon review items and their candidates and selected factor;
- every carbon and non-carbon item in `allItems`;
- `filterOptions`, diagnostics, warnings, summary, and message;
- status `completed` or `needs_input`;
- `sourceFileSha256` returned by `analysis build` and carried through `analysis prepare`, or
  returned authoritatively by `analysis get`.
- optional item `emissionPreview` values from prepare.

Do not construct server-owned fields. The server owns upload and session identity, submitted state,
submission timestamps, `versionId`, provenance, and authoritative factor metadata.
`analysis get` returns the current `versionId` and `sourceFileSha256` at the analysis root. A
successful upsert returns a new root `versionId`.

Build the upsert input as a dedicated writable snapshot:

```json
{
  "schemaVersion": "direct-upload-factor-review/v2",
  "status": "completed",
  "sourceFileSha256": "sha256-returned-by-analysis-build",
  "items": [],
  "allItems": [],
  "filterOptions": {},
  "diagnostics": [],
  "warnings": [],
  "summary": "",
  "message": ""
}
```

Never copy `uploadId`, `sessionId`, `submitted`, `submittedAt`, `versionId`, or `provenance` from an
`analysis get` response into this write input.

Upsert accepts only `completed` or `needs_input`, rejects unknown fields and duplicate
`sourceId/itemId`, replaces the complete analysis snapshot, and creates a new UUID v4 `versionId`.
It also replaces persisted non-carbon items and authoritatively recalculates item
`emissionPreview`. Do not attempt to save `processing` or `error`.

## Amount reconciliation

Compare item spend or associated cost against document `netAmount` only when all relevant values
have a compatible currency. Compare at two decimal places.

Do not include VAT, gross amount, payments, amount due, or balance in the item sum. When an amount
is missing or currencies differ, state that an exact comparison is unavailable. A mismatch is a
visible warning, not a submission blocker.

## Markdown review

Before any write, show:

- document identity and status;
- each carbon and non-carbon row;
- source amount and activity unit or currency;
- dates and evidence;
- selected factor and up to two alternatives;
- confidence, match reason, compatibility, and warnings;
- per-row and total emissions preview;
- amount reconciliation result.

Require status `completed` and a compatible factor for every carbon row before submission.
Pure non-carbon documents can be saved but not submitted.

## Decision gate

After showing the exact review, ask the user to choose **save temporarily, submit, or discard**.
Do not infer this choice from the initial task, prior approval of analysis, silence, or timeout.

- **Discard:** perform no write.
- **Save temporarily:** call `analysis upsert` once and return the new `versionId`.
- **Submit:** call `analysis upsert` first, then submit the exact returned analysis with its new
  `versionId` and `--y`.

Build submit input from the successful upsert response, never from the older local review:

```json
{
  "schemaVersion": "emission-source-submission/v2",
  "analysisVersionId": "versionId-returned-by-upsert",
  "items": [
    {
      "sourceRecord": {},
      "factorId": "selected-factor-id"
    }
  ]
}
```

Use each complete returned `sourceRecord`; the abbreviated object above is illustrative only.

Any change to business facts, factor selection, or review JSON invalidates the displayed review.
Rebuild or prepare as appropriate, display the revised review, and ask again.

## Concurrency and file binding

The server generates a UUID v4 `versionId` on every Web analyze, Web save, and CLI upsert. Submit
uses `analysisVersionId` and locks the current analysis. On `ANALYSIS_CHANGED`, fetch the latest
analysis, show the changes, and require a new review decision.

The server also compares the submitted `sourceRecord + factorId` against the latest stored
analysis. Never modify submission rows after upsert.

The CLI computes source SHA-256 during build. Preparation and review carry that exact value, and
upsert compares it with the upload record. On `SOURCE_FILE_MISMATCH`, stop and obtain the source
bound to the Document ID. Never override the error.

## Submit confirmation

Use `greentally submit ... --y` only after the post-review choice. Without `--y`, the CLI returns
`CONFIRMATION_REQUIRED` locally and makes no API request. Never bypass this gate.

Report only the server's insertion, duplicate, calculation, or failure result as final. A local
preview is not proof of submission.

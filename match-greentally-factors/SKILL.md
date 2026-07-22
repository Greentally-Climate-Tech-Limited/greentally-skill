---
name: match-greentally-factors
description: Read any local file format the agent can reliably understand, extract bounded document-observation/v2 facts, canonicalize them through Greentally MCP, match canonical source records to organization-visible factors, validate the submission, and submit confirmed rows. Use for bills, invoices, receipts, PDFs, images, spreadsheets, CSV, email, text, or other locally readable sources when the user wants to recognize emissions data, choose factors, calculate a preview, or import reviewed source records without uploading the original source file.
---

# Match Greentally Factors

Keep the original source local. Extract only observed facts as `document-observation/v2`, call Greentally's deterministic canonicalizer to produce `emission-source-analysis/v2`, then use the canonical records for matching, validation, and reviewed submission.

## Mandatory Submit Gate

- Never call `submit_emission_source_records` proactively, autonomously, in the background, or merely because submission appears to be the next logical step.
- A user's initial request to process, analyze, import, or upload a source is not final submission confirmation.
- After successful validation, show the exact rows, selected factors, per-row emissions, total emission, and duplicate implications. Ask a focused confirmation question and stop. Wait for a new explicit affirmative response.
- Silence, timeout, lack of response, general approval of the analysis, or permission granted before the validation summary does not count as confirmation.
- If any source record, factor selection, or submission JSON changes after confirmation, validate again, show the revised summary, and obtain a new confirmation.
- Set `userConfirmed: true` only after this gate is satisfied. Otherwise never call the submit tool.

## Preconditions

1. Confirm that the `greentally` MCP server is connected and exposes the factor query plus emission source-record tools.
2. If it is unavailable or returns `UNAUTHORIZED`, stop and ask the user to configure the MCP URL and a valid `sk_` API key. Never guess, expose, or save the key in task output or this skill.
3. Treat every MCP result as scoped to the API key owner's current organization and current permissions. Do not bypass empty results or `FORBIDDEN`.
4. Never send the original document, its base64 representation, or its complete extracted text to Greentally MCP. Only send bounded `document-observation/v2` facts, factor search criteria, and the final standardized submission JSON.

## Load the References

- Read [references/document-and-matching-workflow.md](references/document-and-matching-workflow.md) before recognizing a source, extracting rows, or matching factors.
- Read [references/emission-source-contract.md](references/emission-source-contract.md), the [observation JSON Schema](references/document-observation-v2.schema.json), and the strict [source-record JSON Schema](references/emission-source-contract-v2.schema.json) before extraction, canonicalization, validation, or submission.
- Read [references/mcp-factor-tools.md](references/mcp-factor-tools.md) before planning MCP calls, handling errors, or performing writes.

## Execute the Workflow

1. Read the source locally with the agent's available file, OCR, spreadsheet, archive, email, database, or application tools. Accept any format that can be interpreted reliably; do not restrict the workflow to web-upload formats.
2. Preserve exact values, units, dates, geography, supplier, and page/row/line evidence. Mark unreadable or ambiguous evidence for review.
3. Route the source to single-item or multi-item extraction. Remove taxes, totals, payments, duplicate consumption charges, and other interference according to the extraction reference.
4. Load visible factor categories and use only their exact IDs and names in optional observation matching hints.
5. Build one bounded `document-observation/v2` artifact. Record only explicit facts; omit unknown optional properties and never invent `input`, values, units, currency, or dates. Classify with stable `documentCategory`, use an open lower-snake-case `documentType`, and place low-priority facts only in `additionalInfo`.
6. Call `canonicalize_emission_source_observations`. If it returns `needs_input`, show its diagnostics and resolve the missing facts with the user; do not hand-build or weaken the strict analysis contract.
7. Build the remaining catalog context from visible libraries and published releases, then match each canonical analysis record against visible factor entries. Treat activity unit as a hard constraint, relax year and region only in the documented order, and retain up to three factor candidates. Never invent an ID or factor value.
8. Present a review table containing the extracted source evidence, normalized amount/unit or spend/currency, dates, selected factor, factor value/unit, scope, confidence, alternatives, warnings, and preview emission.
9. Resolve every canonicalization or matching `needs_input` item with the user. Re-run canonicalization after changing observed facts. Do not include an unresolved record in the submission.
10. Build `emission-source-submission/v2` with `items: [{sourceRecord, factorId}]`, then call `validate_emission_source_records`. If `failedItems` is non-empty, correct the source record or factor selection and validate again. Do not submit a partially valid payload.
11. Show the validated row count, selected factors, per-row server-calculated emissions, total preview, and duplicate behavior. Ask whether to submit exactly these rows, stop, and wait for the user's new explicit confirmation.
12. Only after that confirmation, call `submit_emission_source_records` with the exact validated submission and `userConfirmed: true`. Treat its calculation and insertion result as authoritative. If confirmation is absent, leave the validated JSON local and do not submit.
13. Report inserted and duplicate counts, total emission, per-row status, and any MCP error. Never claim success from a local calculation alone.

## Default Extraction and Matching Rules

- Prefer physical activity such as energy, mass, volume, distance, fuel, or water over spend for the same consumption.
- Treat `item.input` as the only calculation-driving value. Never use `additionalInfo.quantity` as a factor-pick or calculation fallback.
- Use spend only when no trustworthy physical activity exists or the spend line is independently priced.
- Use `publishedOnly: true` for operational matching.
- Require exact normalized equality between the row source unit and factor `activityUnit`. For spend, require the ISO currency to match `activityUnit`.
- Prefer exact region, then a defensible fallback; prefer exact year, then nearest earlier year, then nearest year.
- Rank semantic matches in factor name and activity code above description or metadata.
- Calculate only a preview locally as `Value * factorValue` after unit compatibility is established. The MCP validation/submission result is final.
- Do not infer unsupported quantities, split a document total among unpriced lines, or silently convert dimensions.

## Safety and Writes

- Factor catalog writes are separate from emission submission. Call `create_factor_entry`, `update_factor_entry`, or `import_factor_entries_csv` only for an explicit factor-management request, never to force a document match.
- `submit_emission_source_records` creates organization source and emission records. Never invoke it without a new explicit confirmation obtained after showing the exact validation summary.
- Stable `source.sourceId` plus `item.itemId` values provide idempotent retry behavior. If `duplicateCount` is non-zero, report it; do not create new IDs merely to bypass deduplication.
- Public factors may be read but cannot be modified across organizations.
- Report stable MCP codes without hiding them: `VALIDATION`, `CONFIRMATION_REQUIRED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `PAYLOAD_TOO_LARGE`, and `UNAUTHORIZED`.

## Response Format

Before submission, report for each item:

- source label and evidence location;
- activity or spend, normalized value and unit/currency, period, supplier, and region;
- selected factor ID, name, value, unit, scope, library/release context when known;
- confidence, concise reason, warnings, and up to two alternatives;
- local preview and MCP validation preview.

After submission, report `insertedCount`, `duplicateCount`, `totalEmission`, unit, and per-row result. If no defensible match exists, return `needs_input` with one focused question. Never fabricate a factor ID or submit an incompatible unit.

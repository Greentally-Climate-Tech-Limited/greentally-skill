---
name: match-greentally-factors
description: Read any local file format the agent can reliably understand, extract reviewable emission activity or spend rows, match them to organization-visible factors through Greentally MCP, build and validate the Greentally emission import CSV, and submit confirmed rows to Greentally. Use for bills, invoices, receipts, PDFs, images, spreadsheets, CSV, email, text, or other locally readable sources when the user wants to recognize emissions data, choose factors, calculate a preview, or import the reviewed data into Greentally without uploading the original source file.
---

# Match Greentally Factors

Keep the original source local. Perform recognition and extraction with the local agent, use Greentally MCP only for factor catalog queries and final CSV validation/submission, and require review before creating emission records.

## Preconditions

1. Confirm that the `greentally` MCP server is connected and exposes the factor query plus emission CSV tools.
2. If it is unavailable or returns `UNAUTHORIZED`, stop and ask the user to configure the MCP URL and a valid `sk_` API key. Never guess, expose, or save the key in task output or this skill.
3. Treat every MCP result as scoped to the API key owner's current organization and current permissions. Do not bypass empty results or `FORBIDDEN`.
4. Never send the original document, its base64 representation, or its complete extracted text to Greentally MCP. Only send bounded factor search criteria and the final standardized CSV text.

## Load the References

- Read [references/document-and-matching-workflow.md](references/document-and-matching-workflow.md) before recognizing a source, extracting rows, or matching factors.
- Read [references/emission-csv-contract.md](references/emission-csv-contract.md) before creating, validating, or submitting CSV.
- Read [references/mcp-factor-tools.md](references/mcp-factor-tools.md) before planning MCP calls, handling errors, or performing writes.

## Execute the Workflow

1. Read the source locally with the agent's available file, OCR, spreadsheet, archive, email, database, or application tools. Accept any format that can be interpreted reliably; do not restrict the workflow to web-upload formats.
2. Preserve exact values, units, dates, geography, supplier, and page/row/line evidence. Mark unreadable or ambiguous evidence for review.
3. Route the source to single-item or multi-item extraction. Remove taxes, totals, payments, duplicate consumption charges, and other interference according to the extraction reference.
4. Build a bounded Greentally catalog context with visible categories, libraries, published releases, and entries. Never invent an ID or factor value.
5. Match each extracted item. Treat activity unit as a hard constraint, relax year and region only in the documented order, and retain up to three candidates with confidence and warnings.
6. Present a review table containing the extracted source evidence, normalized amount/unit or spend/currency, dates, selected factor, factor value/unit, scope, confidence, alternatives, warnings, and preview emission.
7. Resolve every `needs_input` item with the user. Do not include an unresolved row in the CSV.
8. Generate a local UTF-8 CSV file using the exact contract, normally `greentally-emission-import.csv`. Use deterministic Item IDs so retrying the same source cannot create duplicates. Pass its text content to MCP; do not treat this as an original-file upload.
9. Call `validate_emission_import_csv`. If `failedRows` is non-empty, correct the CSV and validate again. Do not submit a partially valid CSV.
10. Show the validated row count, selected factors, per-row server-calculated emissions, and total preview. Obtain explicit user confirmation to create these Greentally emission records.
11. Call `submit_emission_import_csv` with the byte-for-byte validated CSV content. Treat its calculation and insertion result as authoritative.
12. Report inserted and duplicate counts, total emission, per-row status, and any MCP error. Never claim success from a local calculation alone.

## Default Extraction and Matching Rules

- Prefer physical activity such as energy, mass, volume, distance, fuel, or water over spend for the same consumption.
- Use spend only when no trustworthy physical activity exists or the spend line is independently priced.
- Use `publishedOnly: true` for operational matching.
- Require exact normalized equality between the row source unit and factor `activityUnit`. For spend, require the ISO currency to match `activityUnit`.
- Prefer exact region, then a defensible fallback; prefer exact year, then nearest earlier year, then nearest year.
- Rank semantic matches in factor name and activity code above description or metadata.
- Calculate only a preview locally as `Value * factorValue` after unit compatibility is established. The MCP validation/submission result is final.
- Do not infer unsupported quantities, split a document total among unpriced lines, or silently convert dimensions.

## Safety and Writes

- Factor catalog writes are separate from emission submission. Call `create_factor_entry`, `update_factor_entry`, or `import_factor_entries_csv` only for an explicit factor-management request, never to force a document match.
- `submit_emission_import_csv` creates organization emission records. Validate first and obtain confirmation after showing the exact import summary.
- Stable Item IDs provide idempotent retry behavior. If `duplicateCount` is non-zero, report it; do not create new IDs merely to bypass deduplication.
- Public factors may be read but cannot be modified across organizations.
- Report stable MCP codes without hiding them: `VALIDATION`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `PAYLOAD_TOO_LARGE`, and `UNAUTHORIZED`.

## Response Format

Before submission, report for each item:

- source label and evidence location;
- activity or spend, normalized value and unit/currency, period, supplier, and region;
- selected factor ID, name, value, unit, scope, library/release context when known;
- confidence, concise reason, warnings, and up to two alternatives;
- local preview and MCP validation preview.

After submission, report `insertedCount`, `duplicateCount`, `totalEmission`, unit, and per-row result. If no defensible match exists, return `needs_input` with one focused question. Never fabricate a factor ID or submit an incompatible unit.

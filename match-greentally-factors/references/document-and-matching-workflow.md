# Document Extraction and Factor Matching Workflow

## Contents

1. Recognition
2. Extraction routing
3. Field extraction
4. Item validity and deduplication
5. Normalization
6. Canonical analysis JSON
7. Catalog-bounded matching
8. Candidate ranking
9. Final validation

## 1. Recognition

Use locally readable source content as the source of truth and the filename only as a weak hint. The source may be a PDF, image, spreadsheet, delimited file, document, email, message, database export, or any other format the local agent can reliably interpret. Never send the original content to Greentally MCP.

Recognize these direct document kinds when evidence is clear:

- `electricity_utility_bill`
- `gas_fuel_bill`
- `water_utility_bill`
- `waste_disposal_document`
- `business_travel_document`

Also process purchase invoices, material invoices, service invoices, spreadsheets, and other readable business documents through the general extraction workflow.

Assign one recognition status:

- `recognized`: a clear supported document;
- `needs_review`: plausible but ambiguous, partial, low-quality, or low-confidence;
- `unsupported`: no reliable emissions-relevant document type or unreadable content.

Do not extract from a source the local agent cannot read reliably. State what is unreadable and request a different representation or the missing local capability.

## 2. Extraction Routing

Choose `multi_item` only when multiple distinct emissions activities or priced goods/services have their own compatible physical amounts or explicit line-level spend amounts.

Choose `single_item` when:

- one utility consumption total, fuel, trip, waste service, or invoice-level activity is present;
- many descriptions or quantities exist but only one invoice subtotal is priced;
- several readings describe the same utility service and should be summarized;
- uncertainty would make line-level allocation unsafe.

Ignore VAT, tax, discounts, payments, balances, notes, references, subtotals, totals, and non-consumption charges when deciding whether a document is multi-item.

## 3. Field Extraction

Preserve exact source evidence. Extract document-level fields when present:

- document kind, supplier, location, original country text, ISO-3166 alpha-3 `regionCode`;
- account or meter number;
- meaningful invoice title, invoice number, invoice date;
- currency, net subtotal before tax, tax, gross total;
- period start and end dates;
- warnings and page, row, or line evidence.

For every emissions item, extract:

- stable local item label and a non-empty suggested name;
- `calculationType`: `activity` or `spend`;
- semantic `activityName` kept separate from the display name;
- physical `amount` and `unit`, or trustworthy `spendValue`/`lineTotal` and ISO currency;
- row-specific quantity, quantity unit, dimensions, or unit price when useful;
- original and normalized geography;
- up to eight semantic factor keywords;
- concise evidence.

Exclude supplier/customer names, invoice numbers, account numbers, bare SKUs, currency codes, and generic words such as `invoice`, `item`, `total`, `tax`, or `payment` from factor keywords.

## 4. Item Validity and Deduplication

### Activity items

- Use consumption or usage quantities, not price, rate, tax, standing charge, capacity charge, reactive power, levy, or line total.
- Prefer electricity and gas consumption in kWh when explicitly present.
- If a row has both physical consumption and its charge, keep one activity item and retain the charge only as supporting spend evidence.
- Keep separate utility registers only when each has its own physical amount and represents a separately matchable activity.

### Spend items

- Use spend only when no compatible physical activity is available or the priced line is independent.
- Prefer net amount before VAT/tax.
- Split priced children only when every retained child has its own explicit line amount.
- If rows are unpriced and only a document total exists, keep exactly one invoice-level spend item.
- Never copy one invoice subtotal or total into several spend items.

### Interference and duplicates

Remove VAT, sales tax, discounts, deposits, payments, balances, amount due, subtotals, totals, rounding, credits, standing charges, availability/MIC charges, reactive power charges, and levies unless the line itself is an independently purchased emissions-relevant service.

When trustworthy physical activity and a spend line represent the same underlying consumption charge, keep the activity item and remove the duplicate spend item before factor matching.

## 5. Normalization

Normalize physical units conservatively:

| Source forms | Normalized form |
| --- | --- |
| gram, grams | `g` |
| kilogram, kilograms | `kg` |
| kilometre(s), kilometer(s) | `km` |
| metre(s), meter(s) | `m` |
| cubic metre(s), cubic meter(s) | `m3` |
| liter(s), litres | `litre` |
| mile(s) | `mile` |
| metric ton(s), tonnes | `tonne` |

Keep established catalog spellings such as `kWh`, `MWh`, `therm`, `l`, or `each` when they are the actual MCP `activityUnit`. Compare units case-insensitively after whitespace and alias normalization, but do not perform an unproven dimensional conversion.

Normalize currency symbols and names to ISO codes when unambiguous, for example `€` to `EUR`, `£` to `GBP`, and an explicitly US `$` to `USD`. Ask when `$` geography is ambiguous.

Normalize country evidence to ISO-3166 alpha-3 codes. Keep `GLOBAL` as a catalog geography, not as an inferred document country. Derive source year from the activity period end, start, or invoice date in that order.

## 6. Canonical Analysis JSON

Before serializing, call `list_factor_categories` and choose one to three `matchingHints.categoryCandidates` only from the returned exact IDs and names. Catalog discovery is context building, not factor-entry matching. Do not generate an ID from a category name.

Serialize the validated, deduplicated, normalized source facts and catalog-bounded matching hints as `emission-source-analysis/v1` before searching or selecting factor entries. Read [emission-source-contract.md](emission-source-contract.md) and validate the artifact against the root of [emission-source-contract-v1.schema.json](emission-source-contract-v1.schema.json).

Keep source facts in each `sourceRecord` and catalog-search guidance in its sibling `matchingHints`. Use the exact lower-camel-case property names. Do not emit a free-form alternative object, CSV row, selected factor, or calculation snapshot at this stage.

## 7. Catalog-Bounded Matching

### Build context

1. Reuse the exact category IDs and names already recorded in the analysis artifact.
2. Call `list_factor_libraries` if they were not loaded while building the analysis context.
3. Call `list_factor_releases` for relevant libraries with `publishedOnly: true`.
4. Select release candidates by region and year before searching entries.

If a later no-match expansion changes the category candidates, update `matchingHints.categoryCandidates` with exact catalog values and revalidate the analysis artifact before continuing.

### Search stages

For each extracted item, search in this order:

1. category + exact region + exact or best source-year release + semantic query;
2. category + defensible fallback region + best source-year release;
3. category + exact/fallback region with year relaxed;
4. category + activity unit with region relaxed, producing a low-confidence warning;
5. expand to up to three additional catalog categories only when the original categories return no compatible candidate.

Use `list_factor_entries` with `categoryId`, `regionCode`, `scope` only when known, `query`, and `publishedOnly: true`. Try concise keywords separately when a combined query is too restrictive. Page only as far as needed to establish a defensible candidate set.

The MCP entry search does not enforce `activityUnit`. Post-filter every activity candidate and reject entries whose normalized `activityUnit` differs from the extracted activity unit. For spend items, match the ISO currency to `activityUnit`.

## 8. Candidate Ranking

Keep at most three unique candidates per item. Rank with these priorities:

1. hard activity-unit compatibility;
2. selected category compatibility;
3. exact region, then an explicitly defensible fallback region;
4. exact year, then nearest earlier year, then nearest year;
5. semantic keyword matches in name and `activityCode`;
6. description and metadata evidence;
7. scope compatibility when scope is known.

Assign confidence:

- `high`: exact unit, category, region, and year, with clear semantic agreement;
- `medium`: compatible unit/category with a fallback region, nearest year, or missing source year;
- `low`: region was relaxed, category was expanded, semantic fit is weak, or critical evidence is ambiguous.

Never label a match high confidence when the source year is unavailable.

## 9. Final Validation

For each candidate:

1. Verify that its ID came from MCP output in the current run.
2. Reject contradictions in category, activity unit, geography, fuel/service/material meaning, period, or scope.
3. Call `get_factor_entry` for the selected candidate when its full details need confirmation.
4. Keep a reasonable fallback when exact region/year data is unavailable, but attach a warning.
5. If no candidate survives, expand categories once or return `needs_input`.

Do not use a candidate merely because it has a similar name. Unit and category constraints take precedence over lexical similarity.

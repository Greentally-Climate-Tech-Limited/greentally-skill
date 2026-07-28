# Document Extraction Rules

## Source identity

- Treat source content as authoritative and filenames as weak hints.
- Upload a local file before analysis and use the returned Document ID as `source.sourceId`.
- Set `source.sourceName` from the bound upload. Do not invent a supplier-based identity.
- For an existing Document ID, download its source through the CLI before local analysis.
- Pass both Document ID and source path to `analysis build`. The CLI computes SHA-256; upsert later
  rejects a different file with `SOURCE_FILE_MISMATCH`.
- Preserve `data.sourceFileSha256` from the successful `analysis build` envelope. Pass it unchanged
  through preparation and review into upsert.
- Keep full OCR text and intermediate recognition local. Send only the bounded observation through
  the CLI.

## Observation contract

Produce strict `document-observation/v2`:

- include `schemaVersion`, `source`, `items`, `warnings`, and `summary`;
- set `item.isCarbon` on every item;
- do not emit `item.input`; core chooses activity or spend deterministically;
- omit unknown optional fields, null values, and empty optional objects;
- never use empty strings, placeholders, zero, or invented values for missing facts;
- preserve exact amounts, units, dates, supplier, location, account or meter identifiers, and
  concise page, row, or line evidence;
- normalize clear countries to uppercase ISO-3166 alpha-3 codes;
- use a stable lower-snake-case `documentType` and one allowed `documentCategory`;
- keep each evidence quote and reference at most 240 characters;
- keep summary at most 1200 characters and do not transcribe the full document.

Missing amounts, units, currencies, names, or dates are valid observations. Add a concise warning
when review is needed and let `analysis build` return deterministic `needs_input` diagnostics.

## Extraction routing

Choose multi-item extraction only when distinct activities or purchased lines have their own
compatible physical amount or explicit line-level spend.

Choose a single item when one utility consumption, fuel, trip, waste service, or invoice-level
purchase is present, or when many described rows share only one priced total. If uncertain, prefer
one item and surface low confidence.

Ignore VAT summaries, discounts, payments, balances, notes, references, subtotals, and totals when
deciding whether a document is multi-item.

## Carbon classification

Retain separately priced rows that contribute to the net subtotal:

- set `isCarbon=true` for physical consumption, fuel, water, transport, waste, purchased goods,
  and services that require factor matching;
- set `isCarbon=false` for standing, capacity, availability, grid or market trading, levy,
  electricity tax, reactive power, and similar administration or tariff charges;
- do not create items for net subtotal, VAT summary, gross total, previous balance, credits,
  payments, amount due, or total due;
- preserve net, tax, and gross totals only in `source.additionalInfo.totals`.

Non-carbon items remain reviewable and are persisted with zero emissions, but never enter factor
matching.

## Activity and spend

- Prefer trustworthy physical activity over spend for the same consumption.
- For utilities, use consumption quantities, not price, rate, tax, standing charge, or line total.
- When a row contains physical activity and its charge, keep one item with activity plus supporting
  spend; do not create a duplicate spend item.
- Use spend when no compatible physical activity exists or when the priced line is independent.
- Split spend items only when every retained child has its own explicit line amount.
- When only a document-level price exists, create exactly one invoice-level spend item using the
  net amount before VAT or tax.
- Never copy an invoice subtotal, gross total, or amount due into multiple items.
- Keep `additionalInfo.quantity` as evidence only; never use it as calculation input.

Normalize conservative unit aliases such as grams to `g`, kilograms to `kg`, kilometres to `km`,
cubic metres to `m3`, litres to `litre`, miles to `mile`, and tonnes to `tonne`. Keep exact catalog
spellings such as `kWh`, `MWh`, `therm`, `l`, and `each` when appropriate. Do not perform an
unproven dimensional conversion.

Normalize unambiguous currency to uppercase ISO-4217. Ask when a symbol such as `$` is ambiguous.

## Dates and matching hints

- Preserve start and end independently; do not invent a missing boundary.
- Use the activity period end, then start, then document date as the release-year hint.
- Use exact category IDs and names obtained from the visible catalog, at most three.
- Keep `activityName` separate from the review/storage name.
- Use at most eight semantic factor keywords; omit supplier names, document numbers, account
  numbers, bare SKUs, currency codes, and generic invoice or payment words.
- Recommend at most three catalog-provided fallback regions without replacing an evidenced source
  region.

## Corrections

Change business facts only in observation and rerun `analysis build`. Business facts include
amount, unit, currency, date, supplier, name, region, evidence, and carbon classification. Never
hand-edit the final `sourceRecord` to bypass canonical validation.

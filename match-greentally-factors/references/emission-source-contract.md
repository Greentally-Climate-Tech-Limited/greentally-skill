# Greentally Emission Source Contract

## Purpose

Represent every locally extracted bill, invoice, utility, travel, waste, or spreadsheet item with the same versioned JSON used by Greentally's internal Factor Agent. The machine-readable authority is [emission-source-contract-v1.schema.json](emission-source-contract-v1.schema.json). Its root validates `emission-source-analysis/v1`; its `#/$defs/submission` subschema validates `emission-source-submission/v1`.

The original source remains local. Submit only the bounded source facts needed for review, audit, and calculation. Do not include full OCR text, file bytes, base64, factor candidates, or factor snapshots in `sourceRecord`.

## Analysis Artifact

Create exactly one `emission-source-analysis/v1` object:

```json
{
  "schemaVersion": "emission-source-analysis/v1",
  "records": [
    {
      "sourceRecord": {
        "schemaVersion": "emission-source-record/v1",
        "source": {
          "sourceId": "9ca1f0c2",
          "sourceName": "electricity-invoice-2026-01.pdf",
          "documentType": "electricity_utility_bill",
          "documentNumber": "INV-2026-001",
          "documentDate": "2026-02-02",
          "supplier": "Example Energy",
          "accountNumber": "ACC-1001",
          "country": "Ireland",
          "regionCode": "IRL",
          "currency": "EUR",
          "netAmount": 318.2
        },
        "item": {
          "itemId": "winter-day",
          "name": "Winter day electricity consumption",
          "calculationType": "activity",
          "activityValue": 1250.4,
          "activityUnit": "kWh",
          "spendValue": 318.2,
          "currency": "EUR",
          "regionCode": "IRL",
          "startDate": "2026-01-01",
          "endDate": "2026-01-31"
        },
        "evidence": [
          {
            "field": "item.activityValue",
            "quote": "Winter day 1,250.4 kWh",
            "reference": "page 2"
          }
        ],
        "remarks": []
      },
      "matchingHints": {
        "activityName": "grid electricity consumption",
        "categoryCandidates": [],
        "fallbackRegionCodes": ["GBR"],
        "factorKeywords": ["electricity", "grid", "consumption"],
        "releaseYear": 2026
      }
    }
  ],
  "warnings": [],
  "summary": "One electricity consumption item was extracted."
}
```

Use lower camel case exactly. Do not add properties outside the schema.

## Source Identity

- Set `source.sourceId` to a stable local source fingerprint. Prefer the lowercase SHA-256 prefix of the original local source content.
- Set `item.itemId` to a stable identifier within that source, such as `page-2:winter-day` or `line-7`.
- Reuse both values for retries. Never change them to bypass a duplicate.
- Set `source.sourceName` to the local file name or a concise user-visible source label. Do not send the source itself.

## Activity and Spend Rules

- For `calculationType: activity`, require positive `activityValue` and non-empty `activityUnit`.
- For `calculationType: spend`, require non-negative `spendValue` and uppercase ISO-4217 `currency`.
- An activity record may also contain its explicitly associated `spendValue` and `currency`; do not create a duplicate spend record for the same consumption.
- Use `quantityValue`, `quantityUnit`, and `unitPrice` only for independently evidenced invoice-line details. They are source facts, not substitutes for activity or spend values.
- Use ISO-3166 alpha-3 `regionCode` or `GLOBAL`. Keep original geography text in `country` or `location`.
- Require `startDate` and `endDate` as `YYYY-MM-DD`; for a single dated invoice use the same date for both.

## Matching Boundary

Keep `matchingHints` outside `sourceRecord`. It may contain bounded category candidates, factor keywords, fallback regions, and a release year, but never a selected factor ID or factor value.

After selecting a visible compatible factor, build the following object and validate it with the machine schema's `#/$defs/submission` JSON Pointer (or an equivalent validator wrapper whose `$ref` targets that pointer):

```json
{
  "schemaVersion": "emission-source-submission/v1",
  "items": [
    {
      "sourceRecord": { "schemaVersion": "emission-source-record/v1" },
      "factorId": "12345"
    }
  ]
}
```

The abbreviated `sourceRecord` above is illustrative only; submit the complete validated object. Greentally stores that object as the authoritative `emission_source_records.payload`. Factor selection and calculation snapshots are stored separately and appear in the Factors Table, not the source-record Table.

## Validation and Submission

1. Call `validate_emission_source_records` with the complete submission.
2. Require `failedItems` to be empty and `validItems` to equal `totalItems`.
3. Compare returned factor IDs, factor values, emissions, and units with the review table.
4. Show the exact validation summary, ask whether to submit those records, stop, and wait for a new explicit affirmative response.
5. Call `submit_emission_source_records` only after that response, using the unchanged submission plus `userConfirmed: true`.

Any source-record or factor-selection change invalidates confirmation and requires revalidation and reconfirmation.

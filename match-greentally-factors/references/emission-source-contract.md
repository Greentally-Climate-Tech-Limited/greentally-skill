# Greentally Emission Source Contract v2

## Purpose

Represent every locally extracted bill, invoice, utility, travel, waste, statement, or data table with the same two-stage contract used by Greentally's Factor Agent. [document-observation-v2.schema.json](document-observation-v2.schema.json) validates observed facts. Greentally's canonicalizer produces the strict [emission-source-contract-v2.schema.json](emission-source-contract-v2.schema.json); its root validates `emission-source-analysis/v2` and `#/$defs/submission` validates `emission-source-submission/v2`.

The original source remains local. Submit only bounded business facts required for review, audit, and calculation. Never put full OCR text, file bytes, base64, factor candidates, selected factors, or factor snapshots in `sourceRecord`.

## Document classification

`source.documentCategory` is a stable routing category and must be one of:

- `utility_bill`, `invoice`, `travel_document`, `waste_document`
- `statement`, `data_table`, `other`

`source.documentType` is optional and extensible. When present, use descriptive lower snake case such as `electricity_utility_bill`, `material_invoice`, or a future type such as `district_heating_statement`. It must match `^[a-z][a-z0-9_]{0,63}$`. Do not expand the category enum merely to add a new document type.

## Observation artifact

Create `document-observation/v2` first. Omit unknown optional properties, empty `additionalInfo` objects, and all `null` values. Put only the calculation-driving amount in `activity` or `spend`; low-priority invoice details belong in `additionalInfo` and are never a fallback activity value.

```json
{
  "schemaVersion": "document-observation/v2",
  "source": {
    "sourceId": "9ca1f0c2",
    "sourceName": "electricity-invoice-2026-01.pdf",
    "documentCategory": "utility_bill",
    "documentType": "electricity_utility_bill",
    "documentDate": "2026-02-02",
    "supplier": "Example Energy",
    "regionCode": "IRL",
    "additionalInfo": {
      "identifiers": {"accountNumber": "ACC-1001", "meterNumber": "MTR-42"},
      "totals": {"netAmount": 318.2, "currency": "EUR"}
    }
  },
  "items": [{
    "itemId": "winter-day",
    "name": "Winter day electricity consumption",
    "activity": {"value": 1250.4, "unit": "kWh"},
    "startDate": "2026-01-01",
    "endDate": "2026-01-31",
    "evidence": [{"field": "item.activity.value", "quote": "Winter day 1,250.4 kWh"}],
    "remarks": [],
    "matchingHints": {
      "activityName": "grid electricity consumption",
      "categoryCandidates": [],
      "fallbackRegionCodes": [],
      "factorKeywords": ["electricity", "grid", "consumption"]
    }
  }],
  "warnings": [],
  "summary": "One electricity item was observed."
}
```

Call `canonicalize_emission_source_observations` with this object and use its returned analysis unchanged. `needs_input` is expected when calculation-driving facts are incomplete; resolve the diagnostics and canonicalize again.

## Canonical analysis artifact

The canonicalizer returns `emission-source-analysis/v2`. Each record contains an `emission-source-record/v2`:

```json
{
  "schemaVersion": "emission-source-analysis/v2",
  "records": [{
    "sourceRecord": {
      "schemaVersion": "emission-source-record/v2",
      "source": {
        "sourceId": "9ca1f0c2",
        "sourceName": "electricity-invoice-2026-01.pdf",
        "documentCategory": "utility_bill",
        "documentType": "electricity_utility_bill",
        "documentNumber": "INV-2026-001",
        "documentDate": "2026-02-02",
        "supplier": "Example Energy",
        "regionCode": "IRL",
        "additionalInfo": {
          "identifiers": {"accountNumber": "ACC-1001"},
          "totals": {"netAmount": 318.2, "currency": "EUR"}
        }
      },
      "item": {
        "itemId": "winter-day",
        "name": "Winter day electricity consumption",
        "input": {"type": "activity", "value": 1250.4, "unit": "kWh"},
        "regionCode": "IRL",
        "startDate": "2026-01-01",
        "endDate": "2026-01-31",
        "additionalInfo": {"associatedCost": {"value": 318.2, "currency": "EUR"}}
      },
      "evidence": [{
        "field": "item.input.value",
        "quote": "Winter day 1,250.4 kWh",
        "reference": "page 2"
      }],
      "remarks": []
    },
    "matchingHints": {
      "activityName": "grid electricity consumption",
      "categoryCandidates": [],
      "fallbackRegionCodes": ["GBR"],
      "factorKeywords": ["electricity", "grid", "consumption"],
      "releaseYear": 2026
    }
  }],
  "warnings": [],
  "summary": "One electricity consumption item was extracted."
}
```

Use lower camel case exactly and add no properties outside the schema.

## Calculation input and additional information

- `item.input` is always required and is the only factor-calculation input.
- Activity input requires `{"type":"activity","value": positive number,"unit": non-empty activity unit}`.
- Spend input requires `{"type":"spend","value": non-negative number,"unit": uppercase ISO-4217 currency}`.
- `item.additionalInfo.quantity` records an independently evidenced commercial quantity only. It never substitutes for `input` and does not influence factor selection.
- `unitPrice` and `associatedCost` use `{"value": number,"currency":"EUR"}`. An activity record may retain its associated monetary cost without creating a duplicate spend record.
- Source identifiers and document totals belong only under `source.additionalInfo`.
- Omit an `additionalInfo`, `identifiers`, or `totals` object when it would be empty.
- Use ISO-3166 alpha-3 `regionCode` or `GLOBAL`; retain free-form place text in `location`.
- Require `startDate` and `endDate` as `YYYY-MM-DD`; use the same date for a single dated item.

## Identity and matching boundary

- Use a stable local fingerprint for `source.sourceId` and a stable within-source identifier for `item.itemId`; reuse both on retries.
- Keep `matchingHints` outside `sourceRecord`. It may contain bounded catalog candidates and search hints, never a selected factor ID or factor value.
- Quantity, product code, meter number, totals, and other `additionalInfo` do not drive factor selection.

After selecting a visible compatible factor, build and validate:

```json
{
  "schemaVersion": "emission-source-submission/v2",
  "items": [{
    "sourceRecord": {"schemaVersion": "emission-source-record/v2"},
    "factorId": "12345"
  }]
}
```

The abbreviated record is illustrative only; submit the complete validated object. Greentally stores the source record as the authoritative `emission_source_records.payload`. Factor selection and calculation snapshots are stored separately and appear in the Factors Table, not the source-record Table.

## Validation and submission

1. Call `validate_emission_source_records` with the complete V2 submission.
2. Require `failedItems` to be empty and `validItems` to equal `totalItems`.
3. Show the exact rows, selected factors, calculated emissions, units, and duplicate behavior.
4. Ask whether to submit those exact records, stop, and wait for a new explicit affirmative response.
5. Call `submit_emission_source_records` only after that response, with the unchanged submission and `userConfirmed: true`.

Any source-record or factor-selection change invalidates confirmation and requires revalidation and reconfirmation.

# Factor Matching and Preparation

## Preparation input

Build this strict shape:

```json
{
  "schemaVersion": "direct-upload-factor-preparation/v1",
  "sourceFileSha256": "sha256-returned-by-analysis-build",
  "analysis": {
    "schemaVersion": "emission-source-analysis/v2",
    "records": [],
    "warnings": [],
    "summary": ""
  },
  "diagnostics": [],
  "matches": [
    {
      "sourceId": "document-id",
      "itemId": "line-1",
      "candidates": [
        {
          "factorId": "factor-id",
          "confidence": "high",
          "reason": "Exact electricity activity and kWh unit.",
          "warnings": []
        }
      ],
      "selectedFactorId": "factor-id"
    }
  ]
}
```

Require exactly one `matches` entry for every carbon record and none for non-carbon records. Keep
at most three unique candidates ordered best to worst. `selectedFactorId` may be absent; when
present, require it to appear in candidates.

Copy `sourceFileSha256` exactly from the successful `analysis build` envelope. Do not calculate a
replacement from a different file or omit it. `analysis prepare` carries it into review, and
`analysis upsert` uses it for server-side source binding.

Copy the required root `diagnostics` array from the build result without dropping unresolved
diagnostics. Preparation carries them into review.

Provide only factor ID, `high|medium|low` confidence, a concise reason, and warnings. The CLI fetches
authoritative factor metadata, verifies visibility and compatibility, and may return
`emissionPreview: {"value": number, "unit": string}` on prepared review items.

## Catalog scope

Query organization-visible categories, libraries, published releases, entries, and entry details
through CLI read commands. Never invent an ID or use Factor create, update, delete, or import.

Use published factors for operational matching. Treat API results as scoped to the authenticated
organization. Do not bypass empty results or permission errors.

## Hard constraints

- For activity, require exact normalized compatibility between `sourceRecord.item.input.unit` and
  factor `activityUnit`.
- For spend, require the uppercase ISO currency to match factor `activityUnit`.
- Reject factors whose category, activity unit, fuel or service label, region, or applicability
  contradicts source evidence.
- Never infer missing quantities, silently convert dimensions, or use
  `additionalInfo.quantity` as input.
- Never trust a factor value supplied by the Agent; use only CLI-returned metadata.

## Ranking

1. Prefer a physical activity factor over a spend factor for the same consumption.
2. Rank semantic matches in factor name and activity code above description or metadata.
3. Prefer exact evidenced region, then a defensible fallback, then `GLOBAL` when appropriate.
4. Prefer exact activity year, then nearest earlier year, then nearest available year.
5. Retain a reasonable region or year fallback with a warning rather than inventing an exact match.

Do not keep a spend item that duplicates a compatible physical activity item. Preserve independent
spend-only products and services.

## Prepare and review

Run `analysis prepare` after selecting candidates. Treat its populated candidates,
`selectedFactor`, compatibility result, status, diagnostics, warnings, amount reconciliation, and
emissions preview as authoritative.

Use `needs_input` when a carbon record lacks a defensible selected factor. Preserve all carbon and
non-carbon records in final `allItems`. A pure non-carbon result may be saved but cannot be
submitted in the first release.

Change only `matches` and rerun prepare when factor selection changes. Return to observation plus
`analysis build` when any business fact changes.

Display a Markdown table containing:

- source and item identity;
- carbon classification;
- activity amount and unit or spend amount and currency;
- period, supplier, and region;
- selected factor ID, name, value, unit, scope, library and release when available;
- confidence, reason, warnings, and alternatives;
- emissions preview.

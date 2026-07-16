# Greentally Emission CSV Contract

## Purpose

Convert locally extracted and reviewed items into the only data payload sent to the Greentally emission import MCP tools. Write it as a local UTF-8 `.csv` artifact when the environment permits. The MCP call receives the artifact's text content; do not attach or encode the original source file.

## Limits

- Maximum CSV size: 10 MiB.
- Maximum data rows: 10,000.
- Encoding: UTF-8; a UTF-8 BOM is accepted.
- Use RFC 4180 quoting when a value contains a comma, quote, or newline.
- The import is atomic: any failed row prevents all rows from being submitted.

## Exact Header

```csv
Item ID,Type,Name,Supplier,Value,Spend Value,Unit,Currency,Start Date,End Date,Region Code,Factor ID,Remarks
```

Do not rename, reorder, add, or remove columns.

## Columns

| Column | Required | Rules |
| --- | --- | --- |
| `Item ID` | yes | Stable, non-empty identifier unique within the organization import stream. Derive it from a source fingerprint plus the source row/page/item, for example `sha256prefix:page-2:item-3`. Reuse it for retries. |
| `Type` | yes | Exactly `activity` or `spend`. |
| `Name` | yes | Concise emissions activity or purchased service name. |
| `Supplier` | no | Supplier text from the source. |
| `Value` | yes | Positive decimal. For `activity`, the physical activity amount. For `spend`, the monetary amount. |
| `Spend Value` | no | Non-negative supporting spend for an `activity` row. Leave empty for a normal `spend` row because `Value` already contains spend. |
| `Unit` | activity | Exact factor `activityUnit` for an activity row, such as `kWh`, `kg`, or `km`. Leave empty for spend unless needed as source evidence. |
| `Currency` | spend | ISO-4217 currency matching the spend factor `activityUnit`, such as `GBP`, `EUR`, or `USD`. |
| `Start Date` | yes | `YYYY-MM-DD` or RFC3339. |
| `End Date` | yes | `YYYY-MM-DD` or RFC3339; not earlier than Start Date. |
| `Region Code` | no | ISO-3166 alpha-3 source geography such as `GBR`, or `GLOBAL` only when appropriate. |
| `Factor ID` | yes | Numeric factor entry ID returned by Greentally MCP during the current task. |
| `Remarks` | no | Short review note, fallback warning, or source evidence summary. |

## Examples

```csv
Item ID,Type,Name,Supplier,Value,Spend Value,Unit,Currency,Start Date,End Date,Region Code,Factor ID,Remarks
9ca1f0c2:page-1:electricity,activity,Grid electricity,Example Energy,1250.4,318.20,kWh,,2026-01-01,2026-01-31,GBR,12345,Metered consumption
9ca1f0c2:line-7:consulting,spend,Environmental consulting,Example Consulting,8000,,,GBP,2026-01-01,2026-01-31,GBR,67890,Net amount before VAT
```

Quote text containing commas:

```csv
9ca1f0c2:line-9:materials,activity,"Steel plate, recycled",Example Metals,2500,,kg,,2026-02-01,2026-02-28,GBR,24680,"Region fallback: Europe"
```

## Validation and Submission

1. Call `validate_emission_import_csv` with the complete CSV text.
2. Require `failedRows` to be empty and `validRows` to equal `totalRows`.
3. Compare returned factor IDs, factor values, emissions, and units with the review table.
4. Show the validation summary and obtain explicit confirmation.
5. Call `submit_emission_import_csv` with the byte-for-byte validated CSV.
6. Treat `inserted: false` rows as idempotent duplicates, not failures.

Never change an Item ID to conceal a duplicate. Use a new Item ID only for a genuinely distinct source item.

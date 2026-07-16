# Greentally MCP Tools

## Connection Contract

- Transport: stateless Streamable HTTP
- Endpoint: `<greentally-service-url>/mcp`
- Authentication header: `Authorization: Bearer sk_...`
- API keys are organization-scoped and cannot authenticate Greentally REST endpoints.
- Every request uses the key owner's current permissions. Viewer roles are read-only; writes require `org.write_data`.
- The MCP server does not receive or recognize original source files. Recognition and extraction happen in the local agent.

Never place the API key in task output, source files, URLs, query parameters, or logs.

Never send original file bytes, base64 content, full OCR output, or unrelated source evidence to an MCP tool.

## Read Tools

### `list_factor_categories`

Input: none.

Use returned `id` and `name` values as the only category catalog. `public` describes visibility and `canManage` describes ownership.

### `list_factor_libraries`

Input: none.

Use library name, publisher, description, visibility, and ownership to choose likely datasets. Do not assume that public means writable.

### `list_factor_releases`

Required input:

- `libraryId`

Optional input:

- `releaseYear`
- `regionCode`
- `publishedOnly`

Use `publishedOnly: true` for normal matching. Retain the release's library, year, and region as candidate provenance.

### `list_factor_entries`

Required input:

- `releaseId`

Optional input:

- `page` (default `1`)
- `size` (default `25`, maximum `100`)
- `categoryId`
- `scope` (`0`, `1`, `2`, or `3`)
- `regionCode`
- `query`
- `publishedOnly`

The result contains `items`, `total`, `page`, and `size`. Entry fields include:

- `id`, `releaseId`, `categoryId`, `categoryName`;
- `name`, `description`, `activityCode`;
- `regionCode`, `activityUnit`, `factorValue`, `unit`, `scope`, `metadata`;
- `canManage`.

`query` searches names, activity codes, and category names. Apply exact unit compatibility yourself after retrieval.

### `get_factor_entry`

Required input:

- `entryId`

Optional input:

- `publishedOnly`

Use this to verify the selected factor or to retrieve the complete current state before an update.

## Emission CSV Tools

### `validate_emission_import_csv`

Required input:

- `csvContent`

This read-only tool validates the exact emission CSV contract, factor visibility, and activity-unit compatibility, then returns server-calculated per-row and total emission previews. It stores nothing. Read [emission-csv-contract.md](emission-csv-contract.md) before calling it.

Require `failedRows` to be empty before requesting submission confirmation.

### `submit_emission_import_csv`

Required input:

- `csvContent`

This tool atomically validates and creates emission source records and raw emission data in the current organization. Call validation first, show the exact summary, and obtain explicit confirmation. Submit the same CSV that was validated.

Stable Item IDs make retries idempotent. Inspect `submitted`, `insertedCount`, `duplicateCount`, `totalEmission`, `unit`, `rows`, and `failedRows`. A duplicate is not a new insertion.

## Factor Catalog Write Tools

### `create_factor_entry`

Required input:

- `releaseId`, `categoryId`, `name`, `activityUnit`, `factorValue`, `unit`, `scope`

Optional input:

- `description`, `metadata`

The release must belong to the current organization. The category must be visible. Do not create a new factor merely because matching returned no result; require an explicit catalog-management request.

### `update_factor_entry`

Required input:

- `entryId`
- the complete entry upsert fields: `releaseId`, `categoryId`, `name`, `activityUnit`, `factorValue`, `unit`, `scope`

Optional input:

- `description`, `metadata`

This replaces editable fields. First call `get_factor_entry`, merge the requested changes into the current complete state, show the proposed result when confirmation is needed, and then update. The entry and target release must belong to the current organization.

### `import_factor_entries_csv`

Required input:

- `libraryId`
- `releaseId`
- `csvContent`

Use this exact header:

```csv
Category,Name,Description,Unit,Factor Unit,Factor Value,Scope
```

Maximum CSV size is 10 MiB and maximum data rows is 10,000. Inspect `totalRows`, `importedCount`, `skippedCount`, and `failedRows`. Do not describe a partial import as fully successful.

## Error Handling

- `VALIDATION`: correct malformed or missing fields; do not retry unchanged input.
- `FORBIDDEN`: stop the attempted write or inaccessible read; explain the organization/role boundary.
- `NOT_FOUND`: refresh the relevant catalog and verify the ID.
- `CONFLICT`: search for the existing factor before proposing another create or update.
- `PAYLOAD_TOO_LARGE`: reduce CSV size or row count without silently dropping data.
- `UNAUTHORIZED`: ask the user to replace or reconfigure the API key.

Do not turn a permission or visibility error into a broader search outside MCP.

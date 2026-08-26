# JSON Toolkit for Business Central

A small AL library for exporting, importing, and patching Microsoft Dynamics 365 Business Central records as JSON. It uses `RecordRef` and `FieldRef`, so callers can work with different tables through one API.

> Experimental: test imports in a sandbox before using them with production data.

## Why this exists

Business Central integrations, migrations, and internal tools often need to move record data as JSON. Writing and maintaining table-specific mapping code for every small use case is repetitive, so this toolkit provides one reusable, table-agnostic API for controlled developer scenarios.

## Features

- Export one record or a filtered record set as JSON.
- Choose flat output or a schema containing table metadata and primary keys.
- Map JSON values into an open `RecordRef`.
- Insert, modify, or upsert records.
- Apply partial updates; omitted fields stay unchanged and `null` clears supported values.
- Assign values directly or run field validation with `FieldRef.Validate`.

The public entry point is codeunit `70770 "Json Toolkit"`. The library source is in [`src/toolkit`](src/toolkit/), and its automated tests are in [`src/test`](src/test/).

## Requirements and installation

- Business Central application `27.0.0.0` or later
- AL runtime `16.0` or later

Clone the repository and open [`src/bc-json-recordref.code-workspace`](src/bc-json-recordref.code-workspace) in Visual Studio Code with the AL Language extension. The workspace loads the toolkit and test projects together. Download symbols, then build and publish the toolkit app to a Business Central sandbox.

## Project structure

```text
src/
├── bc-json-recordref.code-workspace
├── toolkit/
│   ├── app.json
│   ├── codeunit/
│   ├── enum/
│   └── interface/
└── test/
    ├── app.json
    ├── codeunit/
    └── table/
```

- `src/toolkit` contains the publishable library extension, organized by AL object type.
- `src/test` contains the test extension, test codeunits, and the supporting test table. Its manifest declares a dependency on the toolkit app.
- `src/bc-json-recordref.code-workspace` opens both AL projects in one VS Code workspace.

To run the automated tests, build and publish `src/toolkit` first, then build and publish `src/test`. Run the `Json Toolkit General Tests` and `Json Toolkit Schema Tests` codeunits with your Business Central test runner.

## Usage

Export a record with schema metadata:

```al
procedure ExportCustomer(Customer: Record Customer): Text
var
    JsonToolkit: Codeunit "Json Toolkit";
    RecRef: RecordRef;
    Output: Text;
begin
    RecRef.GetTable(Customer);
    if JsonToolkit.RecordRefToJson(RecRef, Output, true) then
        exit(Output);

    exit('');
end;
```

Insert or update a record, running table validation:

```al
procedure ImportCustomer(Payload: JsonObject): Boolean
var
    JsonToolkit: Codeunit "Json Toolkit";
begin
    exit(JsonToolkit.CopyJsonToTable(
        Payload,
        Database::Customer,
        "Json Toolkit Table Action"::InsertOrModify,
        "Json Toolkit Update Mode"::Validate));
end;
```

The facade also provides:

- `RecordRefSetToJson` for filtered record sets
- `JsonToRecordRef` for mapping without inserting or modifying
- `ApplyPatch` for partial updates
- `CopyJsonToTable` overloads for `JsonObject` and `JsonArray`

## JSON format

With `UseSchema = true`:

```json
{
  "__meta": {
    "tableId": 18,
    "tableName": "Customer",
    "company": "CRONUS",
    "schema": "bc-recordref/1.0"
  },
  "__key": {
    "pk": {
      "No.": "10000"
    }
  },
  "fields": {
    "No.": "10000",
    "Name": "Adatum Corporation"
  }
}
```

With `UseSchema = false`, the output contains only field names and values:

```json
{
  "No.": "10000",
  "Name": "Adatum Corporation"
}
```

A patch uses the primary key to find a record and changes only properties under `patch`:

```json
{
  "__meta": { "tableId": 18 },
  "__key": { "pk": { "No.": "10000" } },
  "patch": {
    "Name": "Updated customer name",
    "Phone No.": null
  }
}
```

## Safety and limitations

This is a developer library, not an end-user import wizard. External payloads can select tables and fields dynamically, so callers should allow-list target tables and fields, validate payloads, and prefer `Validate` mode when Business Central field logic must run.

Current limitations:

- Error reporting is limited to Boolean success/failure results.
- Fields are matched by name; unknown properties are ignored.
- Nested objects and arrays cannot be imported as field values.
- `Blob`, `Media`, `MediaSet`, and unsupported field classes are skipped.
- Dates, times, datetimes, and decimals are exported as formatted text.
- Array imports have no batching or partial-success report.

## License

Licensed under the [MIT License](LICENSE).

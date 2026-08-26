codeunit 70773 "Json Toolkit Schema Tests"
{
    Subtype = Test;

    [Test]
    procedure T01_SchemaExportContainsMetadataKeyAndFields()
    var
        FieldsObj: JsonObject;
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonToolkit: Codeunit "Json Toolkit";
        KeyObj: JsonObject;
        MetaObj: JsonObject;
        PrimaryKeyObj: JsonObject;
        RecRef: RecordRef;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-SCHEMA-1', 'Schema record', 34.75, true);
        TestRecord.Get('JT-SCHEMA-1');
        RecRef.GetTable(TestRecord);

        // When
        if not JsonToolkit.RecordRefToJson(RecRef, JsonObj, true) then
            Error('The schema record export failed.');

        // Then
        if not JsonObj.Get('__meta', JsonToken) then
            Error('The schema export does not contain metadata.');
        MetaObj := JsonToken.AsObject();
        if not MetaObj.Get('tableId', JsonToken) then
            Error('The schema metadata does not contain a table ID.');
        if JsonToken.AsValue().AsInteger() <> Database::"Json Toolkit Test Record" then
            Error('The schema metadata contains an unexpected table ID.');
        if not MetaObj.Contains('schema') or not MetaObj.Contains('capturedAt') then
            Error('The schema metadata is incomplete.');

        if not JsonObj.Get('__key', JsonToken) then
            Error('The schema export does not contain a key section.');
        KeyObj := JsonToken.AsObject();
        if not KeyObj.Get('pk', JsonToken) then
            Error('The schema key section does not contain the primary key.');
        PrimaryKeyObj := JsonToken.AsObject();
        if not PrimaryKeyObj.Get('Code', JsonToken) or (JsonToken.AsValue().AsText() <> 'JT-SCHEMA-1') then
            Error('The schema primary key is incorrect.');

        if not JsonObj.Get('fields', JsonToken) then
            Error('The schema export does not contain fields.');
        FieldsObj := JsonToken.AsObject();
        if not FieldsObj.Contains('Description') or not FieldsObj.Contains('Amount') or not FieldsObj.Contains('Active') then
            Error('The schema fields section is incomplete.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T02_SchemaRoundTripPreservesAllFieldValues()
    var
        JsonObj: JsonObject;
        JsonToolkit: Codeunit "Json Toolkit";
        SourceRecRef: RecordRef;
        SourceRecord: Record "Json Toolkit Test Record";
        TargetFieldRef: FieldRef;
        TargetRecRef: RecordRef;
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-SCHEMA-2', 'Round trip record', 34.75, true);
        SourceRecord.Get('JT-SCHEMA-2');
        SourceRecRef.GetTable(SourceRecord);
        if not JsonToolkit.RecordRefToJson(SourceRecRef, JsonObj, true) then
            Error('The schema record export failed.');
        TargetRecRef.Open(Database::"Json Toolkit Test Record", true);

        // When
        if not JsonToolkit.JsonToRecordRef(JsonObj, TargetRecRef, "Json Toolkit Update Mode"::Validate) then
            Error('The schema import failed.');

        // Then
        TargetFieldRef := TargetRecRef.Field(1);
        if Format(TargetFieldRef.Value) <> 'JT-SCHEMA-2' then
            Error('The imported primary key differs from the exported value.');
        TargetFieldRef := TargetRecRef.Field(2);
        if Format(TargetFieldRef.Value) <> 'Round trip record' then
            Error('The imported description differs from the exported value.');
        TargetFieldRef := TargetRecRef.Field(3);
        if Format(TargetFieldRef.Value, 0, 9) <> '34.75' then
            Error('The imported amount differs from the exported value.');
        TargetFieldRef := TargetRecRef.Field(4);
        if not TargetFieldRef.Value then
            Error('The imported Boolean differs from the exported value.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T03_SchemaPatchResolvesKeyAndClearsNullField()
    var
        JsonObj: JsonObject;
        JsonToolkit: Codeunit "Json Toolkit";
        KeyObj: JsonObject;
        PatchObj: JsonObject;
        PrimaryKeyObj: JsonObject;
        NullValue: JsonValue;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-SCHEMA-3', 'Original description', 12, true);
        PrimaryKeyObj.Add('Code', 'JT-SCHEMA-3');
        KeyObj.Add('pk', PrimaryKeyObj);
        PatchObj.Add('Description', 'Updated description');
        NullValue.SetValueToNull();
        PatchObj.Add('Amount', NullValue);
        JsonObj.Add('__key', KeyObj);
        JsonObj.Add('patch', PatchObj);

        // When
        if not JsonToolkit.CopyJsonToTable(JsonObj, Database::"Json Toolkit Test Record", "Json Toolkit Table Action"::ModifyOnly) then
            Error('The schema patch copy operation failed.');

        // Then
        TestRecord.Get('JT-SCHEMA-3');
        if (TestRecord.Description <> 'Updated description') or (TestRecord.Amount <> 0) or (not TestRecord.Active) then
            Error('The schema patch did not update and clear the expected fields.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T04_SchemaImportUsesMetadataToOpenRecordReference()
    var
        FieldsObj: JsonObject;
        JsonObj: JsonObject;
        JsonToolkit: Codeunit "Json Toolkit";
        MetaObj: JsonObject;
        RecRef: RecordRef;
        TargetFieldRef: FieldRef;
    begin
        // Given
        MetaObj.Add('tableId', Database::"Json Toolkit Test Record");
        FieldsObj.Add('Code', 'JT-SCHEMA-4');
        FieldsObj.Add('Description', 'Metadata-directed import');
        FieldsObj.Add('Amount', 99.5);
        FieldsObj.Add('Active', false);
        JsonObj.Add('__meta', MetaObj);
        JsonObj.Add('fields', FieldsObj);

        // When
        if not JsonToolkit.JsonToRecordRef(JsonObj, RecRef) then
            Error('The metadata-directed schema import failed.');

        // Then
        if RecRef.Number <> Database::"Json Toolkit Test Record" then
            Error('The schema metadata did not open the expected table.');
        TargetFieldRef := RecRef.Field(2);
        if Format(TargetFieldRef.Value) <> 'Metadata-directed import' then
            Error('The metadata-directed import did not populate fields.');
    end;

    local procedure CreateTestRecord(RecordCode: Code[20]; RecordDescription: Text[100]; RecordAmount: Decimal; RecordActive: Boolean)
    var
        TestRecord: Record "Json Toolkit Test Record";
    begin
        TestRecord.Init();
        TestRecord."Code" := RecordCode;
        TestRecord.Description := RecordDescription;
        TestRecord.Amount := RecordAmount;
        TestRecord.Active := RecordActive;
        TestRecord.Insert(false);
    end;

    local procedure CleanupTestRecords()
    var
        TestRecord: Record "Json Toolkit Test Record";
    begin
        TestRecord.SetFilter("Code", 'JT-*');
        TestRecord.DeleteAll(false);
    end;
}
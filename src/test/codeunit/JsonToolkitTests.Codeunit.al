codeunit 70772 "Json Toolkit General Tests"
{
    Subtype = Test;

    [Test]
    procedure T01_RecordRefToJsonExportsFlatRecordAndText()
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonToolkit: Codeunit "Json Toolkit";
        OutputText: Text;
        RecRef: RecordRef;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-EXPORT', 'Exported record', 12.5, true);
        TestRecord.Get('JT-EXPORT');
        RecRef.GetTable(TestRecord);

        // When
        if not JsonToolkit.RecordRefToJson(RecRef, JsonObj, false) then
            Error('The flat record export failed.');

        // Then
        if not JsonObj.Get('Code', JsonToken) then
            Error('The flat export does not contain the primary key.');
        if JsonToken.AsValue().AsText() <> 'JT-EXPORT' then
            Error('The flat export contains an unexpected primary key.');

        // When
        if not JsonToolkit.RecordRefToJson(RecRef, OutputText, false) then
            Error('The text record export failed.');

        // Then
        if not JsonObj.ReadFrom(OutputText) then
            Error('The exported text is not a JSON object.');
        if not JsonObj.Contains('Description') then
            Error('The text export does not contain record fields.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T02_RecordRefSetToJsonExportsAllFilteredRecords()
    var
        JsonArray: JsonArray;
        JsonToolkit: Codeunit "Json Toolkit";
        OutputText: Text;
        RecRef: RecordRef;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-SET-1', 'First record', 1, true);
        CreateTestRecord('JT-SET-2', 'Second record', 2, false);
        TestRecord.SetFilter("Code", 'JT-SET-*');
        RecRef.GetTable(TestRecord);

        // When
        if not JsonToolkit.RecordRefSetToJson(RecRef, JsonArray, true) then
            Error('The record set export failed.');

        // Then
        if JsonArray.Count() <> 2 then
            Error('The record set export contains an unexpected number of records.');

        // When
        if not JsonToolkit.RecordRefSetToJson(RecRef, OutputText, false) then
            Error('The text record set export failed.');

        // Then
        if not JsonArray.ReadFrom(OutputText) then
            Error('The exported text is not a JSON array.');
        if JsonArray.Count() <> 2 then
            Error('The text record set export contains an unexpected number of records.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T03_ApplyPatchUpdatesOnlyProvidedFields()
    var
        JsonObj: JsonObject;
        JsonToolkit: Codeunit "Json Toolkit";
        KeyObj: JsonObject;
        PatchObj: JsonObject;
        PrimaryKeyObj: JsonObject;
        RecRef: RecordRef;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateTestRecord('JT-PATCH', 'Original description', 8, true);
        PrimaryKeyObj.Add('Code', 'JT-PATCH');
        KeyObj.Add('pk', PrimaryKeyObj);
        PatchObj.Add('Description', 'Patched description');
        JsonObj.Add('__key', KeyObj);
        JsonObj.Add('patch', PatchObj);
        RecRef.Open(Database::"Json Toolkit Test Record");

        // When
        if not JsonToolkit.ApplyPatch(JsonObj, RecRef) then
            Error('The patch operation failed.');
        if not RecRef.Modify(false) then
            Error('The patched record could not be saved.');

        // Then
        TestRecord.Get('JT-PATCH');
        if (TestRecord.Description <> 'Patched description') or (TestRecord.Amount <> 8) or (not TestRecord.Active) then
            Error('The patch changed fields that were not provided.');

        CleanupTestRecords();
    end;

    [Test]
    procedure T04_CopyJsonToTableSupportsInsertModifyAndArray()
    var
        FirstJsonObj: JsonObject;
        JsonArray: JsonArray;
        JsonToolkit: Codeunit "Json Toolkit";
        SecondJsonObj: JsonObject;
        TestRecord: Record "Json Toolkit Test Record";
    begin
        // Given
        CleanupTestRecords();
        CreateJsonRecord('JT-COPY-1', 'Initial description', 10, true, FirstJsonObj);

        // When
        if not JsonToolkit.CopyJsonToTable(FirstJsonObj, Database::"Json Toolkit Test Record", "Json Toolkit Table Action"::InsertOnly) then
            Error('The insert-only copy operation failed.');

        // Then
        if JsonToolkit.CopyJsonToTable(FirstJsonObj, Database::"Json Toolkit Test Record", "Json Toolkit Table Action"::InsertOnly) then
            Error('The insert-only copy operation allowed a duplicate record.');

        // Given
        CreateJsonRecord('JT-COPY-1', 'Modified description', 15, false, FirstJsonObj);

        // When
        if not JsonToolkit.CopyJsonToTable(FirstJsonObj, Database::"Json Toolkit Test Record", "Json Toolkit Table Action"::ModifyOnly) then
            Error('The modify-only copy operation failed.');

        // Then
        TestRecord.Get('JT-COPY-1');
        if (TestRecord.Description <> 'Modified description') or (TestRecord.Amount <> 15) or TestRecord.Active then
            Error('The modify-only copy operation did not apply the JSON values.');

        // Given
        CreateJsonRecord('JT-COPY-2', 'Second copied record', 20, true, SecondJsonObj);
        JsonArray.Add(SecondJsonObj);

        // When
        if not JsonToolkit.CopyJsonToTable(JsonArray, Database::"Json Toolkit Test Record", "Json Toolkit Table Action"::InsertOrModify) then
            Error('The JSON array copy operation failed.');

        // Then
        if not TestRecord.Get('JT-COPY-2') then
            Error('The JSON array copy operation did not insert its record.');

        CleanupTestRecords();
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

    local procedure CreateJsonRecord(RecordCode: Code[20]; RecordDescription: Text[100]; RecordAmount: Decimal; RecordActive: Boolean; var JsonObj: JsonObject)
    begin
        Clear(JsonObj);
        JsonObj.Add('Code', RecordCode);
        JsonObj.Add('Description', RecordDescription);
        JsonObj.Add('Amount', RecordAmount);
        JsonObj.Add('Active', RecordActive);
    end;

    local procedure CleanupTestRecords()
    var
        TestRecord: Record "Json Toolkit Test Record";
    begin
        TestRecord.SetFilter("Code", 'JT-*');
        TestRecord.DeleteAll(false);
    end;
}
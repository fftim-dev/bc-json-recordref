codeunit 70771 "Json Toolkit Impl." implements "Json Toolkit"
{
    Access = Internal;

    procedure RecordRefToJson(RecRef: RecordRef; var JsonObj: JsonObject; UseSchema: Boolean): Boolean
    begin
        if RecRef.IsEmpty() then
            exit(false);

        Clear(JsonObj);

        if UseSchema then
            JsonObj := BuildRecordObject(RecRef)
        else
            JsonObj := BuildFieldsObject(RecRef);

        exit(true);
    end;

    procedure RecordRefToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean
    var
        JsonObj: JsonObject;
    begin
        if not RecordRefToJson(RecRef, JsonObj, UseSchema) then
            exit(false);

        Clear(OutputText);
        exit(JsonObj.WriteTo(OutputText));
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var JsonArray: JsonArray; UseSchema: Boolean): Boolean
    begin
        if RecRef.IsEmpty() then
            exit(false);

        Clear(JsonArray);
        JsonArray := BuildArray(RecRef, UseSchema);

        exit(true);
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean
    var
        JsonArray: JsonArray;
    begin
        if not RecordRefSetToJson(RecRef, JsonArray, UseSchema) then
            exit(false);

        Clear(OutputText);
        exit(JsonArray.WriteTo(OutputText));
    end;

    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef): Boolean
    begin
        exit(JsonToRecordRef(JsonObj, RecRef, "Json Toolkit Update Mode"::Assign));
    end;

    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        FieldsObj: JsonObject;
        HasFields: Boolean;
    begin
        if not EnsureRecordRefOpen(JsonObj, RecRef, 0) then
            exit(false);

        HasFields := TryGetObjectSection(JsonObj, 'fields', FieldsObj);
        if not HasFields then begin
            if IsToolkitSchemaObject(JsonObj) then
                exit(ResolveRecordByKey(JsonObj, RecRef));

            FieldsObj := JsonObj;
            HasFields := true;
        end;

        if HasFields then begin
            RecRef.Init();
            exit(ApplyFieldsObject(FieldsObj, RecRef, UpdateMode));
        end;

        exit(false);
    end;

    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef): Boolean
    begin
        exit(ApplyPatch(JsonObj, RecRef, "Json Toolkit Update Mode"::Assign));
    end;

    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        PatchObj: JsonObject;
    begin
        if not EnsureRecordRefOpen(JsonObj, RecRef, 0) then
            exit(false);

        if HasKeyObject(JsonObj) then
            if not ResolveRecordByKey(JsonObj, RecRef) then
                exit(false);

        if not TryGetObjectSection(JsonObj, 'patch', PatchObj) then
            if not TryGetObjectSection(JsonObj, 'fields', PatchObj) then
                PatchObj := JsonObj;

        exit(ApplyFieldsObject(PatchObj, RecRef, UpdateMode));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean
    begin
        exit(CopyJsonToTable(JsonObj, TableNo, TableAction, "Json Toolkit Update Mode"::Assign));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        exit(CopyJsonToTable(JsonObj, RecRef, TableAction, UpdateMode));
    end;

    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean
    begin
        exit(CopyJsonToTable(JsonArray, TableNo, TableAction, "Json Toolkit Update Mode"::Assign));
    end;

    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        JsonToken: JsonToken;
        JsonObj: JsonObject;
        Index: Integer;
    begin
        for Index := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(Index, JsonToken);
            if not JsonToken.IsObject() then
                exit(false);

            JsonObj := JsonToken.AsObject();
            if not CopyJsonToTable(JsonObj, TableNo, TableAction, UpdateMode) then
                exit(false);
        end;

        exit(true);
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; RecRef: RecordRef; TableAction: Enum "Json Toolkit Table Action"): Boolean
    begin
        exit(CopyJsonToTable(JsonObj, RecRef, TableAction, "Json Toolkit Update Mode"::Assign));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; RecRef: RecordRef; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        ExistingRecRef: RecordRef;
        SourceRecRef: RecordRef;
        TableNo: Integer;
        Exists: Boolean;
        IsPatch: Boolean;
    begin
        TableNo := RecRef.Number;
        if not EnsureRecordRefOpen(JsonObj, RecRef, TableNo) then
            exit(false);

        TableNo := RecRef.Number;
        IsPatch := HasObjectSection(JsonObj, 'patch');

        ExistingRecRef.Open(TableNo);
        Exists := ResolveRecordByKey(JsonObj, ExistingRecRef);

        if IsPatch then begin
            if TableAction = "Json Toolkit Table Action"::InsertOnly then
                exit(false);
            if not Exists then
                exit(false);

            if not ApplyPatch(JsonObj, ExistingRecRef, UpdateMode) then
                exit(false);

            exit(ExistingRecRef.Modify(false));
        end;

        if IsToolkitSchemaObject(JsonObj) and (not HasObjectSection(JsonObj, 'fields')) then
            exit(false);

        SourceRecRef.Open(TableNo);
        SourceRecRef.Init();
        if not ApplyFieldsFromJson(JsonObj, SourceRecRef, UpdateMode) then
            exit(false);

        if not Exists then begin
            ExistingRecRef.Close();
            ExistingRecRef.Open(TableNo);
            Exists := ResolveRecordByCurrentPrimaryKey(SourceRecRef, ExistingRecRef);
        end;

        case TableAction of
            "Json Toolkit Table Action"::InsertOnly:
                begin
                    if Exists then
                        exit(false);
                    exit(SourceRecRef.Insert(false));
                end;
            "Json Toolkit Table Action"::ModifyOnly:
                begin
                    if not Exists then
                        exit(false);
                    if not ApplyFieldsFromJson(JsonObj, ExistingRecRef, UpdateMode) then
                        exit(false);
                    exit(ExistingRecRef.Modify(false));
                end;
            "Json Toolkit Table Action"::InsertOrModify:
                begin
                    if Exists then begin
                        if not ApplyFieldsFromJson(JsonObj, ExistingRecRef, UpdateMode) then
                            exit(false);
                        exit(ExistingRecRef.Modify(false));
                    end;

                    exit(SourceRecRef.Insert(false));
                end;
        end;

        exit(false);
    end;

    local procedure BuildArray(RecRef: RecordRef; UseSchema: Boolean) ResultArray: JsonArray
    begin
        if RecRef.FindSet() then
            repeat
                if UseSchema then
                    ResultArray.Add(BuildRecordObject(RecRef))
                else
                    ResultArray.Add(BuildFieldsObject(RecRef));
            until RecRef.Next() = 0;
    end;

    local procedure BuildRecordObject(RecRef: RecordRef) ResultObj: JsonObject
    begin
        ResultObj.Add('__meta', BuildMetadataObject(RecRef));
        ResultObj.Add('__key', BuildKeyObject(RecRef));
        ResultObj.Add('fields', BuildFieldsObject(RecRef));
    end;

    local procedure BuildMetadataObject(RecRef: RecordRef) MetaObj: JsonObject
    begin
        MetaObj.Add('tableId', RecRef.Number);
        MetaObj.Add('tableName', Format(RecRef.Caption()));
        MetaObj.Add('company', CompanyName);
        MetaObj.Add('schema', 'bc-recordref/1.0');
        MetaObj.Add('capturedAt', Format(CurrentDateTime(), 0, 9));
    end;

    local procedure BuildKeyObject(RecRef: RecordRef) KeyObj: JsonObject
    begin
        KeyObj.Add('pk', BuildPrimaryKeyObject(RecRef));
    end;

    local procedure BuildPrimaryKeyObject(RecRef: RecordRef) PrimaryKeyObj: JsonObject
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        Index: Integer;
    begin
        KeyRef := RecRef.KeyIndex(1);

        for Index := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(Index);
            AddFieldValue(PrimaryKeyObj, FieldRef);
        end;
    end;

    local procedure BuildFieldsObject(RecRef: RecordRef) FieldsObj: JsonObject
    var
        FieldRef: FieldRef;
        Index: Integer;
    begin
        for Index := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(Index);
            if IsSerializableField(FieldRef) then
                AddFieldValue(FieldsObj, FieldRef);
        end;
    end;

    local procedure AddFieldValue(var JsonObj: JsonObject; FieldRef: FieldRef)
    var
        BigIntegerValue: BigInteger;
        BooleanValue: Boolean;
        DateTimeValue: DateTime;
        DateValue: Date;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        TextValue: Text;
        TimeValue: Time;
    begin
        case FieldRef.Type of
            FieldType::Integer:
                begin
                    IntegerValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, IntegerValue);
                end;
            FieldType::BigInteger:
                begin
                    BigIntegerValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, BigIntegerValue);
                end;
            FieldType::Boolean:
                begin
                    BooleanValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, BooleanValue);
                end;
            FieldType::Decimal:
                begin
                    DecimalValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, Format(DecimalValue, 0, 9));
                end;
            FieldType::Date:
                begin
                    DateValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, Format(DateValue, 0, 9));
                end;
            FieldType::Time:
                begin
                    TimeValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, Format(TimeValue, 0, 9));
                end;
            FieldType::DateTime:
                begin
                    DateTimeValue := FieldRef.Value;
                    JsonObj.Add(FieldRef.Name, Format(DateTimeValue, 0, 9));
                end;
            else begin
                TextValue := Format(FieldRef.Value);
                JsonObj.Add(FieldRef.Name, TextValue);
            end;
        end;
    end;

    local procedure ApplyFieldsFromJson(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        FieldsObj: JsonObject;
    begin
        if TryGetObjectSection(JsonObj, 'fields', FieldsObj) then
            exit(ApplyFieldsObject(FieldsObj, RecRef, UpdateMode));

        exit(ApplyFieldsObject(JsonObj, RecRef, UpdateMode));
    end;

    local procedure ApplyFieldsObject(FieldsObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        FieldRef: FieldRef;
        FieldNames: List of [Text];
        FieldName: Text;
        JsonToken: JsonToken;
    begin
        FieldNames := FieldsObj.Keys();

        foreach FieldName in FieldNames do
            if not IsToolkitSectionName(FieldName) then
                if TryGetFieldRefByName(RecRef, FieldName, FieldRef) then
                    if IsWritableField(FieldRef) then begin
                        FieldsObj.Get(FieldName, JsonToken);
                        if not SetFieldValueFromToken(FieldRef, JsonToken, UpdateMode) then
                            exit(false);
                    end;

        exit(true);
    end;

    local procedure SetFieldValueFromToken(var FieldRef: FieldRef; JsonToken: JsonToken; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        BigIntegerValue: BigInteger;
        BooleanValue: Boolean;
        DateTimeValue: DateTime;
        DateValue: Date;
        DecimalValue: Decimal;
        GuidValue: Guid;
        IntegerValue: Integer;
        TextValue: Text;
        TimeValue: Time;
    begin
        if not JsonToken.IsValue() then
            exit(false);

        if IsNullToken(JsonToken) then begin
            ClearFieldValue(FieldRef, UpdateMode);
            exit(true);
        end;

        TextValue := GetJsonValueText(JsonToken);

        case FieldRef.Type of
            FieldType::Integer:
                begin
                    if not Evaluate(IntegerValue, TextValue, 9) then
                        exit(false);
                    AssignFieldValue(FieldRef, IntegerValue, UpdateMode);
                end;
            FieldType::BigInteger:
                begin
                    if not Evaluate(BigIntegerValue, TextValue, 9) then
                        exit(false);
                    AssignFieldValue(FieldRef, BigIntegerValue, UpdateMode);
                end;
            FieldType::Boolean:
                begin
                    if not EvaluateBoolean(TextValue, BooleanValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, BooleanValue, UpdateMode);
                end;
            FieldType::Decimal:
                begin
                    if not Evaluate(DecimalValue, TextValue, 9) then
                        exit(false);
                    AssignFieldValue(FieldRef, DecimalValue, UpdateMode);
                end;
            FieldType::Date:
                begin
                    if not EvaluateDate(TextValue, DateValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, DateValue, UpdateMode);
                end;
            FieldType::Time:
                begin
                    if not EvaluateTime(TextValue, TimeValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, TimeValue, UpdateMode);
                end;
            FieldType::DateTime:
                begin
                    if not EvaluateDateTime(TextValue, DateTimeValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, DateTimeValue, UpdateMode);
                end;
            FieldType::Option:
                begin
                    if not EvaluateOption(FieldRef, TextValue, IntegerValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, IntegerValue, UpdateMode);
                end;
            FieldType::Guid:
                begin
                    if not Evaluate(GuidValue, TextValue) then
                        exit(false);
                    AssignFieldValue(FieldRef, GuidValue, UpdateMode);
                end;
            else
                AssignFieldValue(FieldRef, TextValue, UpdateMode);
        end;

        exit(true);
    end;

    local procedure ClearFieldValue(var FieldRef: FieldRef; UpdateMode: Enum "Json Toolkit Update Mode")
    begin
        case FieldRef.Type of
            FieldType::Integer:
                AssignFieldValue(FieldRef, 0, UpdateMode);
            FieldType::BigInteger:
                AssignFieldValue(FieldRef, 0, UpdateMode);
            FieldType::Boolean:
                AssignFieldValue(FieldRef, false, UpdateMode);
            FieldType::Decimal:
                AssignFieldValue(FieldRef, 0, UpdateMode);
            FieldType::Date:
                AssignFieldValue(FieldRef, 0D, UpdateMode);
            FieldType::Time:
                AssignFieldValue(FieldRef, 0T, UpdateMode);
            FieldType::DateTime:
                AssignFieldValue(FieldRef, 0DT, UpdateMode);
            FieldType::Option:
                AssignFieldValue(FieldRef, 0, UpdateMode);
            else
                AssignFieldValue(FieldRef, '', UpdateMode);
        end;
    end;

    local procedure AssignFieldValue(var FieldRef: FieldRef; Value: Variant; UpdateMode: Enum "Json Toolkit Update Mode")
    begin
        if UpdateMode = "Json Toolkit Update Mode"::Validate then
            FieldRef.Validate(Value)
        else
            FieldRef.Value := Value;
    end;

    local procedure ResolveRecordByKey(JsonObj: JsonObject; var RecRef: RecordRef): Boolean
    var
        KeyObj: JsonObject;
    begin
        if not TryGetKeyFieldsObject(JsonObj, KeyObj) then
            exit(false);

        RecRef.Reset();
        RecRef.Init();
        if not ApplyFieldsObject(KeyObj, RecRef, "Json Toolkit Update Mode"::Assign) then
            exit(false);

        RecRef.SetRecFilter();
        if RecRef.FindFirst() then
            exit(true);

        RecRef.Reset();
        exit(false);
    end;

    local procedure ResolveRecordByCurrentPrimaryKey(SourceRecRef: RecordRef; var TargetRecRef: RecordRef): Boolean
    var
        KeyFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        KeyRef: KeyRef;
        Index: Integer;
    begin
        TargetRecRef.Reset();
        TargetRecRef.Init();
        KeyRef := SourceRecRef.KeyIndex(1);

        for Index := 1 to KeyRef.FieldCount do begin
            KeyFieldRef := KeyRef.FieldIndex(Index);
            TargetFieldRef := TargetRecRef.Field(KeyFieldRef.Number);
            TargetFieldRef.Value := KeyFieldRef.Value;
        end;

        TargetRecRef.SetRecFilter();
        if TargetRecRef.FindFirst() then
            exit(true);

        TargetRecRef.Reset();
        exit(false);
    end;

    local procedure EnsureRecordRefOpen(JsonObj: JsonObject; var RecRef: RecordRef; FallbackTableNo: Integer): Boolean
    var
        TableNo: Integer;
    begin
        TableNo := FallbackTableNo;
        if TableNo = 0 then
            TryGetTableNo(JsonObj, TableNo);

        if TableNo = 0 then
            exit(RecRef.Number <> 0);

        if RecRef.Number = TableNo then
            exit(true);

        if RecRef.Number <> 0 then
            RecRef.Close();

        RecRef.Open(TableNo);
        exit(true);
    end;

    local procedure TryGetTableNo(JsonObj: JsonObject; var TableNo: Integer): Boolean
    var
        MetaObj: JsonObject;
        TableToken: JsonToken;
    begin
        if TryGetObjectSection(JsonObj, '__meta', MetaObj) then
            if MetaObj.Get('tableId', TableToken) then
                exit(Evaluate(TableNo, GetJsonValueText(TableToken), 9));

        if TryGetObjectSection(JsonObj, 'meta', MetaObj) then
            if MetaObj.Get('tableId', TableToken) then
                exit(Evaluate(TableNo, GetJsonValueText(TableToken), 9));

        exit(false);
    end;

    local procedure TryGetObjectSection(JsonObj: JsonObject; SectionName: Text; var SectionObj: JsonObject): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(SectionName, JsonToken) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);

        SectionObj := JsonToken.AsObject();
        exit(true);
    end;

    local procedure HasObjectSection(JsonObj: JsonObject; SectionName: Text): Boolean
    var
        SectionObj: JsonObject;
    begin
        exit(TryGetObjectSection(JsonObj, SectionName, SectionObj));
    end;

    local procedure HasKeyObject(JsonObj: JsonObject): Boolean
    var
        KeyObj: JsonObject;
    begin
        exit(TryGetKeyFieldsObject(JsonObj, KeyObj));
    end;

    local procedure TryGetKeyFieldsObject(JsonObj: JsonObject; var KeyFieldsObj: JsonObject): Boolean
    var
        KeyObj: JsonObject;
    begin
        if not TryGetObjectSection(JsonObj, '__key', KeyObj) then
            exit(false);

        if TryGetObjectSection(KeyObj, 'pk', KeyFieldsObj) then
            exit(true);

        KeyFieldsObj := KeyObj;
        exit(true);
    end;

    local procedure TryGetFieldRefByName(var RecRef: RecordRef; FieldName: Text; var FieldRef: FieldRef): Boolean
    var
        Index: Integer;
    begin
        for Index := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(Index);
            if FieldRef.Name = FieldName then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetJsonValueText(JsonToken: JsonToken): Text
    var
        JsonValue: JsonValue;
    begin
        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            exit('');

        exit(JsonValue.AsText());
    end;

    local procedure IsNullToken(JsonToken: JsonToken): Boolean
    var
        JsonValue: JsonValue;
    begin
        if not JsonToken.IsValue() then
            exit(false);

        JsonValue := JsonToken.AsValue();
        exit(JsonValue.IsNull());
    end;

    local procedure IsToolkitSchemaObject(JsonObj: JsonObject): Boolean
    begin
        exit(HasObjectSection(JsonObj, '__meta') or HasObjectSection(JsonObj, '__key'));
    end;

    local procedure IsToolkitSectionName(FieldName: Text): Boolean
    begin
        exit((FieldName = '__meta') or (FieldName = '__key') or (FieldName = 'fields') or (FieldName = 'patch') or (FieldName = 'meta') or (FieldName = 'records'));
    end;

    local procedure IsSerializableField(FieldRef: FieldRef): Boolean
    begin
        if FieldRef.Class = FieldClass::FlowFilter then
            exit(false);

        case FieldRef.Type of
            FieldType::Blob,
            FieldType::Media,
            FieldType::MediaSet:
                exit(false);
        end;

        exit(true);
    end;

    local procedure IsWritableField(FieldRef: FieldRef): Boolean
    begin
        if FieldRef.Class <> FieldClass::Normal then
            exit(false);

        case FieldRef.Type of
            FieldType::Blob,
            FieldType::Media,
            FieldType::MediaSet:
                exit(false);
        end;

        exit(true);
    end;

    local procedure EvaluateBoolean(ValueText: Text; var BooleanValue: Boolean): Boolean
    begin
        case LowerCase(ValueText) of
            'true', 'yes':
                begin
                    BooleanValue := true;
                    exit(true);
                end;
            'false', 'no':
                begin
                    BooleanValue := false;
                    exit(true);
                end;
        end;

        exit(Evaluate(BooleanValue, ValueText));
    end;

    local procedure EvaluateDate(ValueText: Text; var DateValue: Date): Boolean
    begin
        if ValueText = '' then begin
            Clear(DateValue);
            exit(true);
        end;
        if Evaluate(DateValue, ValueText, 9) then
            exit(true);
        exit(Evaluate(DateValue, ValueText));
    end;

    local procedure EvaluateTime(ValueText: Text; var TimeValue: Time): Boolean
    begin
        if ValueText = '' then begin
            Clear(TimeValue);
            exit(true);
        end;
        if Evaluate(TimeValue, ValueText, 9) then
            exit(true);
        exit(Evaluate(TimeValue, ValueText));
    end;

    local procedure EvaluateDateTime(ValueText: Text; var DateTimeValue: DateTime): Boolean
    begin
        if ValueText = '' then begin
            Clear(DateTimeValue);
            exit(true);
        end;
        if Evaluate(DateTimeValue, ValueText, 9) then
            exit(true);
        exit(Evaluate(DateTimeValue, ValueText));
    end;

    local procedure EvaluateOption(FieldRef: FieldRef; ValueText: Text; var OptionValue: Integer): Boolean
    begin
        if Evaluate(OptionValue, ValueText, 9) then
            exit(OptionValue >= 0);

        if EvaluateOptionText(FieldRef.OptionMembers, ValueText, OptionValue) then
            exit(true);

        exit(EvaluateOptionText(FieldRef.OptionCaption, ValueText, OptionValue));
    end;

    local procedure EvaluateOptionText(OptionValues: Text; ValueText: Text; var OptionValue: Integer): Boolean
    var
        OptionText: Text;
        OptionIndex: Integer;
    begin
        OptionIndex := 0;
        while OptionValues <> '' do begin
            OptionText := PopCommaSeparatedValue(OptionValues);
            if IsSameOptionText(OptionText, ValueText) then begin
                OptionValue := OptionIndex;
                exit(true);
            end;

            OptionIndex += 1;
        end;

        exit(false);
    end;

    local procedure PopCommaSeparatedValue(var Values: Text) Value: Text
    var
        CommaPos: Integer;
    begin
        CommaPos := StrPos(Values, ',');
        if CommaPos = 0 then begin
            Value := Values;
            Values := '';
            exit(Value);
        end;

        Value := CopyStr(Values, 1, CommaPos - 1);
        Values := CopyStr(Values, CommaPos + 1);
    end;

    local procedure IsSameOptionText(OptionText: Text; ValueText: Text): Boolean
    begin
        exit(LowerCase(DelChr(OptionText, '<>', ' ')) = LowerCase(DelChr(ValueText, '<>', ' ')));
    end;
}

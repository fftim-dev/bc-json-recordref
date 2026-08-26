codeunit 70770 "Json Toolkit"
{
    Access = Public;

    procedure RecordRefToJson(RecRef: RecordRef; var JsonObj: JsonObject; UseSchema: Boolean): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(RecordRefToJson(RecRef, JsonObj, UseSchema, JsonToolkitSchema));
    end;

    procedure RecordRefToJson(RecRef: RecordRef; var JsonObj: JsonObject; UseSchema: Boolean; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.RecordRefToJson(RecRef, JsonObj, UseSchema));
    end;

    procedure RecordRefToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(RecordRefToJson(RecRef, OutputText, UseSchema, JsonToolkitSchema));
    end;

    procedure RecordRefToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.RecordRefToJson(RecRef, OutputText, UseSchema));
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var JsonArray: JsonArray; UseSchema: Boolean): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(RecordRefSetToJson(RecRef, JsonArray, UseSchema, JsonToolkitSchema));
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var JsonArray: JsonArray; UseSchema: Boolean; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.RecordRefSetToJson(RecRef, JsonArray, UseSchema));
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(RecordRefSetToJson(RecRef, OutputText, UseSchema, JsonToolkitSchema));
    end;

    procedure RecordRefSetToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.RecordRefSetToJson(RecRef, OutputText, UseSchema));
    end;

    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(JsonToRecordRef(JsonObj, RecRef, "Json Toolkit Update Mode"::Assign, JsonToolkitSchema));
    end;

    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(JsonToRecordRef(JsonObj, RecRef, UpdateMode, JsonToolkitSchema));
    end;

    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.JsonToRecordRef(JsonObj, RecRef, UpdateMode));
    end;

    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(ApplyPatch(JsonObj, RecRef, "Json Toolkit Update Mode"::Assign, JsonToolkitSchema));
    end;

    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(ApplyPatch(JsonObj, RecRef, UpdateMode, JsonToolkitSchema));
    end;

    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.ApplyPatch(JsonObj, RecRef, UpdateMode));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(CopyJsonToTable(JsonObj, TableNo, TableAction, "Json Toolkit Update Mode"::Assign, JsonToolkitSchema));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(CopyJsonToTable(JsonObj, TableNo, TableAction, UpdateMode, JsonToolkitSchema));
    end;

    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.CopyJsonToTable(JsonObj, TableNo, TableAction, UpdateMode));
    end;

    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(CopyJsonToTable(JsonArray, TableNo, TableAction, "Json Toolkit Update Mode"::Assign, JsonToolkitSchema));
    end;

    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean
    var
        JsonToolkitSchema: Interface "Json Toolkit";
    begin
        JsonToolkitSchema := GetDefaultSchema();
        exit(CopyJsonToTable(JsonArray, TableNo, TableAction, UpdateMode, JsonToolkitSchema));
    end;

    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"; JsonToolkitSchema: Interface "Json Toolkit"): Boolean
    begin
        exit(JsonToolkitSchema.CopyJsonToTable(JsonArray, TableNo, TableAction, UpdateMode));
    end;

    local procedure GetDefaultSchema() JsonToolkitSchema: Interface "Json Toolkit"
    var
        JsonToolkitImp: Codeunit "Json Toolkit Impl.";
    begin
        JsonToolkitSchema := JsonToolkitImp;
    end;
}

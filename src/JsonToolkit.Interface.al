interface "Json Toolkit"
{
    // Converts the current RecordRef into a JsonObject using either a flat structure or the Json Toolkit schema.
    procedure RecordRefToJson(RecRef: RecordRef; var JsonObj: JsonObject; UseSchema: Boolean): Boolean;
    procedure RecordRefToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean;

    // Converts a RecordRef record set into a JsonArray using either a flat structure or the Json Toolkit schema.
    procedure RecordRefSetToJson(RecRef: RecordRef; var JsonArray: JsonArray; UseSchema: Boolean): Boolean;
    procedure RecordRefSetToJson(RecRef: RecordRef; var OutputText: Text; UseSchema: Boolean): Boolean;

    // Populates a RecordRef with values from a JsonObject by mapping JSON properties to table fields.
    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef): Boolean;
    procedure JsonToRecordRef(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean;

    // Applies a patch object to an existing RecordRef. Missing fields are ignored, null fields are cleared.
    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef): Boolean;
    procedure ApplyPatch(JsonObj: JsonObject; var RecRef: RecordRef; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean;

    // Applies a JsonObject to a table specified by TableNo by inserting, modifying, or updating a record according to the provided TableAction.
    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean;
    procedure CopyJsonToTable(JsonObj: JsonObject; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean;

    // Applies each JsonObject element from a JsonArray to a table specified by TableNo by inserting, modifying, or updating records according to the provided TableAction.
    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"): Boolean;
    procedure CopyJsonToTable(JsonArray: JsonArray; TableNo: Integer; TableAction: Enum "Json Toolkit Table Action"; UpdateMode: Enum "Json Toolkit Update Mode"): Boolean;
}

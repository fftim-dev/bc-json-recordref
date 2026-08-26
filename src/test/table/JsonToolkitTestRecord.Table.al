table 70770 "Json Toolkit Test Record"
{
    Caption = 'Json Toolkit Test Record';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(4; Active; Boolean)
        {
            Caption = 'Active';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
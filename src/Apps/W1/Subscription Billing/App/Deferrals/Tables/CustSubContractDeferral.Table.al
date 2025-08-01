namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.Dimension;
using System.Security.User;

table 8066 "Cust. Sub. Contract Deferral"
{
    Caption = 'Customer Subscription Contract Deferral';
    DataClassification = CustomerContent;
    DrillDownPageId = "Customer Contract Deferrals";
    LookupPageId = "Customer Contract Deferrals";
    Permissions =
        tabledata "Sales Invoice Line" = r,
        tabledata "Sales Cr.Memo Line" = r;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Subscription Contract No."; Code[20])
        {
            Caption = 'Subscription Contract No.';
            TableRelation = "Customer Subscription Contract"."No.";
        }
        field(3; "Document Type"; Enum "Rec. Billing Document Type")
        {
            Caption = 'Document Type';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Subscription Contract Type"; Code[10])
        {
            Caption = 'Contract Type';
            TableRelation = "Subscription Contract Type".Code;
        }
        field(6; "Released"; Boolean)
        {
            Caption = 'Released';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
            ValidateTableRelation = false;
        }
        field(13; "Discount Amount"; Decimal)
        {
            Caption = 'Discount Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(14; "Deferral Base Amount"; Decimal)
        {
            Caption = 'Deferral Base Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(15; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(16; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        field(17; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(18; "Document Posting Date"; Date)
        {
            Caption = 'Document Posting Date';
            Editable = false;
        }
        field(19; "Release Posting Date"; Date)
        {
            Caption = 'Release Posting Date';
        }
        field(20; "G/L Entry No."; Integer)
        {
            Caption = 'General Ledger Entry No.';
            TableRelation = "G/L Entry";
        }
        field(21; "Number of Days"; Integer)
        {
            Caption = 'Number of Days';
        }
        field(22; "Subscription Contract Line No."; Integer)
        {
            Caption = 'Subscription Contract Line No.';
            TableRelation = "Cust. Sub. Contract Line"."Line No." where("Subscription Contract No." = field("Subscription Contract No."));
        }
        field(23; "Subscription Description"; Text[100])
        {
            Caption = 'Subscription Description';
        }
        field(24; "Subscription Line Description"; Text[100])
        {
            Caption = 'Subscription Line Description';
        }
        field(25; Discount; Boolean)
        {
            Caption = 'Discount';
        }
        field(26; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Subscription Contract No.")
        {
        }
    }
    internal procedure InitFromSalesLine(SalesLine: Record "Sales Line"; var Sign: Integer)
    begin
        case SalesLine."Document Type" of
            Enum::"Sales Document Type"::"Credit Memo":
                begin
                    "Document Type" := "Document Type"::"Credit Memo";
                    Sign := 1;
                end;
            Enum::"Sales Document Type"::Invoice:
                begin
                    "Document Type" := "Document Type"::Invoice;
                    Sign := -1;
                end;
        end;
        if (SalesLine.Quantity < 0) and (not SalesLine."Discount") then
            Sign := Sign * -1;
        Rec."Customer No." := SalesLine."Sell-to Customer No.";
        Rec."Dimension Set ID" := SalesLine."Dimension Set ID";
        Rec."Discount %" := SalesLine."Line Discount %";
        Rec."Document Line No." := SalesLine."Line No.";
        Rec."Bill-to Customer No." := SalesLine."Bill-to Customer No.";
        Rec."Document Posting Date" := SalesLine."Posting Date";
        Rec.Discount := SalesLine."Discount";
        Rec."Currency Code" := SalesLine."Currency Code";
    end;

    internal procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
        DimTextLbl: Label '%1 %2', Locked = true;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(DimTextLbl, TableCaption, "Entry No."), 1, 250));
    end;

    internal procedure FilterOnDocumentTypeAndDocumentNo(RecurringBillingDocumentType: Enum "Rec. Billing Document Type"; DocumentNo: Code[20])
    begin
        Rec.SetRange("Document Type", RecurringBillingDocumentType);
        Rec.SetRange("Document No.", DocumentNo);
    end;

    internal procedure GetDocumentPostingGroups(var GenBusPostingGroup: Code[20]; var GenProdPostingGroup: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        case "Document Type" of
            "Rec. Billing Document Type"::Invoice:
                if SalesInvoiceLine.Get("Document No.", "Document Line No.") then begin
                    GenBusPostingGroup := SalesInvoiceLine."Gen. Bus. Posting Group";
                    GenProdPostingGroup := SalesInvoiceLine."Gen. Prod. Posting Group";
                    exit(true);
                end;
            "Rec. Billing Document Type"::"Credit Memo":
                if SalesCrMemoLine.Get("Document No.", "Document Line No.") then begin
                    GenBusPostingGroup := SalesCrMemoLine."Gen. Bus. Posting Group";
                    GenProdPostingGroup := SalesCrMemoLine."Gen. Prod. Posting Group";
                    exit(true);
                end;
        end;
        exit(false);
    end;
}

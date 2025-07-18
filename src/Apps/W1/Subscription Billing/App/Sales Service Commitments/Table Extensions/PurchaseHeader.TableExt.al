namespace Microsoft.SubscriptionBilling;

using Microsoft.Purchases.Document;

tableextension 8061 "Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(8051; "Recurring Billing"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Recurring Billing';
        }
    }

    local procedure GetLastLineNo(): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No.");
    end;

    internal procedure GetNextLineNo(): Integer
    begin
        exit(GetLastLineNo() + 10000);
    end;

    internal procedure SetRecurringBilling()
    var
        DocumentChangeManagement: Codeunit "Document Change Management";
    begin
        DocumentChangeManagement.SetSkipContractPurchaseHeaderModifyCheck(true);
        Rec.Validate("Recurring Billing", true);
        Rec.Modify(false);
        DocumentChangeManagement.SetSkipContractPurchaseHeaderModifyCheck(false);
    end;

    internal procedure RunGetVendorContractLines()
    var
        GetVendorContractLines: Page "Get Vendor Contract Lines";
    begin
        GetVendorContractLines.LookupMode(true);
        GetVendorContractLines.SetPurchaseHeader(Rec);
        GetVendorContractLines.RunModal();
    end;
}
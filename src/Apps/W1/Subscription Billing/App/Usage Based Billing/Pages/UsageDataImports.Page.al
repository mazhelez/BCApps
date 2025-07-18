namespace Microsoft.SubscriptionBilling;

page 8041 "Usage Data Imports"
{
    ApplicationArea = All;
    SourceTable = "Usage Data Import";
    Caption = 'Usage Data Imports';
    UsageCategory = Lists;
    PageType = List;
    InsertAllowed = false;
    LinksAllowed = false;
    RefreshOnActivate = true;
    DataCaptionFields = "Supplier No.";
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the sequential number assigned to the record when it was created.';
                }
                field("Supplier No."; Rec."Supplier No.")
                {
                    ToolTip = 'Specifies the number of the supplier to which this usage data refers.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Supplier Description"; Rec."Supplier Description")
                {
                    ToolTip = 'Specifies the description of the supplier to which this usage data refers.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the import.';
                }
                field("Processing Date"; Rec."Processing Date")
                {
                    ToolTip = 'Specifies the date of the last processing step.';
                }
                field("Processing Step"; Rec."Processing Step")
                {
                    ToolTip = 'Specifies the last processing step.';
                }
                field("Processing Status"; Rec."Processing Status")
                {
                    ToolTip = 'Specifies the status of the last processing step.';
                    StyleExpr = ProcessingStatusStyleExpr;
                }
                field("Reason (Preview)"; Rec."Reason (Preview)")
                {
                    ToolTip = 'Specifies the preview why the last processing step failed.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReason();
                    end;
                }
                field("No. of Usage Data Blobs"; Rec."No. of Usage Data Blobs")
                {
                    ToolTip = 'Specifies the number of files of the raw data.';
                }
                field("No. of Imported Lines"; Rec."No. of Imported Lines")
                {
                    ToolTip = 'Specifies the number of Imported Lines.';
                }
                field("No. of Imported Line Errors"; Rec."No. of Imported Line Errors")
                {
                    ToolTip = 'Specifies the number of errors during the creation and processing of Imported Lines.';
                    StyleExpr = LineErrorNumberStyleExpr;
                }
                field("No. of Usage Data Billing"; Rec."No. of Usage Data Billing")
                {
                    ToolTip = 'Specifies the number of errors during the creation and processing of Usage Data Billing.';
                }
                field("No. of UD Billing Errors"; Rec."No. of UD Billing Errors")
                {
                    ToolTip = 'Specifies the number of usage data billing errors.';
                    StyleExpr = BillingErrorNumberStyleExpr;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(NewImportAndFile)
            {
                Caption = 'New Import & file';
                ToolTip = 'Creates a new import and opens a dialog for importing billing data in the form of a CSV file.';
                Image = NewRow;

                trigger OnAction()
                var
                    UsageDataImport: Record "Usage Data Import";
                begin
                    UsageDataImport.SetView(Rec.GetView());
                    UsageDataImport.NewDataImport();
                    UsageDataImport.ImportFile();
                    CurrPage.SetRecord(UsageDataImport);
                end;
            }
            action(NewImport)
            {
                Caption = 'New Import';
                ToolTip = 'Creates a new import.';
                Image = NewRow;

                trigger OnAction()
                var
                    UsageDataImport: Record "Usage Data Import";
                begin
                    UsageDataImport.SetView(Rec.GetView());
                    UsageDataImport.NewDataImport();
                    CurrPage.SetRecord(UsageDataImport);
                end;
            }
            action(ImportFile)
            {
                Caption = 'Import file';
                ToolTip = 'Enables the import of billing data in the form of a CSV file into the selected import.';
                Image = Import;
                Scope = repeater;

                trigger OnAction()
                begin
                    Rec.ImportFile();
                end;
            }
            action(ProcessData)
            {
                Caption = 'Process Data';
                ToolTip = 'Processes the imported usage data.';
                Image = Import;
                Scope = repeater;

                trigger OnAction()
                var
                    UsageDataImport: Record "Usage Data Import";
                    GenericImportSettings: Record "Generic Import Settings";
                begin
                    CurrPage.SetSelectionFilter(UsageDataImport);
                    Rec.TestField("Supplier No.");
                    GenericImportSettings.Get(Rec."Supplier No.");
                    if not GenericImportSettings."Process without UsageDataBlobs" then
                        Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Imported Lines");
                    Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Imported Lines");
                    Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
                    Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
                    CurrPage.Update();
                end;
            }
            action(CreateCustomerInvoices)
            {
                Caption = 'Create Customer Invoices';
                ToolTip = 'Creates the invoices for the Customer Subscription Contracts related to this import.';
                Image = Invoice;
                Scope = Repeater;
                Enabled = not IsProcessingStatusError;
                trigger OnAction()
                var
                    UsageDataImport: Record "Usage Data Import";
                begin
                    CurrPage.SetSelectionFilter(UsageDataImport);
                    Rec.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
                end;
            }
            action(CreateVendorInvoices)
            {
                Caption = 'Create Vendor Invoices';
                ToolTip = 'Creates the invoices for the Vendor Subscription Contracts related to this import.';
                Image = Invoice;
                Scope = Repeater;
                Enabled = not IsProcessingStatusError;
                trigger OnAction()
                var
                    UsageDataImport: Record "Usage Data Import";
                begin
                    CurrPage.SetSelectionFilter(UsageDataImport);
                    Rec.CollectVendorContractsAndCreateInvoices(UsageDataImport);
                end;
            }
        }
        area(Navigation)
        {
            group(ManualProcessing)
            {
                Caption = 'Manual Processing';
                action("Create Imported Lines")
                {
                    Caption = 'Create Imported Lines';
                    ToolTip = 'Creates (supplier-specific) imported rows based on the CSV file.';
                    Image = ExecuteBatch;

                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Imported Lines");
                        CurrPage.Update();
                    end;
                }
                action("Process Imported Lines")
                {
                    Caption = 'Process Imported Lines';
                    ToolTip = 'Searches the associated Subscription Line and creates a link to the imported rows.';
                    Image = ExecuteBatch;

                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Imported Lines");
                        CurrPage.Update();
                    end;
                }
                action("Create Usage Data Billing")
                {
                    Caption = 'Create Usage Data Billing';
                    ToolTip = 'Creates new records based on the Subscriptions and the Subscription Lines they contain.';
                    Image = ExecuteBatch;

                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
                        CurrPage.Update();
                    end;
                }
                action("Process Usage Data Billing")
                {
                    Caption = 'Process Usage Data Billing';
                    ToolTip = 'Updates the respective vendor or Customer Subscription Contract lines, Subscriptions and Subscription Lines (quantities and prices). In addition, sales prices are calculated for the customer-side usage data. The basis for this is either the sales price of the associated Customer Subscription Contract line or the usage data (selection "Sales price from import" in "Usage Data Supplier").';
                    Image = ExecuteBatch;

                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
                        CurrPage.Update();
                    end;
                }
                action("Delete Usage Data Lines & Billing")
                {
                    Caption = 'Delete Usage Data Lines & Billing';
                    ToolTip = 'Deletes all generated data without deleting the import file.';
                    Image = Delete;
                    Scope = repeater;

                    trigger OnAction()
                    begin
                        Rec.DeleteUsageDataBillingLines();
                    end;
                }
            }
            group(UsageBasedBilling)
            {
                Caption = 'Usage Based Billing';
                action(CustomerContracts)
                {
                    Caption = 'Customer Subscription Contracts';
                    ToolTip = 'Opens the Customer Subscription Contracts that are related to this import.';
                    Image = Documents;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Customer, DocumentType::Contract);
                    end;
                }
                action(CustomerContractInvoices)
                {
                    Caption = 'Customer Subscription Contract Invoices';
                    ToolTip = 'Displays the open Customer Subscription Contract invoices that are related to this import.';
                    Image = Documents;
                    Visible = UsageBasedBillingExists;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Customer, DocumentType::"Contract Invoices");
                    end;
                }
                action(PostedCustomerContractInvoices)
                {
                    Caption = 'Posted Customer Subscription Contract Invoices';
                    ToolTip = 'Opens the posted Customer Subscription Contract invoices that belong to this import.';
                    Image = Documents;
                    Visible = UsageBasedBillingExists;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Customer, DocumentType::"Posted Contract Invoices");
                    end;
                }
                action(VendorContracts)
                {
                    Caption = 'Vendor Subscription Contracts';
                    ToolTip = 'Opens the Vendor Subscription Contracts that are related to this import.';
                    Image = Documents;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Vendor, DocumentType::Contract);
                    end;
                }
                action(VendorContractInvoices)
                {
                    Caption = 'Vendor Subscription Contract Invoices';
                    ToolTip = 'Displays the open Vendor Subscription Contract invoices that are related to this import.';
                    Image = Documents;
                    Visible = UsageBasedBillingExists;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Vendor, DocumentType::"Contract Invoices");
                    end;
                }
                action(PostedVendorContractInvoices)
                {
                    Caption = 'Posted Vendor Subscription Contract Invoices';
                    ToolTip = 'Opens the posted Vendor Subscription Contract invoices that belong to this import.';
                    Image = Documents;
                    Visible = UsageBasedBillingExists;
                    trigger OnAction()
                    var
                        UsageDataImport: Record "Usage Data Import";
                    begin
                        CurrPage.SetSelectionFilter(UsageDataImport);
                        Rec.ShowRelatedDocuments(UsageDataImport, Enum::"Service Partner"::Vendor, DocumentType::"Posted Contract Invoices");
                    end;
                }

            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(NewImportAndFile_Promoted; NewImportAndFile)
                {
                }
                actionref(NewImport_Promoted; NewImport)
                {
                }
                actionref(ImportFile_Promoted; ImportFile)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ProcessData_Promoted; ProcessData)
                {
                }
                actionref(CreateCustomerInvoices_Promoted; CreateCustomerInvoices)
                {
                }
                actionref(CreateVendorInvoices_Promoted; CreateVendorInvoices)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report';
            }
            group(Category_Category4)
            {
                Caption = 'Development Tools';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyleExprIfProcessingStatusIsError();
        SetRelatedDocumentsVisibility();
    end;

    local procedure SetRelatedDocumentsVisibility()
    begin
        Rec.CalcFields("No. of Usage Data Billing");
        if Rec."No. of Usage Data Billing" <> 0 then
            UsageBasedBillingExists := true;
    end;

    local procedure SetStyleExprIfProcessingStatusIsError()
    begin
        ProcessingStatusStyleExpr := 'Standard';
        LineErrorNumberStyleExpr := 'Standard';
        BillingErrorNumberStyleExpr := 'Standard';
        IsProcessingStatusError := false;

        if Rec."Processing Status" = Enum::"Processing Status"::Error then begin
            ProcessingStatusStyleExpr := 'Attention';
            IsProcessingStatusError := true;
        end;
        Rec.CalcFields("No. of Imported Line Errors", "No. of UD Billing Errors");
        if Rec."No. of Imported Line Errors" <> 0 then
            LineErrorNumberStyleExpr := 'Unfavorable';
        if Rec."No. of UD Billing Errors" <> 0 then
            BillingErrorNumberStyleExpr := 'Unfavorable';
    end;

    var
        DocumentType: Option Contract,"Contract Invoices","Posted Contract Invoices";
        UsageBasedBillingExists: Boolean;
        IsProcessingStatusError: Boolean;
        ProcessingStatusStyleExpr: Text;
        LineErrorNumberStyleExpr: Text;
        BillingErrorNumberStyleExpr: Text;
}
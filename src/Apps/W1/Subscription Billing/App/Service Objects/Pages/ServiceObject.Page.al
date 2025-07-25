namespace Microsoft.SubscriptionBilling;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item.Attribute;

page 8060 "Service Object"
{
    Caption = 'Subscription';
    PageType = Card;
    SourceTable = "Subscription Header";
    RefreshOnActivate = true;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of Subscription.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
#if not CLEAN26
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the Item No. of the Subscription.';
                    ObsoleteReason = 'Replaced by field Source No.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
#endif
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the type of the Subscription.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Source No."; Rec."Source No.")
                {
                    ToolTip = 'Specifies the No. of the Item or G/L Account of the Subscription.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Created in Contract line"; Rec."Created in Contract line")
                {
                    ToolTip = 'Specifies whether the Subscription was created by creating a Contract line manually.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the Subscription.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the number of units of Subscription.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ToolTip = 'Specifies the unit of measure code.';
                }
                field("Customer Reference"; Rec."Customer Reference")
                {
                    ToolTip = 'Specifies the reference by which the customer identifies the Subscription.';
                }
                field(Version; Rec.Version)
                {
                    ToolTip = 'Specifies the version of the Subscription.';
                }
                field("Key"; Rec."Key")
                {
                    Visible = false;
                    ToolTip = 'Specifies the additional information (ex. License) of the Subscription.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ToolTip = 'Specifies the Serial No. assigned to the Subscription.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Visible = false;
                    ToolTip = 'Specifies the Variant Code of the Subscription.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Provision Start Date"; Rec."Provision Start Date")
                {
                    ToolTip = 'Specifies the date from which the subject of the Subscription Line and the associated Subscription Lines were made available to the customer.';
                }

                field("Provision End Date"; Rec."Provision End Date")
                {
                    ToolTip = 'Specifies the date from which the subject of the Subscription Line and the associated Subscription Lines are not longer available to the customer.';
                }
                field(PrimaryAttributeValueField; PrimaryAttributeValue)
                {
                    CaptionClass = PrimaryAttributeValueCaption;
                    ToolTip = 'Specifies the primary attribute value.';
                    Importance = Additional;
                    Editable = false;
                }
                field("Archived Service Commitments"; Rec."Archived Sub. Lines exist")
                {
                    ToolTip = 'Specifies whether archived Subscription Lines exist for the Subscription.';
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        ServiceCommitmentArchive: Record "Subscription Line Archive";
                    begin
                        if Rec."Archived Sub. Lines exist" = false then
                            exit;
                        ServiceCommitmentArchive.SetCurrentKey("Entry No.");
                        ServiceCommitmentArchive.SetAscending("Entry No.", false);
                        ServiceCommitmentArchive.SetRange("Subscription Header No.", Rec."No.");
                        Page.Run(Page::"Service Commitment Archive", ServiceCommitmentArchive);
                    end;
                }
                field("Planned Serv. Comm. exists"; Rec."Planned Sub. Lines exist")
                {
                    ToolTip = 'Specifies if planned Renewals exists for the Subscription.';
                }
            }
            part(Services; "Service Commitments")
            {
                Caption = 'Subscription Lines';
                SubPageLink = "Subscription Header No." = field("No.");
                UpdatePropagation = Both;
            }
            group("End User")
            {
                Caption = 'End User';
                field("End-User Contact No."; Rec."End-User Contact No.")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the contact of the customer to whom the Subscription Line was sold.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("End-User Contact"; Rec."End-User Contact")
                {
                    Editable = EndUserContactEditable;
                    ToolTip = 'Specifies the name of the contact to whom the Subscription Line was sold.';
                }
                field("End-User Customer No."; Rec."End-User Customer No.")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the customer to whom the Subscription Line was sold.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("End-User Customer Name"; Rec."End-User Customer Name")
                {
                    ToolTip = 'Specifies the name of the customer to whom the Subscription Line was sold.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if Rec.LookupEndUserCustomerName() then
                            CurrPage.Update();
                    end;
                }
                field("End-User Address"; Rec."End-User Address")
                {
                    ToolTip = 'Specifies the address where the customer is located.';
                }
                field("End-User Address 2"; Rec."End-User Address 2")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies additional address information.';
                }
                field("End-User Post Code"; Rec."End-User Post Code")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the postal code.';
                }
                field("End-User City"; Rec."End-User City")
                {
                    ToolTip = 'Specifies the city of the customer.';
                }
                field("End-User Country/Region Code"; Rec."End-User Country/Region Code")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the country or region of the address.';
                }
                field("End-User Phone No."; Rec."End-User Phone No.")
                {
                    Caption = 'Phone No.';
                    Importance = Additional;
                    ToolTip = 'Specifies the phone number of the contact.';
                }
                field("End-User Fax No."; Rec."End-User Fax No.")
                {
                    Caption = 'Fax No.';
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s fax number.';
                }
                field("End-User E-Mail"; Rec."End-User E-Mail")
                {
                    Caption = 'Email';
                    ToolTip = 'Specifies the email address of the contact.';
                }
            }
            group("Shipping and Billing")
            {
                Caption = 'Shipping and Billing';
                group(Control91)
                {
                    ShowCaption = false;
                    group(Control90)
                    {
                        ShowCaption = false;
                        field(ShippingOptions; ShipToOptions)
                        {
                            Caption = 'Ship-to';
                            OptionCaption = 'Default (End-User Address),Alternate Shipping Address,Custom Address';
                            ToolTip = 'Specifies the address that the Subscription and Subscription Lines were shipped. Default (End-User Address): The same as the customer''s End-User address. Alternate Ship-to Address: One of the customer''s alternate ship-to addresses. Custom Address: Any ship-to address that you specify in the fields below.';

                            trigger OnValidate()
                            var
                                ShipToAddress: Record "Ship-to Address";
                                ShipToAddressList: Page "Ship-to Address List";
                            begin
                                OnBeforeValidateShipToOptions(Rec, ShipToOptions);

                                case ShipToOptions of
                                    ShipToOptions::"Default (End-User Address)":
                                        begin
                                            Rec.Validate("Ship-to Code", '');
                                            Rec.CopyEndUserAddressToShipToAddress();
                                        end;
                                    ShipToOptions::"Alternate Shipping Address":
                                        begin
                                            ShipToAddress.SetRange("Customer No.", Rec."End-User Customer No.");
                                            ShipToAddressList.LookupMode := true;
                                            ShipToAddressList.SetTableView(ShipToAddress);

                                            if ShipToAddressList.RunModal() = Action::LookupOK then begin
                                                ShipToAddressList.GetRecord(ShipToAddress);
                                                OnValidateShipToOptionsOnAfterShipToAddressListGetRecord(ShipToAddress, Rec);
                                                Rec.Validate("Ship-to Code", ShipToAddress.Code);
                                                IsShipToCountyVisible := FormatAddress.UseCounty(ShipToAddress."Country/Region Code");
                                            end else
                                                ShipToOptions := ShipToOptions::"Custom Address";
                                        end;
                                    ShipToOptions::"Custom Address":
                                        begin
                                            Rec.Validate("Ship-to Code", '');
                                            IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                                        end;
                                end;

                                OnAfterValidateShippingOptions(Rec, ShipToOptions);
                            end;
                        }
                        group(Control4)
                        {
                            ShowCaption = false;
                            Visible = not (ShipToOptions = ShipToOptions::"Default (End-User Address)");
                            field("Ship-to Code"; Rec."Ship-to Code")
                            {
                                Caption = 'Code';
                                Editable = ShipToOptions = ShipToOptions::"Alternate Shipping Address";
                                Importance = Promoted;
                                ToolTip = 'Specifies the code for another shipment address than the customer''s own address, which is entered by default.';

                                trigger OnValidate()
                                var
                                    ShipToAddress: Record "Ship-to Address";
                                begin
                                    if (xRec."Ship-to Code" <> '') and (Rec."Ship-to Code" = '') then
                                        Error(EmptyShipToCodeErr);
                                    if Rec."Ship-to Code" <> '' then begin
                                        ShipToAddress.Get(Rec."End-User Customer No.", Rec."Ship-to Code");
                                        IsShipToCountyVisible := FormatAddress.UseCounty(ShipToAddress."Country/Region Code");
                                    end else
                                        IsShipToCountyVisible := false;
                                end;
                            }
                            field("Ship-to Name"; Rec."Ship-to Name")
                            {
                                Caption = 'Name';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                ToolTip = 'Specifies the name that Subscription and Subscription Lines were shipped.';
                            }
                            field("Ship-to Address"; Rec."Ship-to Address")
                            {
                                Caption = 'Address';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the address that Subscription and Subscription Lines were shipped.';
                            }
                            field("Ship-to Address 2"; Rec."Ship-to Address 2")
                            {
                                Caption = 'Address 2';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies additional address information.';
                            }
                            field("Ship-to City"; Rec."Ship-to City")
                            {
                                Caption = 'City';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the city of the customer.';
                            }
                            group(Control297)
                            {
                                ShowCaption = false;
                                Visible = IsShipToCountyVisible;
                                field("Ship-to County"; Rec."Ship-to County")
                                {
                                    Caption = 'County';
                                    Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                    QuickEntry = false;
                                    ToolTip = 'Specifies the state, province or county of the address.';
                                }
                            }
                            field("Ship-to Post Code"; Rec."Ship-to Post Code")
                            {
                                Caption = 'Post Code';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                                ToolTip = 'Specifies the postal code.';
                            }
                            field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                            {
                                Caption = 'Country/Region';
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                Importance = Additional;
                                QuickEntry = false;
                                ToolTip = 'Specifies the customer''s country/region.';

                                trigger OnValidate()
                                begin
                                    IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                                end;
                            }
                        }
                        field("Ship-to Contact"; Rec."Ship-to Contact")
                        {
                            Caption = 'Contact';
                            ToolTip = 'Specifies the name of the contact person at the address that Subscription and Subscription Lines were shipped.';
                        }
                    }
                }
                group(Control85)
                {
                    ShowCaption = false;
                    field(BillToOptions; BillToOptions)
                    {
                        Caption = 'Bill-to';
                        OptionCaption = 'Default (Customer),Another Customer,Custom Address';
                        ToolTip = 'Specifies the customer that the sales invoice will be sent to. Default (Customer): The same as the customer on the sales invoice. Another Customer: Any customer that you specify in the fields below.';

                        trigger OnValidate()
                        begin
                            if BillToOptions = BillToOptions::"Default (Customer)" then begin
                                Rec.Validate("Bill-to Customer No.", Rec."End-User Customer No.");
                                Rec.RecallModifyAddressNotification(Rec.GetModifyBillToCustomerAddressNotificationId());
                            end;

                            Rec.CopyEndUserAddressToBillToAddress();

                            UpdateBillToFieldsEnabled();
                        end;
                    }
                    group(Control82)
                    {
                        ShowCaption = false;
                        Visible = not (BillToOptions = BillToOptions::"Default (Customer)");
                        field("Bill-to Name"; Rec."Bill-to Name")
                        {
                            Caption = 'Name';
                            Editable = BillToOptions = BillToOptions::"Another Customer";
                            Enabled = BillToOptions = BillToOptions::"Another Customer";
                            Importance = Promoted;
                            ToolTip = 'Specifies the customer to whom you will send the sales invoice, when different from the customer that you are selling to.';

                            trigger OnValidate()
                            begin
                                if Rec.GetFilter("Bill-to Customer No.") = xRec."Bill-to Customer No." then
                                    if Rec."Bill-to Customer No." <> xRec."Bill-to Customer No." then
                                        Rec.SetRange("Bill-to Customer No.");

                                CurrPage.Update(true);
                            end;
                        }
                        field("Bill-to Address"; Rec."Bill-to Address")
                        {
                            Caption = 'Address';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the address of the customer that you will send the invoice to.';
                        }
                        field("Bill-to Address 2"; Rec."Bill-to Address 2")
                        {
                            Caption = 'Address 2';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies additional address information.';
                        }
                        field("Bill-to City"; Rec."Bill-to City")
                        {
                            Caption = 'City';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the city of the customer on the sales document.';
                        }
                        group(Control130)
                        {
                            ShowCaption = false;
                            Visible = IsBillToCountyVisible;
                            field("Bill-to County"; Rec."Bill-to County")
                            {
                                Caption = 'County';
                                Editable = BillToFieldsEnabled;
                                Enabled = BillToFieldsEnabled;
                                Importance = Additional;
                                QuickEntry = false;
                                ToolTip = 'Specifies the state, province or county of the address.';
                            }
                        }
                        field("Bill-to Post Code"; Rec."Bill-to Post Code")
                        {
                            Caption = 'Post Code';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the postal code.';
                        }
                        field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                        {
                            Caption = 'Country/Region Code';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            QuickEntry = false;
                            ToolTip = 'Specifies the country or region of the address.';

                            trigger OnValidate()
                            begin
                                IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
                            end;
                        }
                        field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                        {
                            Caption = 'Contact No.';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            Importance = Additional;
                            ToolTip = 'Specifies the number of the contact the invoice will be sent to.';
                        }
                        field("Bill-to Contact"; Rec."Bill-to Contact")
                        {
                            Caption = 'Contact';
                            Editable = BillToFieldsEnabled;
                            Enabled = BillToFieldsEnabled;
                            ToolTip = 'Specifies the name of the person you should contact at the customer who you are sending the invoice to.';
                        }
                    }
                }
            }
        }
        area(FactBoxes)
        {
            part(ServiceObjectAttrFactbox; "Service Object Attr. Factbox")
            {
                ApplicationArea = Basic, Suite;
                Visible = Rec.Type = Rec.Type::Item;
            }
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
                Visible = Rec.Type = Rec.Type::Item;
            }
            part("Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Subscription Header"),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignServices)
            {
                Caption = 'Assign Subscription Lines';
                ToolTip = 'Opens the page with assignable Subscription Packages.';
                Image = ServiceLedger;
                Enabled = Rec.Type = Rec.Type::Item;

                trigger OnAction()
                var
                    ServiceCommitmentPackage: Record "Subscription Package";
                    ItemServCommitmentPackage: Record "Item Subscription Package";
                    AssignServiceCommitments: Page "Assign Service Commitments";
                    PackageFilter: Text;
                begin
                    Rec.TestField("No.");
                    Rec.TestField(Type, Rec.Type::Item);
                    Rec.TestField("Source No.");
                    PackageFilter := ItemServCommitmentPackage.GetPackageFilterForItem(Rec."Source No.", Rec."No.");
                    ServiceCommitmentPackage.SetRange("Price Group", Rec."Customer Price Group");
                    if ServiceCommitmentPackage.IsEmpty() then
                        ServiceCommitmentPackage.SetRange("Price Group");
                    ServiceCommitmentPackage.FilterCodeOnPackageFilter(PackageFilter);
                    AssignServiceCommitments.SetTableView(ServiceCommitmentPackage);
                    AssignServiceCommitments.SetServiceObject(Rec);
                    AssignServiceCommitments.LookupMode(true);
                    if AssignServiceCommitments.RunModal() = Action::LookupOK then begin
                        AssignServiceCommitments.GetSelectionFilter(ServiceCommitmentPackage);
                        Rec.InsertServiceCommitmentsFromServCommPackage(AssignServiceCommitments.GetServiceAndCalculationStartDate(), ServiceCommitmentPackage);
                    end;
                end;
            }

            action(UpdateServicesDatesAction)
            {
                Caption = 'Update Subscription Line Dates';
                Image = ChangeDates;
                ToolTip = 'The function updates the dates in the Subscription Lines.';

                trigger OnAction()
                begin
                    Rec.UpdateServicesDates();
                end;
            }
            action(UpdateExchangeRates)
            {
                Caption = 'Update Exchange Rates';
                Image = ChangeDates;
                ToolTip = 'Starts the update of the exchange rate.';

                trigger OnAction()
                begin
                    Rec.UpdateAmountsOnServiceCommitmentsBasedOnExchangeRates();
                end;
            }
        }
        area(Navigation)
        {
            action(Attributes)
            {
                AccessByPermission = tabledata "Item Attribute" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Attributes';
                Image = Category;
                ToolTip = 'Displays the attributes of the Subscription that describe it in more detail.';
                Enabled = Rec.Type = Rec.Type::Item;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Serv. Object Attr. Values", Rec);
                    CurrPage.SaveRecord();
                    CurrPage.ServiceObjectAttrFactbox.Page.LoadServiceObjectAttributesData(Rec."No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(AssignServices_Promoted; AssignServices) { }
                actionref(UpdateServicesDatesAction_Promoted; UpdateServicesDatesAction) { }
                actionref(UpdateExchangeRates_Promoted; UpdateExchangeRates) { }
                actionref(Attributes_Promoted; Attributes) { }
            }
        }
    }

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShippingOptions(var SubscriptionHeader: Record "Subscription Header"; ShipToOptions: Option "Default (End-User Address)","Alternate Shipping Address","Custom Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToOptions(var SubscriptionHeader: Record "Subscription Header"; ShipToOptions: Option "Default (End-User Address)","Alternate Shipping Address","Custom Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToOptionsOnAfterShipToAddressListGetRecord(var ShipToAddress: Record "Ship-to Address"; var SubscriptionHeader: Record "Subscription Header")
    begin
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateShipToBillToGroupVisibility();
        UpdateBillToFieldsEnabled();
        EndUserContactEditable := Rec."End-User Customer No." <> '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateShipToBillToGroupVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.IsItem() then begin
            CurrPage.ServiceObjectAttrFactbox.Page.LoadServiceObjectAttributesData(Rec."No.");
            CurrPage.ItemAttributesFactbox.Page.LoadItemAttributesData(Rec."Source No.");
            Rec.SetPrimaryAttributeValueAndCaption(PrimaryAttributeValue, PrimaryAttributeValueCaption);
        end;
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsBillToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        BillToFieldsEnabled: Boolean;
        EndUserContactEditable: Boolean;
        EmptyShipToCodeErr: Label 'The Code field can only be empty if you select Custom Address in the Ship-to field.';
        PrimaryAttributeValue: Text[250];
        PrimaryAttributeValueCaption: Text;

    protected var
        ShipToOptions: Option "Default (End-User Address)","Alternate Shipping Address","Custom Address";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";

    local procedure UpdateShipToBillToGroupVisibility()
    begin
        Rec.CalculateShipToBillToOptions(ShipToOptions, BillToOptions, Rec);
    end;

    local procedure UpdateBillToFieldsEnabled()
    begin
        BillToFieldsEnabled := (BillToOptions = BillToOptions::"Custom Address") or (Rec."Bill-to Customer No." <> Rec."End-User Customer No.");
    end;
}
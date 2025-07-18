// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment;
using System.Security.AccessControl;

codeunit 9844 "User Selection Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata User = r;

    var
        UserNameDoesNotExistErr: Label 'The user name %1 does not exist.', Comment = '%1 username';

    procedure HideExternalAndSystemUsers(var User: Record User)
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        User.FilterGroup(2);
        if not EnvironmentInformation.IsSaaS() then
            User.SetFilter("License Type", '<>%1&<>%2&<>%3', User."License Type"::Application, User."License Type"::"Windows Group", User."License Type"::"Agent")
        else
            User.SetFilter("License Type", '<>%1&<>%2&<>%3&<>%4', User."License Type"::"External User", User."License Type"::Application, User."License Type"::"AAD Group", User."License Type"::"Agent");
        User.FilterGroup(0);
    end;

    procedure HideOnlyExternalUsers(var User: Record User)
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        User.FilterGroup(2);
        if EnvironmentInformation.IsSaaS() then
            User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
        User.FilterGroup(0);
    end;

    procedure Open(var SelectedUser: Record User; HideOnlyExternal: Boolean): Boolean
    var
        UserLookup: Page "User Lookup";
    begin
        UserLookup.SetHideOnlyExternalUsers(HideOnlyExternal);
        UserLookup.SetTableView(SelectedUser);
        UserLookup.LookupMode := true;
        if UserLookup.RunModal() = Action::LookupOK then begin
            UserLookup.GetSelectedUsers(SelectedUser);
            exit(true);
        end;
        exit(false);
    end;

    procedure ValidateUserName(UserName: Code[50])
    var
        User: Record User;
    begin
        if UserName = '' then
            exit;
        if User.IsEmpty() then
            exit;
        User.SetRange("User Name", UserName);
        if User.IsEmpty() then
            Error(UserNameDoesNotExistErr, UserName);
    end;

    procedure FilterSystemUserAndAADGroupUsers(var User: Record User)
    begin
        User.SetFilter("License Type", '<>%1&<>%2', User."License Type"::"External User", User."License Type"::"AAD Group");
    end;

    procedure FilterSystemUserAndGroupUsers(var User: Record User)
    begin
        User.SetFilter("License Type", '<>%1&<>%2&<>%3', User."License Type"::"External User", User."License Type"::"AAD Group", User."License Type"::"Windows Group");
    end;
}


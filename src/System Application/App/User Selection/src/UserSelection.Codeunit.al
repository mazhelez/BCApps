// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Security.AccessControl;

/// <summary>
/// Provides basic functionality to open a search page and validate user information.
/// </summary>
codeunit 9843 "User Selection"
{
    Access = Public;

    /// <summary>
    /// Opens the user lookup page with external and system users (application, agent, etc.) filtered out and assigns the selected users on the <paramref name="SelectedUser"/> parameter.
    /// </summary>
    /// <param name="SelectedUser">The variable to return the selected users. Any filters on this record will influence the page view.</param>
    /// <returns>Returns true if a user was selected.</returns>
    procedure Open(var SelectedUser: Record User): Boolean
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        exit(UserSelectionImpl.Open(SelectedUser, false));
    end;

    /// <summary>
    /// Opens the user lookup page with only external users filtered out and assigns the selected users on the <paramref name="SelectedUser"/> parameter.
    /// </summary>
    /// <param name="SelectedUser">The variable to return the selected users. Any filters on this record will influence the page view.</param>
    /// <returns>Returns true if a user was selected.</returns>
    procedure OpenWithSystemUsers(var SelectedUser: Record User): Boolean
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        exit(UserSelectionImpl.Open(SelectedUser, true));
    end;

    /// <summary>
    /// Displays an error if there is no user with the given username and the user table is not empty.
    /// </summary>
    /// <param name="UserName">The username to validate.</param>
    procedure ValidateUserName(UserName: Code[50])
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        UserSelectionImpl.ValidateUserName(UserName);
    end;

    /// <summary>
    /// Sets Filter on the given User Record to exclude external and system (application, agent, etc.) users.
    /// </summary>
    /// <param name="User">The User Record to return.</param>
    procedure HideExternalUsers(var User: Record User)
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        UserSelectionImpl.HideExternalAndSystemUsers(User);
    end;

    /// <summary>
    /// Sets Filter on the given User Record to exclude the system user and Microsoft Entra group users.
    /// </summary>
    /// <param name="User">The User Record to return.</param>
    procedure FilterSystemUserAndAADGroupUsers(var User: Record User)
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        UserSelectionImpl.FilterSystemUserAndAADGroupUsers(User);
    end;

    /// <summary>
    /// Sets Filter on the given User Record to exclude the system user, Microsoft Entra group users and Windows Group users.
    /// </summary>
    /// <param name="User">The User Record to return.</param>
    procedure FilterSystemUserAndGroupUsers(var User: Record User)
    var
        UserSelectionImpl: Codeunit "User Selection Impl.";
    begin
        UserSelectionImpl.FilterSystemUserAndGroupUsers(User);
    end;
}


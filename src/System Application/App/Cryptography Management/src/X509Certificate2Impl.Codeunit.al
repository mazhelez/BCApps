// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;

codeunit 1285 "X509Certificate2 Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CertInitializeErr: Label 'Unable to initialize certificate!';

    procedure VerifyCertificate(var CertBase64Value: Text; Password: SecretText; X509ContentType: Enum "X509 Content Type"): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        ExportToBase64String(CertBase64Value, X509Certificate2, X509ContentType);
        exit(true);
    end;

    procedure GetCertificateFriendlyName(CertBase64Value: Text; Password: SecretText; var FriendlyName: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        FriendlyName := X509Certificate2.FriendlyName();
    end;

    procedure GetCertificateSubject(CertBase64Value: Text; Password: SecretText; var Subject: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        Subject := X509Certificate2.Subject;
    end;

    procedure GetCertificateThumbprint(CertBase64Value: Text; Password: SecretText; var Thumbprint: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        Thumbprint := X509Certificate2.Thumbprint();
    end;

    procedure GetCertificateIssuer(CertBase64Value: Text; Password: SecretText; var Issuer: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        Issuer := X509Certificate2.Issuer();
    end;

    procedure GetCertificateExpiration(CertBase64Value: Text; Password: SecretText; var Expiration: DateTime)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        Evaluate(Expiration, X509Certificate2.GetExpirationDateString());
    end;

    procedure GetCertificateNotBefore(CertBase64Value: Text; Password: SecretText; var NotBefore: DateTime)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        Evaluate(NotBefore, X509Certificate2.GetEffectiveDateString());
    end;

    procedure HasPrivateKey(CertBase64Value: Text; Password: SecretText): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        exit(X509Certificate2.HasPrivateKey());
    end;

    procedure GetCertificateSerialNumber(CertBase64Value: Text; Password: SecretText; var SerialNumber: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        SerialNumber := X509Certificate2.SerialNumber;
    end;

    procedure GetCertificateSerialNumberAsASCII(CertBase64Value: Text; Password: SecretText; var SerialNumberASCII: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
        SerialHex: Text;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        SerialHex := X509Certificate2.SerialNumber;

        if SerialHex = '' then
            exit;

        SerialNumberASCII := ConvertHexToAscii(SerialHex);
    end;

    procedure GetCertificatePropertiesAsJson(CertBase64Value: Text; Password: SecretText; var CertPropertyJson: Text)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        CreateCertificatePropertyJson(X509Certificate2, CertPropertyJson);
    end;

    [NonDebuggable]
    procedure GetSecretCertificatePrivateKey(CertBase64Value: Text; Password: SecretText): SecretText
    var
        X509Certificate2: DotNet X509Certificate2;
        AsymmetricAlgorithm: DotNet AsymmetricAlgorithm;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        if not X509Certificate2.HasPrivateKey then
            exit;

        AsymmetricAlgorithm := X509Certificate2.PrivateKey;
        exit(AsymmetricAlgorithm.ToXmlString(true));
    end;

    [NonDebuggable]
    procedure GetCertificatePublicKey(CertBase64Value: Text; Password: SecretText): Text
    var
        X509Certificate2: DotNet X509Certificate2;
        AsymmetricAlgorithm: DotNet AsymmetricAlgorithm;
    begin
        InitializeX509Certificate(CertBase64Value, Password, X509Certificate2);
        AsymmetricAlgorithm := X509Certificate2.PublicKey."Key";
        exit(AsymmetricAlgorithm.ToXmlString(false));
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryInitializeCertificate(CertBase64Value: Text; Password: SecretText; var X509Certificate2: DotNet X509Certificate2)
    var
        X509KeyStorageFlags: DotNet X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        X509Certificate2 := X509Certificate2.X509Certificate2(Convert.FromBase64String(CertBase64Value), Password.Unwrap(), X509KeyStorageFlags.Exportable);
        if IsNull(X509Certificate2) then
            Error('');
    end;

    [TryFunction]
    local procedure TryExportToBase64String(X509Certificate2: DotNet X509Certificate2; X509ContentType: Enum "X509 Content Type"; var CertBase64Value: Text)
    var
        Convert: DotNet Convert;
        X509ContType: DotNet X509ContentType;
        Enum: DotNet Enum;
    begin
        X509ContType := Enum.Parse(GetDotNetType(X509ContType), Format(X509ContentType));
        CertBase64Value := Convert.ToBase64String(X509Certificate2.Export(X509ContType));
    end;

    procedure InitializeX509Certificate(CertBase64Value: Text; Password: SecretText; var X509Certificate2: DotNet X509Certificate2)
    begin
        if not TryInitializeCertificate(CertBase64Value, Password, X509Certificate2) then
            Error(CertInitializeErr);
    end;

    local procedure ExportToBase64String(var CertBase64Value: Text; var X509Certificate2: DotNet X509Certificate2; X509ContentType: Enum "X509 Content Type")
    begin
        if not TryExportToBase64String(X509Certificate2, X509ContentType, CertBase64Value) then
            Error(GetLastErrorText());
    end;

    local procedure CreateCertificatePropertyJson(X509Certificate2: DotNet X509Certificate2; var CertPropertyJson: Text)
    var
        JObject: JsonObject;
        PropertyInfo: DotNet PropertyInfo;
    begin
        foreach PropertyInfo in X509Certificate2.GetType().GetProperties() do
            if PropertyInfo.PropertyType().ToString() in ['System.Boolean', 'System.String', 'System.DateTime', 'System.Int32'] then
                JObject.Add(PropertyInfo.Name(), Format(PropertyInfo.GetValue(X509Certificate2), 0, 0));
        JObject.WriteTo(CertPropertyJson);
    end;

    local procedure ConvertHexToAscii(SerialHex: Text): Text
    var
        Convert: DotNet Convert;
        CharObj: Char;
        i: Integer;
        SerialNumberASCII: Text;
    begin
        for i := 1 to StrLen(SerialHex) do begin
            CharObj := Convert.ToInt32(SerialHex.Substring(i, 2), 16);
            SerialNumberASCII += CharObj;
            i += 1;
        end;

        exit(SerialNumberASCII);
    end;

    [NonDebuggable]
    procedure CreateFromPemAndExportAsBase64(CertBase64: Text; PrivateKeyXmlString: SecretText; Password: SecretText): Text
    var
        RSA: Codeunit "RSA Impl.";
        RSAEncryptionHelper: DotNet RSAEncryptionHelper;
        BeginCertTok: Label '-----BEGIN CERTIFICATE-----', Locked = true;
        EndCertTok: Label '-----END CERTIFICATE-----', Locked = true;
    begin
        if CertBase64 = '' then
            exit;

        if PrivateKeyXmlString.IsEmpty() then
            exit;

        if Password.IsEmpty() then
            exit;

        if not CertBase64.StartsWith(BeginCertTok) then
            CertBase64 := BeginCertTok + CertBase64 + EndCertTok;

        RSA.FromSecretXmlString(PrivateKeyXmlString);

        exit(RSAEncryptionHelper.CreateBase64Pkcs12FromPem(CertBase64, RSA.ExportRSAPrivateKeyPem(), Password));
    end;
}
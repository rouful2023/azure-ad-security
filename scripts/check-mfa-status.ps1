# check-mfa-status.ps1
# Microsoft 365 MFA Enrollment Status Report
# Author: Md Rouful Alam Majumder
# Requires: Microsoft.Graph module, User.Read.All and UserAuthenticationMethod.Read.All permissions

param(
    [string] $ExportCSV = ".\mfa-status-report.csv"
)

# Connect
Write-Host "`n  [*] Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All" -NoWelcome

$results = @()
$users = Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses |
         Where-Object { $_.AccountEnabled -eq $true -and $_.AssignedLicenses.Count -gt 0 }

Write-Host "  [*] Checking MFA status for $($users.Count) licensed users...`n" -ForegroundColor Cyan

$i = 0
foreach ($user in $users) {
    $i++
    Write-Progress -Activity "Checking MFA status" -Status "$($user.UserPrincipalName)" -PercentComplete (($i / $users.Count) * 100)

    $methods = Get-MgUserAuthenticationMethod -UserId $user.Id
    $methodTypes = $methods.AdditionalProperties.'@odata.type'

    $hasMFA        = $methodTypes | Where-Object { $_ -ne '#microsoft.graph.passwordAuthenticationMethod' }
    $hasAuthApp    = $methodTypes -contains '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'
    $hasFIDO2      = $methodTypes -contains '#microsoft.graph.fido2AuthenticationMethod'
    $hasPhone      = $methodTypes -contains '#microsoft.graph.phoneAuthenticationMethod'
    $mfaRegistered = ($hasMFA | Measure-Object).Count -gt 0

    $results += [PSCustomObject]@{
        DisplayName        = $user.DisplayName
        UserPrincipalName  = $user.UserPrincipalName
        MFARegistered      = $mfaRegistered
        AuthenticatorApp   = [bool]$hasAuthApp
        FIDO2Key           = [bool]$hasFIDO2
        PhoneSMS           = [bool]$hasPhone
        MethodCount        = ($hasMFA | Measure-Object).Count
    }
}

# Summary
$registered   = $results | Where-Object { $_.MFARegistered }
$notRegistered = $results | Where-Object { -not $_.MFARegistered }
$smsOnly      = $results | Where-Object { $_.PhoneSMS -and -not $_.AuthenticatorApp -and -not $_.FIDO2Key }

Write-Host "`n  ==============================" -ForegroundColor Cyan
Write-Host "  MFA Status Summary" -ForegroundColor Cyan
Write-Host "  ==============================" -ForegroundColor Cyan
Write-Host "  Total licensed users : $($results.Count)"
Write-Host "  MFA registered       : $($registered.Count)" -ForegroundColor Green
Write-Host "  NOT registered       : $($notRegistered.Count)" -ForegroundColor Red
Write-Host "  SMS only (weak MFA)  : $($smsOnly.Count)" -ForegroundColor Yellow

if ($notRegistered) {
    Write-Host "`n  Users WITHOUT MFA:" -ForegroundColor Red
    $notRegistered | Format-Table DisplayName, UserPrincipalName -AutoSize
}

$results | Export-Csv -Path $ExportCSV -NoTypeInformation
Write-Host "`n  [+] Full report saved to: $ExportCSV`n" -ForegroundColor Green

# ☁️ Azure AD & Microsoft 365 Security — Field Notes

Practical notes, commands, and scripts from real-world Azure AD and Microsoft 365 administration. Covers identity security, conditional access, threat protection, and incident response.

> Built from hands-on experience as an IT Manager administering Azure AD, MFA, Office 365 migrations, and Threat Protection configurations across multiple organisations.

---

## Contents

| File | Description |
|------|-------------|
| `notes-azure-ad.md` | Azure AD identity security — concepts, commands, tips |
| `notes-conditional-access.md` | Conditional Access policy design and examples |
| `notes-o365-threat-protection.md` | Microsoft Defender for Office 365 — setup and tuning |
| `scripts/get-signin-report.ps1` | Export Azure AD sign-in logs with risk filtering |
| `scripts/check-mfa-status.ps1` | Report on MFA enrollment status for all users |
| `scripts/o365-migration-checklist.sh` | Pre/post Office 365 domain migration checklist |

---

## Quick Reference

### Connect to Microsoft Graph (PowerShell)
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "AuditLog.Read.All","User.Read.All","Policy.Read.All"
```

### Connect to Azure AD (legacy)
```powershell
Install-Module AzureAD
Connect-AzureAD
```

### Get all users without MFA
```powershell
Get-MgUser -All | Where-Object {
    (Get-MgUserAuthenticationMethod -UserId $_.Id).Count -le 1
} | Select DisplayName, UserPrincipalName
```

---

## Key Concepts Covered

- Azure AD tenant structure and licensing tiers
- Conditional Access — named locations, device compliance, sign-in risk
- Azure AD Identity Protection — risk policies, risky users/sign-ins
- Privileged Identity Management (PIM) — JIT admin access
- MFA methods — Authenticator App, FIDO2, TOTP, SMS (avoid SMS)
- Microsoft Defender for Office 365 — Safe Attachments, Safe Links, Anti-phishing
- Office 365 domain migration — DNS, mailbox migration, licensing, security config
- Azure AD audit logs — what to monitor and how to alert

---

## Author

**Md Rouful Alam Majumder** — Master of Cyber Security, CDU  
[GitHub](https://github.com/rouful2023) · [Email](mailto:rouful.info@gmail.com)

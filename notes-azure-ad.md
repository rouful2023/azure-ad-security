# Azure AD Identity Security — Field Notes

Personal notes from administering Azure AD across enterprise environments.  
Updated: May 2026

---

## Tenant Basics

```
Azure AD Tenant
├── Users & Groups
├── App Registrations (service principals)
├── Devices (Azure AD joined / Hybrid joined / Registered)
├── Conditional Access Policies
├── Identity Protection (requires P2 licence)
└── Privileged Identity Management / PIM (requires P2 licence)
```

**Licence tiers that matter for security:**
| Feature | Free | P1 | P2 |
|---------|------|----|----|
| MFA per-user | ✅ | ✅ | ✅ |
| Conditional Access | ❌ | ✅ | ✅ |
| Identity Protection | ❌ | ❌ | ✅ |
| PIM | ❌ | ❌ | ✅ |
| Sign-in risk policies | ❌ | ❌ | ✅ |

---

## Multi-Factor Authentication

### MFA Methods (strongest → weakest)
1. **FIDO2 security key** — phishing-resistant, hardware-based ✅ Best
2. **Microsoft Authenticator (number match)** — push notification with match ✅ Recommended
3. **TOTP (Authenticator App code)** — time-based one-time password ✅ Good
4. **Phone call** — susceptible to SIM swap ⚠️ Avoid
5. **SMS** — susceptible to SIM swap and SS7 attacks ❌ Weakest

### Enforce MFA via Conditional Access (preferred over per-user MFA)
```
Policy: Require MFA for all users
├── Users: All users
├── Cloud apps: All cloud apps
├── Conditions: Any
└── Grant: Require MFA
```

### Check if a user has MFA registered
```powershell
# Microsoft Graph
$methods = Get-MgUserAuthenticationMethod -UserId "user@domain.com"
$methods | Select-Object AdditionalProperties
```

---

## Conditional Access Policies

### Baseline policies every tenant should have

**1. Block legacy authentication**
```
Users: All users
Cloud apps: All cloud apps
Conditions: Client apps = Exchange ActiveSync + Other clients
Grant: Block access
```
> Why: Legacy auth clients cannot do MFA — biggest attack vector for password spray.

**2. Require MFA for admins**
```
Users: Directory roles (Global Admin, etc.)
Cloud apps: All cloud apps
Grant: Require MFA
```

**3. Require MFA for all users**
```
Users: All users
Cloud apps: All cloud apps
Grant: Require MFA
```

**4. Sign-in risk policy (requires P2)**
```
Users: All users
Conditions: Sign-in risk = Medium or High
Grant: Require MFA or Block
```

### Named Locations — restrict access by country
```powershell
# Create named location (example: Australia only)
$ipRanges = @{ "@odata.type" = "#microsoft.graph.iPv4CidrRange"; cidrAddress = "203.0.113.0/24" }
```

---

## Azure AD Identity Protection (P2)

**Two key policies:**

### User Risk Policy
- Triggers when a user's account shows signs of compromise (leaked credentials, unusual behaviour)
- Action: Require password change for **High** risk users

### Sign-in Risk Policy  
- Triggers on anomalous sign-in patterns (impossible travel, anonymous IP, unfamiliar location)
- Action: Require MFA for **Medium** risk, Block for **High** risk

### Monitor risky users
```powershell
# Get risky users
Get-MgRiskyUser -Filter "riskLevel eq 'high'" | Select DisplayName, UserPrincipalName, RiskDetail
```

---

## Privileged Identity Management (PIM)

PIM enables **Just-In-Time (JIT)** access to privileged roles — admins must "activate" their role when needed, rather than being permanently assigned.

**Benefits:**
- Reduces the attack surface (compromised admin account = less damage)
- Creates an audit trail for all privilege use
- Requires MFA + justification to activate

**Key settings:**
- Activation max duration: **4–8 hours**
- Require MFA on activation: **Always**
- Require justification: **Yes**
- Require approval for Global Admin: **Yes**

---

## Audit Logs — What to Monitor

| Event | Why it matters |
|-------|---------------|
| Sign-in failures (high volume) | Password spray / brute force |
| Sign-in from new country | Account takeover |
| MFA blocked / denied | MFA fatigue attack |
| Admin role assigned | Privilege escalation |
| Conditional Access policy changed | Policy tampering |
| Bulk user deletion | Destructive action / insider threat |
| App consent granted | OAuth phishing |

```powershell
# Get failed sign-ins from the last 7 days
$startDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
Get-MgAuditLogSignIn -Filter "status/errorCode ne 0 and createdDateTime ge $startDate" |
    Select UserDisplayName, UserPrincipalName, IpAddress, Location, CreatedDateTime |
    Sort-Object CreatedDateTime -Descending
```

---

## Office 365 Domain Migration — Key Steps

From my experience executing domain migrations at Redline Courier Service:

### Pre-migration
- [ ] Verify domain ownership in M365 admin centre (add TXT record to DNS)
- [ ] Check existing MX records and note current mail flow
- [ ] Export user list and licence assignments
- [ ] Document existing mailbox rules and shared mailboxes
- [ ] Test with a pilot mailbox first

### DNS changes
```
MX  → <tenant>.mail.protection.outlook.com  (priority 0)
SPF → v=spf1 include:spf.protection.outlook.com -all
DKIM → enabled from M365 Security admin
Autodiscover → autodiscover.outlook.com (CNAME)
```

### Post-migration
- [ ] Verify mail flow (send test emails)
- [ ] Confirm Outlook auto-configures via Autodiscover
- [ ] Enable DKIM signing in Defender for Office 365
- [ ] Configure DMARC policy
- [ ] Re-apply Conditional Access and MFA policies
- [ ] Check mobile devices reconnect (Intune / ActiveSync)
- [ ] Validate shared mailboxes and distribution lists

# vmware-sec-assessment.ps1

**Name:** vmware-sec-assessment.ps1  
**Purpose:** Read-only vSphere 8 Security Assessment using VMware PowerCLI.  
**Author:** LT  
**Version:** 1.2  
**Target:** VMware vSphere 8

---

## Disclaimer

This script is provided "as is", without any warranty of any kind. Use it at your own risk. You are solely responsible for reviewing, testing, and implementing it in your own environment.

---

## Overview

`vmware-sec-assessment.ps1` runs a set of **read-only** compliance/hardening checks for **vSphere 8**.  
It inspects ESXi hosts, networking, logging, and **all virtual machines** (no VM name required).  
The script **does not modify** any configuration; it prints **colorized results** and **summaries** to the console.

**Key features**
- ✅ Read-only (no changes made)
- ✅ Checks all ESXi hosts and **all VMs**
- ✅ Clear PASS/FAIL/INFO statuses with color
- ✅ Per-check results + summary by category + overall summary
- ✅ Works with PowerShell 5.1 or PowerShell 7+, PowerCLI 13+

---

## Requirements

- Windows PowerShell **5.1** or PowerShell **7+**
- **VMware.PowerCLI** (13.x recommended)

Install (current user scope recommended):

```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

---

First run may prompt about an untrusted repository; answer Y or configure:
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

If you have an existing older PowerCLI and hit a publisher mismatch, you can update with:
Install-Module VMware.PowerCLI -Scope CurrentUser -Force -SkipPublisherCheck

Note: -SkipPublisherCheck is optional; use it only if you understand the warning.

---

Usage

From the directory where the script is saved:
.\vmware-sec-assessment.ps1 -vCenter "vcsa.lab.local"

Parameters
- vCenter (string, required) — vCenter Server FQDN or IP.
There is no -VMName parameter. The script automatically evaluates all VMs in the connected vCenter.

Execution Policy (if needed)
If your system blocks script execution:
powershell -NoProfile -ExecutionPolicy Bypass -File .\vmware-sec-assessment.ps1 -vCenter "vcsa.lab.local"

---

What It Checks
1. Install (ESXi host software / patching)
* ESXi build/patch info (informational)
* VIB acceptance level is PartnerSupported or VMwareAccepted

2. Communication (ESXi host network services)
* NTP servers configured and ntpd running
* ESXi firewall default policy denies inbound by default
* Managed Object Browser (MOB) disabled
* SNMP configured properly (not public; informational if disabled)
* dvfilter bind IP not set
* vDS Health Check disabled

3. Logging (ESXi host logging/syslog)
* Centralized core dump configured (network)
* Persistent logging directory set (Syslog.global.logDir)
* Remote syslog target set (Syslog.global.logHost)

5. Console (ESXi console & shell services)
* DCUI timeout ≥ 600 seconds
* ESXi Shell service disabled
* SSH service disabled
* Shell/SSH idle timeouts configured
* Lockdown Mode enabled (Normal/Strict)

7. Network (vSwitch / vDS policy)
* Standard Portgroups (vSS): reject Promiscuous, MAC Changes, Forged Transmits; VLAN not 0/4095
* Distributed Portgroups (vDS): reject Promiscuous, MAC Changes, Forged Transmits; VLAN not 0/4095
* vDS NetFlow (Ipfix) — PASS if enabled, INFO if disabled

8. Virtual Machines (Guest VM configuration)
* Console copy/paste/drag&drop disabled
* Unauthorized device edit/connect disabled
* CD/DVD not connected or auto-connected at boot
* No floppy / serial / parallel devices
* Only one remote console connection allowed
* VNC console disabled (if setting present)
* Disk shrinking/wiping disabled
* VM logs: keepOld ≥ 10 (INFO/PASS), rotateSize ≤ 1MiB (INFO/PASS)
* Host info not exposed to guest
* Hardware 3D acceleration disabled

---

Example Output
Per-check lines (partial)

Category            Check                                   Object                      Status Details
--------            -----                                   ------                      ------ -------
1.Install           ESXi hosts properly patched (info)      esxi01.lab.local            INFO   Version=8.0.2 build 22380479
1.Install           VIB acceptance level is Partner/VMware  esxi01.lab.local            PASS   AcceptanceLevel=VMwareAccepted
2.Communication     NTP configured and running              esxi01.lab.local            FAIL   Servers=; Running=False
5.Console           SSH service disabled                    esxi01.lab.local            FAIL   Running=True
7.Network           Reject Promiscuous Mode (Std PG)        vSwitch0/VM Network         PASS   AllowPromiscuous=False
8.Virtual Machines  VM console copy disabled                app-01                      FAIL   isolation.tools.copy.disable=False

Summary by Category and Status

=== Summary by Category and Status ===
Category                                      Status                  Count
--------                                      ------                  -----
1.Install (ESXi host software / patching)     PASS                       1
1.Install (ESXi host software / patching)     INFO                       1
2.Communication (ESXi host network services)  PASS                       3
2.Communication (ESXi host network services)  FAIL                       1
3.Logging (ESXi host logging/syslog)          PASS                       2
5.Console (ESXi console & shell services)     FAIL                       1
7.Network (vSwitch / vDS networking policies) PASS                       6
8.Virtual Machines (Guest VM configuration)   FAIL                       5


Overall Summary

=== Overall Summary ===
Status                                Count
------                                -----
PASS (compliant)                         12
FAIL (requires remediation)               7
INFO (informational only)                 3

Colors: PASS = green, FAIL = red, INFO = cyan.

---

Notes

* Some environment-specific controls (e.g., certificate trust, AD password policies, SAN zoning) are not verifiable purely via PowerCLI and are intentionally excluded or reported as INFO when context is unknown.
* You can easily extend the script by adding new Check-* functions following the same pattern and appending them in the “Run all checks” section.

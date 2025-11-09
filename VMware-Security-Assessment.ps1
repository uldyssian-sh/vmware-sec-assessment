<#
================================================================================
 Name     : VMware-Security-Assessment.ps1
 Purpose  : Read-only vSphere 8 Security Assessment (PowerCLI).
            Implements a set of hardening/compliance checks for ESXi hosts,
            networking, logging, and VM settings. Prints colorized results.

 Author   : Paladin alias LT
 Version  : 1.2
 Target   : VMware vSphere 8

 DISCLAIMER
 ----------
 This script is provided "as is", without any warranty of any kind.
 Use it at your own risk. You are solely responsible for reviewing,
 testing, and implementing it in your own environment.

 NOTES
 -----
 - Read-only: This script DOES NOT change any configuration.
 - Output: Prints per-check results to the console and summaries at the end.
 - Requirements: PowerShell + VMware.PowerCLI (13.x recommended).
 - Scope: All ESXi hosts and ALL VMs in the connected vCenter.

 Run the script:
 .\VMware-Security-Assessment.ps1 -vCenter "vcsa.lab.local"
================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$vCenter
)

# ----------------------------- Prereqs (read-only) ---------------------------
$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name VMware.PowerCLI)) {
  throw "VMware.PowerCLI module is required. Install-Module VMware.PowerCLI"
}
Import-Module VMware.PowerCLI -ErrorAction Stop | Out-Null
Import-Module VMware.VimAutomation.Vds -ErrorAction SilentlyContinue | Out-Null
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

Write-Host "Connecting to vCenter: $vCenter ..." -ForegroundColor Cyan
$null = Connect-VIServer -Server $vCenter

# ----------------------------- Result collector -----------------------------
$global:Results = New-Object System.Collections.Generic.List[object]
function Add-Result {
  param(
    [string]$Category,   # e.g., 7.Network
    [string]$Check,      # control short name
    [string]$Object,     # host/pg/vds/vm
    [ValidateSet('PASS','FAIL','INFO','N/A')]
    [string]$Status,
    [string]$Details
  )
  $global:Results.Add([PSCustomObject]@{
    Category = $Category
    Check    = $Check
    Object   = $Object
    Status   = $Status
    Details  = $Details
  })
}

function BoolToStatus([bool]$b){ if($b){'PASS'}else{'FAIL'} }
function Try-Get { param([scriptblock]$Script) try { & $Script } catch { $null } }
function Get-AdvValue { param($Entity,[string]$Name) try{ (Get-AdvancedSetting -Entity $Entity -Name $Name -ErrorAction Stop).Value }catch{ $null } }
function BoolVal([object]$v){ try{ [bool]$v }catch{ $false } }

# ESXCLI acceptance level (compatible)
function Get-HostAcceptanceLevel {
  param([VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]$VMHost)
  try {
    $e2 = Get-EsxCli -VMHost $VMHost -V2
    ($e2.software.acceptance.get.Invoke()).AcceptanceLevel
  } catch {
    try { (Get-EsxCli -VMHost $VMHost).software.acceptance.get() } catch { $null }
  }
}

# =============================== Checks ======================================

# 1) Install / Host hygiene
function Check-ESXi-BuildInfo {
  $cat='1.Install'
  foreach($h in Get-VMHost){
    $detail = "Version=$($h.Version) build $($h.Build)"
    Add-Result $cat 'ESXi hosts properly patched (info)' $h.Name 'INFO' $detail
  }
}
function Check-Host-VIBAcceptance {
  $cat='1.Install'
  foreach($h in Get-VMHost){
    $al = Get-HostAcceptanceLevel -VMHost $h
    $status = BoolToStatus ($al -in @('PartnerSupported','VMwareAccepted'))
    Add-Result $cat 'VIB acceptance level is Partner/VMware' $h.Name $status "AcceptanceLevel=$al"
  }
}

# 2) Communication / Host services
function Check-NTP {
  $cat='2.Communication'
  foreach($h in Get-VMHost){
    $servers = Try-Get { Get-VMHostNtpServer -VMHost $h }
    $ntpSvc  = Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd'
    $ok = ($servers -and $servers.Count -gt 0 -and $ntpSvc -and $ntpSvc.Running)
    $status = BoolToStatus $ok
    $detail = "Servers=$(@($servers) -join ','); Running=$($ntpSvc.Running)"
    Add-Result $cat 'NTP configured and running' $h.Name $status $detail
  }
}
function Check-Firewall-DefaultPolicy {
  $cat='2.Communication'
  foreach($h in Get-VMHost){
    try{
      $pol = Get-VMHostFirewallDefaultPolicy -VMHost $h
      $status = BoolToStatus (-not $pol.AllowIncoming) # inbound deny by default
      $detail = "AllowIncoming=$($pol.AllowIncoming); AllowOutgoing=$($pol.AllowOutgoing)"
      Add-Result $cat 'ESXi firewall default policy (deny inbound)' $h.Name $status $detail
    }catch{
      Add-Result $cat 'ESXi firewall default policy (deny inbound)' $h.Name 'INFO' 'Policy not available'
    }
  }
}
function Check-MOB-Disabled {
  $cat='2.Communication'
  foreach($h in Get-VMHost){
    $v = Get-AdvValue $h 'Config.HostAgent.plugins.solo.enableMob'
    $status = BoolToStatus (-not (BoolVal $v))
    Add-Result $cat 'Managed Object Browser (MOB) disabled' $h.Name $status "enableMob=$v"
  }
}
function Check-SNMP {
  $cat='2.Communication'
  foreach($h in Get-VMHost){
    try{
      $snmp = Get-VMHostSnmp -VMHost $h
      $ok = $snmp.Enabled -and ($snmp.Community) -and ($snmp.Community -ne 'public')
      $status = if ($snmp.Enabled) { if ($ok) { 'PASS' } else { 'FAIL' } } else { 'INFO' }
      $detail = "Enabled=$($snmp.Enabled); Community=$($snmp.Community)"
      Add-Result $cat 'SNMP configured properly' $h.Name $status $detail
    }catch{
      Add-Result $cat 'SNMP configured properly' $h.Name 'INFO' 'SNMP state unavailable'
    }
  }
}
function Check-dvfilter-Disabled {
  $cat='2.Communication'
  foreach($h in Get-VMHost){
    $val = Get-AdvValue $h 'Net.DVFilterBindIpAddress'
    $status = BoolToStatus ([string]::IsNullOrEmpty($val))
    Add-Result $cat 'dvfilter binding disabled (no bind IP)' $h.Name $status "Net.DVFilterBindIpAddress='$val'"
  }
}
function Check-VDS-HealthCheck-Disabled {
  $cat='2.Communication'
  $vdss = Get-VDSwitch -ErrorAction SilentlyContinue
  if($vdss){
    foreach($vds in $vdss){
      try{
        $hc  = $vds.ExtensionData.Config.HealthCheckConfig
        $tm  = ($hc | Where-Object { $_.Enable -and $_.HealthCheckType -eq 'teamingHealthCheck' })
        $mtu = ($hc | Where-Object { $_.Enable -and $_.HealthCheckType -eq 'mtuHealthCheck' })
        $status = BoolToStatus (-not $tm -and -not $mtu)
        $detail = "TeamingHC=$([bool]$tm); MTUHC=$([bool]$mtu)"
        Add-Result $cat 'VDS health check disabled' $vds.Name $status $detail
      }catch{
        Add-Result $cat 'VDS health check disabled' $vds.Name 'INFO' 'Unable to read HealthCheckConfig'
      }
    }
  } else {
    Add-Result $cat 'VDS health check disabled' 'No-VDS' 'INFO' 'No VDSwitches found'
  }
}

# 3) Logging / Syslog & Core Dump
function Check-CoreDump {
  $cat='3.Logging'
  foreach($h in Get-VMHost){
    try{
      $cd = Get-VMHostNetworkCoreDump -VMHost $h
      $status = BoolToStatus ($cd.Enabled -and $cd.NetworkCoreDumpEnabled)
      $detail = "Enabled=$($cd.Enabled); NetEnabled=$($cd.NetworkCoreDumpEnabled); Server=$($cd.NetworkServerIpAddress)"
      Add-Result $cat 'Centralized ESXi core dump configured' $h.Name $status $detail
    }catch{
      Add-Result $cat 'Centralized ESXi core dump configured' $h.Name 'INFO' 'Core dump state not available'
    }
  }
}
function Check-Syslog-PersistentDir {
  $cat='3.Logging'
  foreach($h in Get-VMHost){
    $dir = Get-AdvValue $h 'Syslog.global.logDir'
    $status  = BoolToStatus (-not [string]::IsNullOrWhiteSpace($dir))
    Add-Result $cat 'Persistent logging configured' $h.Name $status "Syslog.global.logDir='$dir'"
  }
}
function Check-Syslog-RemoteHost {
  $cat='3.Logging'
  foreach($h in Get-VMHost){
    $logHost = Get-AdvValue $h 'Syslog.global.logHost'
    $status = BoolToStatus (-not [string]::IsNullOrWhiteSpace($logHost))
    Add-Result $cat 'Remote syslog configured' $h.Name $status "Syslog.global.logHost='$logHost'"
  }
}

# 5) Console / Local & remote shells
function Check-DCUI-Timeout {
  $cat='5.Console'
  foreach($h in Get-VMHost){
    $v = [int](Get-AdvValue $h 'UserVars.DcuiTimeOut')
    $status = BoolToStatus ($v -ge 600)
    Add-Result $cat 'DCUI timeout >= 600 sec' $h.Name $status "UserVars.DcuiTimeOut=$v"
  }
}
function Check-ESXiShell-Disabled {
  $cat='5.Console'
  foreach($h in Get-VMHost){
    $svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'TSM'
    $status = BoolToStatus ($svc -and -not $svc.Running)
    Add-Result $cat 'ESXi Shell service disabled' $h.Name $status "Running=$($svc.Running)"
  }
}
function Check-SSH-Disabled {
  $cat='5.Console'
  foreach($h in Get-VMHost){
    $svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'TSM-SSH'
    $status = BoolToStatus ($svc -and -not $svc.Running)
    Add-Result $cat 'SSH service disabled' $h.Name $status "Running=$($svc.Running)"
  }
}
function Check-Shell-SSH-Timeouts {
  $cat='5.Console'
  foreach($h in Get-VMHost){
    $sshTo  = [int](Get-AdvValue $h 'UserVars.SshClientAliveInterval')
    $esxiTo = [int](Get-AdvValue $h 'UserVars.ESXiShellInteractiveTimeOut')
    $status = BoolToStatus ($esxiTo -ge 600)
    $detail = "ESXiShellInteractiveTimeOut=$esxiTo; SshClientAliveInterval=$sshTo"
    Add-Result $cat 'Shell/SSH idle timeouts set' $h.Name $status $detail
  }
}
function Check-LockdownMode {
  $cat='5.Console'
  foreach($h in Get-VMHost){
    $mode = $h.ExtensionData.Config.LockdownMode
    $status = BoolToStatus ($mode -eq 'lockdownNormal' -or $mode -eq 'lockdownStrict')
    Add-Result $cat 'Lockdown mode enabled (Normal/Strict)' $h.Name $status "LockdownMode=$mode"
  }
}

# 7) Network / vSwitch & vDS policies
function Check-vSS-SecurityPolicies {
  $cat='7.Network'
  foreach($pg in Get-VirtualPortGroup -Standard -ErrorAction SilentlyContinue){
    $sp = $pg.ExtensionData.SecurityPolicy
    $status1 = BoolToStatus (-not $sp.AllowPromiscuous)
    Add-Result $cat 'Reject Promiscuous Mode (Std PG)' "$($pg.VirtualSwitch.Name)/$($pg.Name)" $status1 "AllowPromiscuous=$($sp.AllowPromiscuous)"
    $status2 = BoolToStatus (-not $sp.MacChanges)
    Add-Result $cat 'Reject MAC Address Changes (Std PG)' "$($pg.VirtualSwitch.Name)/$($pg.Name)" $status2 "MacChanges=$($sp.MacChanges)"
    $status3 = BoolToStatus (-not $sp.ForgedTransmits)
    Add-Result $cat 'Reject Forged Transmits (Std PG)' "$($pg.VirtualSwitch.Name)/$($pg.Name)" $status3 "ForgedTransmits=$($sp.ForgedTransmits)"
    $vid = $pg.VlanId
    $status4 = BoolToStatus ($vid -ne 0 -and $vid -ne 4095)
    Add-Result $cat 'VLAN not 0/4095 (Std PG)' "$($pg.VirtualSwitch.Name)/$($pg.Name)" $status4 "VLAN=$vid"
  }
}
function Check-vDS-SecurityPolicies {
  $cat='7.Network'
  foreach($pg in Get-VDPortgroup -ErrorAction SilentlyContinue){
    $cfg = $pg.ExtensionData.Config.DefaultPortConfig
    $sec = $cfg.SecurityPolicy
    $status1 = BoolToStatus (-not $sec.AllowPromiscuous.Value)
    Add-Result $cat 'Reject Promiscuous Mode (VDS PG)' "$($pg.VDSwitch.Name)/$($pg.Name)" $status1 "AllowPromiscuous=$($sec.AllowPromiscuous.Value)"
    $status2 = BoolToStatus (-not $sec.MacChanges.Value)
    Add-Result $cat 'Reject MAC Address Changes (VDS PG)' "$($pg.VDSwitch.Name)/$($pg.Name)" $status2 "MacChanges=$($sec.MacChanges.Value)"
    $status3 = BoolToStatus (-not $sec.ForgedTransmits.Value)
    Add-Result $cat 'Reject Forged Transmits (VDS PG)' "$($pg.VDSwitch.Name)/$($pg.Name)" $status3 "ForgedTransmits=$($sec.ForgedTransmits.Value)"
    $vlan = $cfg.Vlan; $vid = $vlan.VlanId
    $status4 = BoolToStatus ($vid -ne 0 -and $vid -ne 4095)
    Add-Result $cat 'VLAN not 0/4095 (VDS PG)' "$($pg.VDSwitch.Name)/$($pg.Name)" $status4 "VLAN=$vid"
  }
}
function Check-vDS-Netflow {
  $cat='7.Network'
  foreach($vds in Get-VDSwitch -ErrorAction SilentlyContinue){
    $nf = $vds.ExtensionData.Config.IpfixConfig
    $enabled = ($nf -and $nf.IpfixEnabled)
    $status = if ($enabled) { 'PASS' } else { 'INFO' }
    $detail = "IpfixEnabled=$($nf.IpfixEnabled); Collector=$($nf.CollectorIpAddress)"
    Add-Result $cat 'NetFlow configured (VDS)' $vds.Name $status $detail
  }
}

# 8) Virtual Machines / isolation & devices
function Check-VMs {
  $cat='8.Virtual Machines'
  $vms = @(Get-VM)
  foreach($vm in $vms){
    # Copy/Paste/Drag&Drop
    $copy  = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.copy.disable'  -ErrorAction SilentlyContinue
    $paste = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.paste.disable' -ErrorAction SilentlyContinue
    $dnd   = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.dnd.disable'   -ErrorAction SilentlyContinue
    $st1 = BoolToStatus ($copy  -and (BoolVal $copy.Value))
    $st2 = BoolToStatus ($paste -and (BoolVal $paste.Value))
    $st3 = BoolToStatus ($dnd   -and (BoolVal $dnd.Value))
    Add-Result $cat 'VM console copy disabled'      $vm.Name $st1 "isolation.tools.copy.disable=$($copy.Value)"
    Add-Result $cat 'VM console paste disabled'     $vm.Name $st2 "isolation.tools.paste.disable=$($paste.Value)"
    Add-Result $cat 'VM console drag&drop disabled' $vm.Name $st3 "isolation.tools.dnd.disable=$($dnd.Value)"

    # Device control
    $edit   = Get-AdvancedSetting -Entity $vm -Name 'isolation.device.edit.disable'         -ErrorAction SilentlyContinue
    $conn   = Get-AdvancedSetting -Entity $vm -Name 'isolation.device.connectable.disable'  -ErrorAction SilentlyContinue
    $st4 = BoolToStatus ($edit -and (BoolVal $edit.Value))
    $st5 = BoolToStatus ($conn -and (BoolVal $conn.Value))
    Add-Result $cat 'Unauthorized device edit disabled'    $vm.Name $st4 "isolation.device.edit.disable=$($edit.Value)"
    Add-Result $cat 'Unauthorized device connect disabled' $vm.Name $st5 "isolation.device.connectable.disable=$($conn.Value)"

    # Media & legacy devices
    $cds = $vm.ExtensionData.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualCdrom] }
    $badCd = $false
    foreach($cd in $cds){
      $now = [bool]$cd.ConnectionState.Connected
      $on  = [bool]($cd.Connectable.Connected -or $cd.Connectable.StartConnected)
      if($now -or $on){ $badCd = $true; break }
    }
    $st6 = BoolToStatus (-not $badCd)
    Add-Result $cat 'CD/DVD not connected/at boot' $vm.Name $st6 "AnyConnectedOrOnBoot=$badCd"

    $hasFloppy  = $vm.ExtensionData.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualFloppy] }
    $hasSerial  = $vm.ExtensionData.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualSerialPort] }
    $hasPar     = $vm.ExtensionData.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualParallelPort] }
    Add-Result $cat 'No floppy device' $vm.Name (BoolToStatus (-not $hasFloppy)) "FloppyPresent=$([bool]$hasFloppy)"
    Add-Result $cat 'No serial port'   $vm.Name (BoolToStatus (-not $hasSerial)) "SerialPresent=$([bool]$hasSerial)"
    Add-Result $cat 'No parallel port' $vm.Name (BoolToStatus (-not $hasPar))    "ParallelPresent=$([bool]$hasPar)"

    # Remote console & UI
    $maxCon = Get-AdvancedSetting -Entity $vm -Name 'RemoteDisplay.maxConnections' -ErrorAction SilentlyContinue
    $st7 = BoolToStatus ($maxCon -and $maxCon.Value -eq '1')
    Add-Result $cat 'Only one remote console connection' $vm.Name $st7 "RemoteDisplay.maxConnections=$($maxCon.Value)"
    $vncOn = Get-AdvancedSetting -Entity $vm -Name 'RemoteDisplay.vnc.enabled' -ErrorAction SilentlyContinue
    if($vncOn){
      $st8 = BoolToStatus (-not (BoolVal $vncOn.Value))
      Add-Result $cat 'VNC console disabled' $vm.Name $st8 "RemoteDisplay.vnc.enabled=$($vncOn.Value)"
    }

    # Disk operations & logging
    $shrink = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.diskShrink.disable' -ErrorAction SilentlyContinue
    $wipe   = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.diskWiper.disable'  -ErrorAction SilentlyContinue
    Add-Result $cat 'Virtual disk shrinking disabled' $vm.Name (BoolToStatus ($shrink -and (BoolVal $shrink.Value))) "isolation.tools.diskShrink.disable=$($shrink.Value)"
    Add-Result $cat 'Virtual disk wiping disabled'    $vm.Name (BoolToStatus ($wipe   -and (BoolVal $wipe.Value)))   "isolation.tools.diskWiper.disable=$($wipe.Value)"

    $keepOld = Get-AdvancedSetting -Entity $vm -Name 'log.keepOld'    -ErrorAction SilentlyContinue
    $rotSz   = Get-AdvancedSetting -Entity $vm -Name 'log.rotateSize' -ErrorAction SilentlyContinue
    if($keepOld){
      $statusKeep = if([int]$keepOld.Value -ge 10){'PASS'}else{'INFO'}
      Add-Result $cat 'VM logs keep >= 10 (info/pass)' $vm.Name $statusKeep "log.keepOld=$($keepOld.Value)"
    }
    if($rotSz){
      $statusRot = if([int]$rotSz.Value -le 1048576){'PASS'}else{'INFO'}
      Add-Result $cat 'VM log rotate size <= 1MiB (info/pass)' $vm.Name $statusRot "log.rotateSize=$($rotSz.Value)"
    }

    # Host info exposure
    $getHostInfo = Get-AdvancedSetting -Entity $vm -Name 'isolation.tools.getHostInfo.disable' -ErrorAction SilentlyContinue
    Add-Result $cat 'Host info not exposed to guest' $vm.Name (BoolToStatus ($getHostInfo -and (BoolVal $getHostInfo.Value))) "isolation.tools.getHostInfo.disable=$($getHostInfo.Value)"

    # 3D accel
    $svga = Get-AdvancedSetting -Entity $vm -Name 'mks.enable3d' -ErrorAction SilentlyContinue
    $status3d = BoolToStatus ((-not $svga) -or (-not (BoolVal $svga.Value)))
    Add-Result $cat 'Hardware 3D acceleration disabled' $vm.Name $status3d "mks.enable3d=$($svga.Value)"
  }
}

# ============================= Run all checks ================================
Check-ESXi-BuildInfo
Check-Host-VIBAcceptance
Check-NTP
Check-Firewall-DefaultPolicy
Check-MOB-Disabled
Check-SNMP
Check-dvfilter-Disabled
Check-VDS-HealthCheck-Disabled
Check-CoreDump
Check-Syslog-PersistentDir
Check-Syslog-RemoteHost
Check-DCUI-Timeout
Check-ESXiShell-Disabled
Check-SSH-Disabled
Check-Shell-SSH-Timeouts
Check-LockdownMode
Check-vSS-SecurityPolicies
Check-vDS-SecurityPolicies
Check-vDS-Netflow
Check-VMs

# ============================== Output & Colors ==============================
$wCat=13; $wCheck=40; $wObj=28; $wStatus=6

function ColorForStatus($s){
  switch ($s) {
    'PASS' { 'Green' }
    'FAIL' { 'Red' }
    'INFO' { 'Cyan' }
    'N/A'  { 'DarkGray' }
    default{ 'White' }
  }
}

Write-Host ""
Write-Host ("{0}  {1}  {2}  {3}  {4}" -f ('Category'.PadRight($wCat)) , ('Check'.PadRight($wCheck)), ('Object'.PadRight($wObj)), ('Status'.PadRight($wStatus)), 'Details') -ForegroundColor Yellow
Write-Host ("{0}" -f ('-'*($wCat+$wCheck+$wObj+$wStatus+6+8)))

$global:Results | Sort-Object Category, Check, Object | ForEach-Object {
  $color = ColorForStatus $_.Status
  $linePrefix = ("{0}  {1}  {2}  " -f ($_.Category.PadRight($wCat)), ($_.Check.PadRight($wCheck)), ($_.Object.PadRight($wObj)))
  Write-Host -NoNewline $linePrefix
  Write-Host -NoNewline ($_.Status.PadRight($wStatus)) -ForegroundColor $color
  Write-Host ("  {0}" -f $_.Details)
}

# ------------------------------- Summaries -----------------------------------
$summary = $global:Results | Group-Object Category, Status | ForEach-Object {
  [PSCustomObject]@{
    Category = $_.Group[0].Category
    Status   = $_.Group[0].Status
    Count    = $_.Count
  }
} | Sort-Object Category, Status

$categoryMap = @{
  '1.Install'           = '1.Install (ESXi host software / patching)'
  '2.Communication'     = '2.Communication (ESXi host network services)'
  '3.Logging'           = '3.Logging (ESXi host logging/syslog)'
  '4.Access'            = '4.Access (ESXi authentication & user mgmt)'
  '5.Console'           = '5.Console (ESXi console & shell services)'
  '6.Storage'           = '6.Storage (ESXi storage / iSCSI / SAN)'
  '7.Network'           = '7.Network (vSwitch / vDS networking policies)'
  '8.Virtual Machines'  = '8.Virtual Machines (Guest VM configuration)'
}

Write-Host ""
Write-Host "=== Summary by Category and Status ===" -ForegroundColor Yellow
Write-Host ("{0}  {1}  {2}" -f ('Category'.PadRight(48)), ('Status'.PadRight(22)), 'Count') -ForegroundColor Yellow
Write-Host ('-'*78)
foreach($row in $summary){
  $catLabel = $categoryMap[$row.Category]; if(-not $catLabel){ $catLabel = $row.Category }
  $color = ColorForStatus $row.Status
  Write-Host -NoNewline ($catLabel.PadRight(48) + '  ')
  Write-Host -NoNewline ($row.Status.PadRight(22)) -ForegroundColor $color
  Write-Host ('  ' + $row.Count)
}

$overall = $global:Results | Group-Object Status | ForEach-Object {
  [PSCustomObject]@{ Status = $_.Name; Count = $_.Count }
} | Sort-Object Status

$statusMap = @{
  'PASS'            = 'PASS (compliant)'
  'FAIL'            = 'FAIL (requires remediation)'
  'INFO'            = 'INFO (informational only)'
  'N/A'             = 'N/A'
}

Write-Host ""
Write-Host "=== Overall Summary ===" -ForegroundColor Yellow
Write-Host ("{0}  {1}" -f ('Status'.PadRight(32),'Count')) -ForegroundColor Yellow
Write-Host ('-'*44)
foreach($row in $overall){
  $label = $statusMap[$row.Status]; if(-not $label){ $label = $row.Status }
  $color = ColorForStatus $row.Status
  Write-Host -NoNewline ($label.PadRight(32) + '  ')
  Write-Host $row.Count -ForegroundColor $color
}
# Updated 20251109_123821

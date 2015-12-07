<#
.SYNOPSIS
    Maintenance script for taking a VMware View ESXi Host (with desktop VMs on local data store) into maintenance mode.
    This script could be scheduled at night (after the scheduled refresh that takes place) for the host you want to set
    in maintenance mode.
    CAUTION: Script does not modify provisioning or number of provisioned desktops. All desktops on Host in Maintenance will not be accessible.
    The composer will continually try to start these VMs
.VERSION 
    1.3
.AUTHOR 
    Bart Tacken - Client ICT Groep
.PREREQUISITES
       Must be run on View Connection Server that must contain:
       PowerShell v3 (default on Server 2012, compatible with Server 2008(R2))
       VMware View PowerCLI Snapin (default on View Broker)
       VMware vSphere PowerCLI Snapin (download PowerCLI from My VMware)
.EXAMPLE
    Script must be run from a View connection broker with following parameters:
    .\Set-VMwareViewMaintenance.ps1 -VMwareViewHost <FQDN of host in maintenance> -vCenter <FQDN vCenter VMware View> 
 #>
 
Param(
    [Parameter(Position=0,
    Mandatory=$True)
    ]
    [String]$VMwareViewHost,
    
    [Parameter(Position=1,
    Mandatory=$True)
    ]
    [String]$vCenter    
)

Start-Transcript -Path C:\Windows\Temp\Set-VMwareViewMaintenance.log -Force

Write-Host "Loading View Broker PowerCLI" -ForegroundColor Green
    Add-PSSnapin VMware.View.Broker

Write-Host "Loading vSphere PowerCLI" -ForegroundColor Green
    Add-PSSnapin VMware.VimAutomation.Core

Write-Host "Connecting to vCenter $vCenter" -ForegroundColor Green
    Connect-VIserver $vCenter -Force 
    Start-Sleep 5

Write-Host "Get Overview of PoweredOn VMs on $VMWareViewHost" -ForegroundColor Green
    $VMobj = Get-VM | Where-Object { ($_.VMHost -like $VMwareViewHost) -and ($_.PowerState -eq 'PoweredOn') }
    $VMstr = $VMobj | Select-Object -ExpandProperty Name

    $VMobj | Select-Object Name,Host,Powerstate # Log VMs to transcript

Write-Host "Put Host in Maintenance mode" -ForegroundColor Green
    Set-VMhost $VMwareViewHost -State Maintenance -runAsync:$True # Process maintenance task in background while allowing to run more commands. 
         
Write-Host "Shutdown PoweredOn VMs on Host $VMwareViewHost"
    #Stop-VM -VM $vmstr -Confirm:$False #
    Get-VMguest $VMstr | Stop-VMGuest -Confirm:$False -Verbose # Use Shutdown-VMGuest in older versions than PowerCLI 6 R1
  
Stop-Transcript
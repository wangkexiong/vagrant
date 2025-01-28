param (
    [string]$vmid
)

if (-not (Get-VMSwitch -Name "Private" -ErrorAction SilentlyContinue)) {
  $scriptPath = "hyperv-create_private_network.ps1"
  $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptPath
  $process = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -WindowStyle Hidden -Wait -PassThru

  $exitCode = $process.ExitCode

  if (-not ($exitCode -eq 0)) {
    exit $exitCode
  }
  Write-Host "VM-Switch Private from Internal type is created"
}

$vmname = (Get-VM -Id $vmid).Name
$count = (Get-VMNetworkAdapter -VMName $vmname | Measure-Object).count
if ($count -lt 2) {
  Write-Host "Adding a new network adapter to VM $vmname with SwitchName Private"
  Add-VMNetworkAdapter -VMName $vmname -SwitchName "Private" -Name "Private"
} else {
  $net=Get-VMNetworkAdapter -VMName $vmname
  if ($net[1].name -eq "Private") {
    Write-Host "Ensure NetworkAdapter with SwitchName Private"
    $net[1] | Connect-VMNetworkAdapter -SwitchName "Private"
  }
}


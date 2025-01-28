
New-VMSwitch -Name Private -SwitchType Internal
$vmAdapter = Get-NetAdapter | Where-Object {$_.Name -ilike "*(Private)*"}
New-NetIPAddress -InterfaceAlias $vmAdapter.Name -IPAddress "192.168.56.1" -PrefixLength 24


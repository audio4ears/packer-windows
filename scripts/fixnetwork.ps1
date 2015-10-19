#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

# query system for version and domainrole
$ver = [environment]::OSVersion.Version;
$wmiCS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName .;

# set network location to private
write-host "==> Setting Public Network Connection Locations to Private";
if ( ($ver.Major -ge 6) -and (1,3,4,5 -notcontains $wmiCS.DomainRole) ) {
  $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"));
  $networkConnections = $networkListManager.GetNetworkConnections();
  $networkConnections | foreach {
    if ($_.GetNetwork().GetCategory() -eq 0) {    
      $_.GetNetwork().SetCategory(1);
    }
  }
}

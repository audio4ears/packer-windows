#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

$puppet_guid = "C3356EDD117AC6A4D911B175C4A305CF";
$puppetx86_url = "https://downloads.puppetlabs.com/windows/puppet-3.8.3.msi"
$puppetx64_url = "https://downloads.puppetlabs.com/windows/puppet-3.8.3-x64.msi"


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

# ----- INSTALL CHEF CLIENT -----

if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$puppet_guid")) {

  # install Puppet
  write-host "==> Installing Puppet";
  $puppet_url = $puppetx86_url;
  if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64") {
      $puppet_url = $puppetx64_url;
  }
  $puppet_bin = $puppet_url.Split('/')[-1];
  if (!(Test-Path -Path "$env:windir\Temp\$puppet_bin")) {
      $request = New-Object System.Net.WebClient;
      $out = "$env:windir\Temp\$puppet_bin";
      $request.DownloadFile($puppet_url, $out);
  }
  $msi = "$env:windir\Temp\$puppet_bin";
  $arguments = @("/qn", "/i", $msi,"/log $env:windir/Temp/puppet.log");
  Start-Process -FilePath msiexec.exe `
                  -ArgumentList $arguments `
                  -Wait `
                  -PassThru;
}

#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

$chef_url = "https://www.chef.io/chef/install.msi";
$chef_guid = "1945256682812F8459C51AA05AD1CF7D";


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------


# ----- INSTALL CHEF CLIENT -----

if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$chef_guid")) {

  # download chef client
  if (!(Test-Path -Path "$env:windir\Temp\chef.msi")) {
      write-host "==> Downloading Chef Client";
      $request = New-Object System.Net.WebClient;
      $out = "$env:windir\Temp\chef.msi";
      $request.DownloadFile($chef_url, $out);
  }

  # install chef client
  write-host "==> Installing Chef Client";
  $msi = "$env:windir\Temp\chef.msi";
  $arguments = @("/qb", "/i", $msi);
  Start-Process -FilePath msiexec.exe `
                  -ArgumentList $arguments `
                  -Wait `
                  -PassThru;
}

#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

$salt_guid = "CF864B68-9E8A-46A5-BFD7-9CB50F993311";
$saltx86_url = "https://repo.saltstack.com/windows/Salt-Minion-2015.8.1-x86-Setup.exe"
$saltx64_url = "https://repo.saltstack.com/windows/Salt-Minion-2015.8.1-AMD64-Setup.exe"


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

# ----- INSTALL SALT CLIENT -----

if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$salt_guid")) {

  # install Salt
  write-host "==> Installing Salt";
  $salt_url = $saltx86_url;
  if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64") {
      $salt_url = $saltx64_url;
  }
  $salt_bin = $salt_url.Split('/')[-1];
  if (!(Test-Path -Path "$env:windir\Temp\$salt_bin")) {
      $request = New-Object System.Net.WebClient;
      $out = "$env:windir\Temp\$salt_bin";
      $request.DownloadFile($salt_url, $out);
  }
  if (!(Test-Path -Path "$env:windir\Temp\$salt_bin")) {
      $exe = "$env:windir\Temp\$salt_bin";
      &$exe /S;
  }
}

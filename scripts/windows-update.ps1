#------------------------------------------------------------------------------
# Function: Print-Report
#------------------------------------------------------------------------------
Function Print-Report ($report) {
  # build table filter
  $a = @{Expression={$_.ComputerName};Label="ComputerName";Align="Left";}, `
       @{Expression={$_.Status};Label="Status";Align="Left";}, `
       @{Expression={$_.KB};Label="KB";Align="Left";}, `
       @{Expression={$_.Size};Label="Size";Align="Right";}, `
       @{Expression={$_.Title};Label="Title";Align="Left";};

  # display array in table
  $report | Sort-Object -Property "MaxDownloadSize" | Format-Table $a -AutoSize;
}


#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

$WindowsUpdate = $false;
$MicrosoftUpdate = $true;
$Search = "IsInstalled = 0 and Type = 'Software'";
$Category = @("Critical Updates","Security Updates");
$AutoReboot = $false;
$IgnoreReboot = $true;


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

write-host "==> Installing Windows Updates" -ForegroundColor Green;


# ----- SCRIPT PREREQUSITES -----

# check for pre-existing reboot requirement
$objSystemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo";
If($objSystemInfo.RebootRequired) {
  Write-Warning "==> System Reboot is required before continuing";
  Return;
}


# ----- GET WINDOWS UPDATE LOCATION -----

# create searcher com object
$objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager";
$objSession = New-Object -ComObject "Microsoft.Update.Session";
$objSearcher = $objSession.CreateUpdateSearcher();

# update searcher object with windows update source
If($WindowsUpdate) {
  $objSearcher.ServerSelection = 2;
  $serviceName = "Windows Update";
}
ElseIf($MicrosoftUpdate) {
  $serviceName = $null;
  Foreach ($objService in $objServiceManager.Services) {
    If ($objService.Name -eq "Microsoft Update") {
      $objSearcher.ServerSelection = 3;
      $objSearcher.ServiceID = $objService.ServiceID;
      $serviceName = $objService.Name;
      Break;
    }
  }
  If(-not $serviceName) {
    Write-Warning "==> Can't find registered service Microsoft Update.";
    Return;
  }
}
Else {
  Foreach ($objService in $objServiceManager.Services) {
    If($objService.IsDefaultAUService -eq $True) {
      $serviceName = $objService.Name;
      Break;
    }
  }
}


# ----- SEARCH FOR WINDOWS UPDATES -----

# search update source for available updates
Write-Host "==> Searching $serviceName for available updates";
$objResults = $objSearcher.Search($search);


# filter available updates based on search criteria
Write-Host "==> Filtering search results";
$objCollectionUpdate = New-Object -ComObject "Microsoft.Update.UpdateColl";
$NumberOfUpdate = 1;
$UpdateCollection = @();
$PreFoundUpdatesToDownload = $objResults.Updates.count;
Foreach($Update in $objResults.Updates) {
  $UpdateAccess = $true;

  # write progress to screen
  Write-Progress -Activity "Searching for Updates:" `
    -Status "[$NumberOfUpdate/$PreFoundUpdatesToDownload] $($Update.Title)" `
    -PercentComplete ([int]($NumberOfUpdate/$PreFoundUpdatesToDownload * 100));

  # filter updates by category
  $UpdateCategories = $Update.Categories | Select-Object Name;
  Foreach($Cat in $Category) {
    If(!($UpdateCategories -match $Cat)) {
      $UpdateAccess = $false;
    }
    Else {
      $UpdateAccess = $true;
      Break;
    }
  }

  # gather and catalog update data for future use
  If($UpdateAccess -eq $true) {

    # collect file size and normalize
    Switch($Update.MaxDownloadSize) {
      {[System.Math]::Round($_/1KB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1KB,0))+" KB"; break }
      {[System.Math]::Round($_/1MB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1MB,0))+" MB"; break } 
      {[System.Math]::Round($_/1GB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1GB,0))+" GB"; break }
      {[System.Math]::Round($_/1TB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1TB,0))+" TB"; break }
      default { $size = $_+"B" }
    }

    # collect kb article
    If ($Update.KBArticleIDs -ne "") {
      $KB = "KB"+$Update.KBArticleIDs;
    }
    else {
      $KB = "";
    }

    # collect installation status
    $Status = "";
    If($Update.IsDownloaded)    {$Status += "D"} else {$status += "-"};
    If($Update.IsInstalled)     {$Status += "I"} else {$status += "-"};
    If($Update.IsMandatory)     {$Status += "M"} else {$status += "-"};
    If($Update.IsHidden)        {$Status += "H"} else {$status += "-"};
    If($Update.IsUninstallable) {$Status += "U"} else {$status += "-"};
    If($Update.IsBeta)          {$Status += "B"} else {$status += "-"};

    # catalog data:COMPUTERNAME
    Add-Member -InputObject $Update -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME;
    Add-Member -InputObject $Update -MemberType NoteProperty -Name KB -Value $KB;
    Add-Member -InputObject $Update -MemberType NoteProperty -Name Size -Value $size;
    Add-Member -InputObject $Update -MemberType NoteProperty -Name Status -Value $Status;
    Add-Member -InputObject $Update -MemberType NoteProperty -Name X -Value 1;
    $Update.PSTypeNames.Clear();
    $Update.PSTypeNames.Add('PSWindowsUpdate.WUInstall');
    $UpdateCollection += $Update;
    $objCollectionUpdate.Add($Update) | Out-Null;
  }
  $NumberOfUpdate++;
}


# ----- DOWNLOAD WINDOWS UPDATES -----

# download desired updates
if ($objCollectionUpdate.Count -ge 1 ) {

  # print updates to be downloaded and installed to screen
  Write-Host "==> The following updates will be downloaded and installed:";
  Print-Report $UpdateCollection;

  # accept update licensing before downloading
  $objCollectionChoose = New-Object -ComObject "Microsoft.Update.UpdateColl";
  Foreach($Update in $objCollectionUpdate) {
    $Status = "Accepted";
    If($Update.EulaAccepted -eq 0) {
      $Update.AcceptEula()
    }
    $objCollectionChoose.Add($Update) | Out-Null;
  }

  # download updates
  Write-Host "==> Downloading updates";
  $NumberOfUpdate = 1;
  $objCollectionDownload = New-Object -ComObject "Microsoft.Update.UpdateColl";
  $UpdatesToDownload = $objCollectionChoose.count;
  Foreach($Update in $objCollectionChoose) {

    # write progress to screen
    Write-Progress -Activity "Downloading Updates:" `
      -Status "[$NumberOfUpdate/$UpdatesToDownload] $($Update.Title) $($Update.Size)" `
      -PercentComplete ([int]($NumberOfUpdate/$UpdatesToDownload * 100));

    # create downloader
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl";
    $objCollectionTmp.Add($Update) | Out-Null;
    $Downloader = $objSession.CreateUpdateDownloader();
    $Downloader.Updates = $objCollectionTmp;

    # download update
    Try {
      $DownloadResult = $Downloader.Download();
    }
    Catch {
      If($_ -match "HRESULT: 0x80240044") {
        Write-Warning "==> Your security policy don't allow a non-administator identity to perform this task";
        Return
      }
    }

    # test download for completion
    If($DownloadResult.ResultCode -eq 2) {
      $objCollectionDownload.Add($Update) | Out-Null;
    }
    $NumberOfUpdate++;
  }


  # ----- INSTALL WINDOWS UPDATES -----

  # install downloaded updates
  Write-Host "==> Installing Updates";
  $NeedsReboot = $false;
  $NumberOfUpdate = 1;
  $ReadyUpdatesToInstall = $objCollectionDownload.count;
  Foreach($Update in $objCollectionDownload) {

    # write progesss to screen
    Write-Progress -Activity "Installing Updates:" `
      -Status "[$NumberOfUpdate/$ReadyUpdatesToInstall] $($Update.Title)" `
      -PercentComplete ([int]($NumberOfUpdate/$ReadyUpdatesToInstall * 100));

    # create installer
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl";
    $objCollectionTmp.Add($Update) | Out-Null;
    $objInstaller = $objSession.CreateUpdateInstaller();
    $objInstaller.Updates = $objCollectionTmp;

    # install update
    Try {
      $InstallResult = $objInstaller.Install();
    }
    Catch {
      If($_ -match "HRESULT: 0x80240044") {
        Write-Warning "==> Your security policy don't allow a non-administator identity to perform this task";
      }
      Return;
    }

    # check if installation requires a reboot
    If(!$NeedsReboot) { 
      $NeedsReboot = $installResult.RebootRequired;
    }
    $NumberOfUpdate++;
  }


  # ----- HANDLE REBOOT REQUIREMENTS -----

  # installation is complete. handle reboot accordingly
  Write-Progress -Activity "Installing Updates" -Status "Completed" -Completed;
  If($NeedsReboot) {
    If($AutoReboot) {
      Restart-Computer -Force;
    }
    ElseIf($IgnoreReboot) {
      Return "==> Reboot is required, but has been suppressed.";
    }
    Else {
      $Reboot = Read-Host "Reboot is required. Do it now ? [Y/N]";
      If($Reboot -eq "Y") {
        Restart-Computer -Force;
      }
    }
  }
}
else {
  # exit if updates are not needed
  Write-Host -ForegroundColor Green "==> OK - No updates needed at this time.";
}

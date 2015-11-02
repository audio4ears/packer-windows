# Windows Templates for Packer

### Introduction

This repository contains [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/) templates that can be used to create Windows Virtual Machines for use with [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [VMWare Fusion](https://www.vmware.com/products/fusion). By default, the templates provided are configured to use Windows 180 day evaluation licenses but can be modified to use MDT, MSDN, or Microsoft Volume Licenses instead.

### Requirements

- [Packer](https://github.com/mitchellh/packer/blob/master/CHANGELOG.md) `0.8.0` or greater is required.
- [Vagrant](https://www.vagrantup.com/) `1.7.0` or greater is requried

### Available Windows Versions

The following Windows versions are known to work (built with VMware Fusion 8.0.0 and VirtualBox 5.0.6):

 * Windows 8.1
 * Windows 2012 R2
 * Windows 2012 R2 Core

## Usage

To build a Windows Server 2012 R2 Standard Vagrant box for VirtualBox:

#### VirtualBox

| OS | Command |
|----|---------|
| Windows 8.1 x64 Professional | ``` $ packer build --only=virtualbox-iso win81x64-pro.json ```
| Windows Server 2012 R2 Standard | ``` $ packer build --only=virtualbox-iso win2012r2-std.json ``` |
| Windows Server 2012 R2 Standard Core | ``` $ packer build --only=virtualbox-iso win2012r2-std-core.json ``` |

#### VMware Fusion

| OS | Command |
|----|---------|
| Windows 8.1 x64 Professional | ``` $ packer build --only=vmware-iso win81x64-pro.json ```
| Windows Server 2012 R2 Standard | ``` $ packer build --only=vmware-iso win2012r2-std.json ``` |
| Windows Server 2012 R2 Standard Core | ``` $ packer build --only=vmware-iso win2012r2-std-core.json ``` |

## Customizations

#### Modify Windows Edition

All Windows Server versions are defaulted to the Server Standard edition. You can modify this by editing the Autounattend.xml & Unattend.xml answerfiles, changing the `ImageInstall`>`OSImage`>`InstallFrom`>`MetaData`>`Value` element (e.g. to Windows Server 2012 R2 SERVERDATACENTER).

#### Update Product Key

The `Autounattend.xml` and `Unattend.xml` files are configured to work correctly with trial ISOs (which will be downloaded and cached for you the first time you perform a `packer build`). If you would like to use retail or volume license ISOs, you need to update the `UserData`>`ProductKey` element as follows:

* Uncomment the `<Key>...</Key>` element
* Insert your product key into the `Key` element

If you are going to configure your VM as a KMS client, you can use the product keys at http://technet.microsoft.com/en-us/library/jj612867.aspx. These are the default values used in the `Key` element.

#### Update Installation ISO

For all editions provided, you have 10 days to complete online activation, at which point the evaluation period begins and runs for 180 days. During the evaluation period, a notification on the Desktop displays the days remaining the evaluation period.

Alternatively – if you have access to [MSDN](http://msdn.microsoft.com) or [TechNet](http://technet.microsoft.com/) – you can download retail or volume license ISO images and place them in the `iso` directory. If you do, you should update the relevent `.json` file, setting `iso_url` to `./iso/<path to your iso>.iso` and `iso_checksum` to `<the md5 of your iso>`. For example, to use the Windows 2008 R2 (With SP1) retail ISO:

1. Download the Windows Server 2012 R2 (x64) - DVD (English) ISO (`en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso`)
2. Verify that `en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso` has an MD5 hash of `78bff6565f178ed08ab534397fe44845`
3. Clone this repo to a local directory
4. Move `en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso` to the `iso` directory
5. Update `win2012r2-std.json`, setting `iso_url` to `./iso/en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso`
6. Update `win2012r2-std.json`, setting `iso_checksum` to `78bff6565f178ed08ab534397fe44845`
7. Run `packer build win2012r2-std.json`

#### Disable Windows Updates

The scripts in this repo will install all Windows updates – by default – during Windows Setup. This is a _very_ time consuming process, depending on the age of the OS and the quantity of updates released since the last service pack. You might want to do yourself a favor during development and disable this functionality, by commenting out the `WITH WINDOWS UPDATES` section and uncommenting the `WITHOUT WINDOWS UPDATES` section in `Autounattend.xml`:

```xml
<FirstLogonCommands>
    <SynchronousCommand wcm:action="add">
        <CommandLine>cmd.exe /c wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE</CommandLine>
        <Order>1</Order>
        <Description>Disable password expiration for Administrator user</Description>
    </SynchronousCommand>
    <!-- WITH WINDOWS UPDATES -->
    <!--
    <SynchronousCommand wcm:action="add">
        <CommandLine>powershell.exe -NoLogo -ExecutionPolicy Bypass -File A:\enable-microsoft-update.ps1</CommandLine>
        <Order>98</Order>
        <Description>Enable Microsoft Updates</Description>
    </SynchronousCommand>
    <SynchronousCommand wcm:action="add">
        <CommandLine>powershell.exe -NoLogo -ExecutionPolicy Bypass -File A:\update-windows.ps1</CommandLine>
        <Description>Install Windows Updates</Description>
        <Order>99</Order>
        <RequiresUserInput>true</RequiresUserInput>
    </SynchronousCommand>
    -->
    <!-- END WITH WINDOWS UPDATES -->
    <SynchronousCommand wcm:action="add">
        <CommandLine>powershell.exe -NoLogo -ExecutionPolicy Bypass -File A:\enable-winrm.ps1</CommandLine>
        <Description>Install WinRM</Description>
        <Order>100</Order>
        <RequiresUserInput>true</RequiresUserInput>
    </SynchronousCommand>
</FirstLogonCommands>
```

### Using .box Files With Vagrant

The generated box files include a Vagrantfile template that is suitable for
use with Vagrant 1.6.2+, which includes native support for Windows and uses
WinRM to communicate with the box.

### Acknowledgements

[CloudBees](http://www.cloudbees.com) is providing a hosted [Jenkins](http://jenkins-ci.org/) master through their CloudBees FOSS program. We also use their [On-Premise Executor](https://developer.cloudbees.com/bin/view/DEV/On-Premise+Executors) feature to connect a physical [Mac Mini Server](http://www.apple.com/mac-mini/server/) running VMware Fusion.

![Powered By CloudBees](http://www.cloudbees.com/sites/default/files/Button-Powered-by-CB.png "Powered By CloudBees")![Built On DEV@Cloud](http://www.cloudbees.com/sites/default/files/Button-Built-on-CB-1.png "Built On DEV@Cloud")

# Packer Windows

### Introduction

This repository contains [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/) templates that can be used to create Windows Virtual Machines for use with [VirtualBox](https://www.virtualbox.org/wiki/Downloads). By default, boxes built with these templates are configured with the following features:

- 180 day Windows Evaluation License
- Current Windows Updates installed
- Chef/Puppet Clients installed
- WinRM configured and running
- Windows Remote Desktop Enabled
- Image is syspreped


### What you need

- [packer](https://github.com/mitchellh/packer/blob/master/CHANGELOG.md) ~> `0.8.0`
- [vagrant](https://www.vagrantup.com/) ~> `1.7.0`
- [virtualbox](https://www.virtualbox.org/wiki/Downloads) ~> `5.0.0`


## Step 1: Build a box with Packer

To build a box, execute the Packer command that corresponds to your desired version of Windows from the list below. Please note that this process may take awhile. Once complete the resulting box will be saved to the `box/` directory within this project.

```bash
# Windows 8.1 x64 Enterprise
$ packer build --only=virtualbox-iso win81x64-ent.json
```

```bash
# Windows Server 2012 R2 Standard
$ packer build --only=virtualbox-iso win2012r2-std.json
```

```bash
# Windows Server 2012 R2 Standard Core
$ packer build --only=virtualbox-iso win2012r2-std-core.json
```

## Step 2: Initialize the box in Vagrant

Based on the Windows Version selected above in `Step 1`, locate and execute the corresponding Vagrant command to initialize the box in Vagrant.

```bash
# Windows 8.1 x64 Enterprise
$ vagrant init win81x64-ent box/virtualbox/win81x64-ent.box
```

```bash
# Windows Server 2012 R2 Standard
$ vagrant init win2012r2-std box/virtualbox/win2012r2-std.box
```

```bash
# Windows Server 2012 R2 Standard Core
$ vagrant init win2012r2-std-core box/virtualbox/win2012r2-std-core.box
```

## Step 3: Run the box in VirtualBox

The command below will start the box in VirtualBox. By default this box will run headless, meaning it runs without a display window. To connect to the box via command line use `WinRM` natively in Windows or the [WinRM Ruby Gem](https://github.com/WinRb/WinRM) in OSX & Linux.

```bash
$ vagrant up
```

## Customizing

By Customizing this build you can create vagrant boxes with alternative Windows versions, licensing models, and even align the build for Business use. To do so, please read the [README-CUSTOMIZE.md](https://github.com/audio4ears/packer-windows/blob/master/README-CUSTOMIZE.md) file for further instructions.

### Acknowledgements

 [joefitzgerald/packer-windows](https://github.com/joefitzgerald/packer-windows): Originally this Project started out as a fork of the packer-windows project and its sole purpose was to update the SSH communicator to WinRM. As development progressed, additional features were added, scripts and configuration files were rewritten, and eventually the drift was so great that the decision was made to develop the project in parallel.

# OCI-VM-Stop-Start

[VIDEO - installation and usage in 1.5 min](https://youtu.be/KrX6uj5cXVw)

- Quick and easy way to start/stop OCI VMs
- All you need is to run the command and enter the number of the VM, from a list.
- All the script does is to start the VM if it's stopped. And vice-versa.
- Without the need to go to the Console or enter the whole CLI command line.
- Mostly for lab instances you don't need to be running all the time.

- There is also an option to stopped all of the VMs at the same time. Something you might want to run at the end of your day, for example.

**Requirements**
- Bash shell
- OCI CLI installed and configured for your OCI account
- jq package. Usually installed.
- git client (Optional, you might as well just download the script)

**New features to be considered**
- Support for multiple regions (which will take longer to run but...)

**Setup instructions**
- Steps for OCI command line insterface are available here:
https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm 
- Download (or clone via git) vm.sh
- It's not necessary but, given the whole idea is to be quick, you my want to create a symbolic link, from a folder that is in tha $PATH, with a short name. For example, if you downloaded the file to /home/opc:
- $ sudo ln -s ~/instances.sh /usr/local/bin/vm
- Make sure it's executable. (chmod u+x <file>)

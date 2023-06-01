The script checks the host machine and vagrant VM machine for the presence of sgx_enclave and isgx drivers. If both drivers are detected, it runs a uninstallation process on the host and VM, including checking the AESM service status and stopping it if necessary. The script removes the kernel module, deletes relevant files, and cleans up the isgx driver installation on the host machine nad VM machine

To execute the script:

Clone the repository.
Navigate to the directory by running the command: cd isgx/
Run the script with root privileges using the command: sudo /bin/bash check.sh
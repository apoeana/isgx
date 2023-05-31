#!/bin/bash

if test $(id -u) -ne 0; then
    echo "Root privilege is required."
    exit 1
fi

echo "Checking Vagrant VM..."
vagrant_dir=$(sudo vagrant global-status | grep running | awk '{print $5}')
if [ -z "$vagrant_dir" ]; then
    echo "No running Vagrant environment found."
else
    echo "Running uninstall script on the Vagrant VM..."

    cd "$vagrant_dir"
    if sudo vagrant ssh -c "
        # Start of uninstall script on the Vagrant VM
        if [ -c /dev/sgx_enclave ] && [ -c /dev/isgx ]; then
            echo 'Both sgx_enclave and isgx are present on the Vagrant VM.'
            echo 'Running uninstall script on the Vagrant VM...'

            # Check if the AESM service is running
            if sudo service aesmd status | grep 'Active: active (running)'; then
                echo -e 'Uninstall failed on the Vagrant VM!'
                echo -e '\nPlease stop the AESM service and uninstall the PSW package first on the Vagrant VM'
                exit 1
            fi

            # Removing the kernel module if it is inserted
            sudo modinfo isgx &> /dev/null
            if [[ $? == '0' ]]; then
                sudo modprobe -r isgx
                if [[ $? != '0' ]]; then
                    echo -e '\nUninstall failed on the Vagrant VM because the kernel module is in use'
                    exit 1
                fi
            fi

            # Removing the .ko file
            sudo rm -f /lib/modules/5.15.0-71-generic/kernel/drivers/intel/sgx/isgx.ko

            # Removing from depmod
            sudo depmod

            # Removing from /etc/modules
            sudo sed -i '/^isgx$/d' /etc/modules

            sudo rm -f /etc/sysconfig/modules/isgx.modules
            sudo rm -f /etc/modules-load.d/isgx.conf

            # Removing the current folder
            sudo rm -fr /opt/intel/sgxdriver

            echo 'Uninstall script executed successfully on the Vagrant VM.'
        else
            echo 'Both sgx_enclave and isgx are not present on the Vagrant VM.'
            echo 'Nothing to uninstall on the Vagrant VM.'
        fi
    "; then
        echo "Uninstall script executed successfully on the Vagrant VM."
    else
        echo "Uninstall script execution failed on the Vagrant VM."
    fi
fi

echo "Checking host for sgx_enclave and isgx..."
if [ -c /dev/sgx_enclave ] && [ -c /dev/isgx ]; then
    echo "Both sgx_enclave and isgx are present on the host."
    echo "Running uninstall script on the host..."

    # Do not uninstall if the AESM service exists
    sudo service aesmd reload &> /dev/null
    if [[ $? == "0" ]]; then
        echo -e "Uninstall failed on the host!"
        echo -e "\nPlease uninstall the PSW package first"
        exit 1
    fi

    # Removing the kernel module if it is inserted
    sudo modinfo isgx &> /dev/null
    if [[ $? == "0" ]]; then
        sudo modprobe -r isgx
        if [[ $? != "0" ]]; then
            echo -e "\nUninstall failed on the host because the kernel module is in use"
            exit 1
        fi
    fi

    # Removing the .ko file
    sudo rm -f /lib/modules/5.15.0-71-generic/kernel/drivers/intel/sgx/isgx.ko

    # Removing from depmod
    sudo depmod

    # Removing from /etc/modules
    sudo sed -i '/^isgx$/d' /etc/modules

    sudo rm -f /etc/sysconfig/modules/isgx.modules
    sudo rm -f /etc/modules-load.d/isgx.conf

    # Removing the current folder
    sudo rm -fr /opt/intel/sgxdriver

    echo "Uninstall script executed successfully on the host."
else
    echo "Both sgx_enclave and isgx are not present on the host."
    echo "Nothing to uninstall on the host."
fi

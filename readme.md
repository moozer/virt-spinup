virt-spinup
===========

Script to spin up virtual machines on a kvm remote host.

We put a spinup script on the virtualization host, which clones a VM, resets password and sets hotsname. See [spinupmachine.sh](spinupmachine.sh) for details.

To use it we have a script in the client machine that activates the remote script, start the new host, wait for it to come online and does the necesary handling of SSH key.

After it has been spun up, it will be be accessible using keys, and an appropriate entry in `known_hosts`.	

Installation
----------------

Requirements:
* Root acces on the kvm host using `su`
* `sudo` to allow users in the libvirt group to run the script
* SSH acces to kvm host
* DNS resolve

To install, run the installation script: `./install_spinup.sh kvm-host`

Warning: This will automatically install `sudo` and `libfs-tools`

Usage 
-------------

1. create a config file. 

    See [sample.conf.sh](sample.conf.sh) for possible keywords

2. Spinup the new machine, using `./spinup.sh my.conf.sh newhostname`

When it is done, you now have
* a running virtualmachine with the name you specified, that you can ssh into.
* the new login credentials in `host_vars/newhostname/passwords.yml`. 

    This is [ansible](https://docs.ansible.com/) compatible

    If it existed already, it is renamed to `.old`


* there is also and `./passwords.log` file with the new credentials




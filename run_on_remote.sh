#!/usr/bin/env sh

REMOTE_PATH="https://raw.githubusercontent.com/moozer/virt-spinup/master"

set -e

echo checking for sudo
if [ -x /usr/bin/sudo ]; then
	echo sudo found. not installing
else
	echo Sudo not found. installing
	apt-get install -y sudo
fi

echo checking for customization tools
if [ -x /usr/bin/virt-customize ]; then
	echo virt-customize found. not installing
else
	echo virt-customize not found. installing libguestfs-tools
	apt-get install -y libguestfs-tools
fi


SUDOERS_FILE="${REMOTE_PATH}/virt-spinup"
echo fetching sudoers files from ${SUDOERS_FILE}
cd /etc/sudoers.d
wget -nc ${SUDOERS_FILE}

SCRIPT_FILE="${REMOTE_PATH}/spinupmachine.sh"
echo fetching spinup script
mkdir -p /opt/virt-spinup
cd /opt/virt-spinup
wget -nc ${SCRIPT_FILE}
chmod +x spinupmachine.sh

echo done


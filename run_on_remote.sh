#!/usr/bin/env sh

REMOTE_PATH="https://raw.githubusercontent.com/moozer/virt-spinup/master"

SUDOERS_FILE="${REMOTE_PATH}/virt-spinup"
echo fetching sudoers files from ${SUDOERS_FILE}
cd /etc/sudoers.d
wget -nc ${SUDOERS_FILE}

SCRIPT_FILE="${REMOTE_PATH}/spinupmachine.sh"
echo fetching spinup script
mkdir -p /opt/virt-spinup
wget -nc ${SCRIPT_FILE}
chmod +x spinupmachine.sh

echo done


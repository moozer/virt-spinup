#!/usr/bin/env bash

if [ "x" == "x$1" ]; then
	echo "usage: $0 <host-name>"
	exit 1
fi

HOST=$1
echo Using host $HOST

scp run_on_remote.sh ${HOST}:/tmp
echo Running script on remote.
echo We will now be asking for the root password on remote machine
ssh -t $HOST su -c /tmp/run_on_remote.sh
ssh $HOST rm /tmp/run_on_remote.sh

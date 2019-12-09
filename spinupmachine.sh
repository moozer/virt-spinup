#!/bin/sh

# to ensure early fail
set -e

PATH=/usr/bin:/bin

ORIGINALDOMAIN="deb9-base"
IMAGESPATH="/var/lib/libvirt/images"

if [ "x" = "x$1" ]; then
	echo "usage: $0 <newdomainname> <from_daomin>"
	exit 1
fi

if [ ! "x" = "x$2" ]; then
	ORIGINALDOMAIN="$2"
fi

NEWDOMAIN="$1"
LOGFILE="spinup_$1.log"
echo "log start $(date)" > $LOGFILE

echo "Cloning $ORIGINALDOMAIN to $NEWDOMAIN" > /dev/stderr

# requires gtk and other stuff
# from the packages virtinst
#virt-clone --original $ORIGINALDOMAIN \
#           --name $NEWDOMAIN \
#           --file $IMAGESPATH/$NEWDOMAIN.qcow2 > $LOGFILE

# copy the storage.
ORIG_PATH=$(virsh dumpxml $ORIGINALDOMAIN | grep "\<source file=" | cut -d "'" -f 2)
if [ ! -f $IMAGESPATH/$NEWDOMAIN.qcow2 ]; then
	echo "- copy from $ORIG_PATH to $IMAGESPATH/$NEWDOMAIN.qcow2" > /dev/stderr
	cp $ORIG_PATH $IMAGESPATH/$NEWDOMAIN.qcow2
else
	echo "- destination qcow image already exists - skipping" > /dev/stderr
fi

if virsh list --all | grep " $NEWDOMAIN "; then
	echo "$NEWDOMAIN already exists, please delete before continuing" > /dev/stderr
	exit 1
else
	# dump the xml for the original
	echo "- get xml and change it" > /dev/stderr
	virsh dumpxml $ORIGINALDOMAIN > $NEWDOMAIN.xml

	# hardware addresses need to be removed, libvirt will assign
	# new addresses automatically
	sed -i /uuid/d $NEWDOMAIN.xml
	sed -i '/mac address/d' $NEWDOMAIN.xml

	# and actually rename the vm: (this also updates the storage path)
	sed -i s/\<name\>$ORIGINALDOMAIN/\<name\>$NEWDOMAIN/ $NEWDOMAIN.xml

	# change line:  <source file='/var/lib/libvirt/images/deb9-base.qcow2'/>
	sed -i s#${ORIG_PATH}#$IMAGESPATH/$NEWDOMAIN.qcow2# $NEWDOMAIN.xml

	# finally, create the new vm
	echo "- import new domain" > /dev/stderr
	virsh define $NEWDOMAIN.xml >> $LOGFILE

	echo "- setting hostname and resetting passwords" > /dev/stderr
	virt-customize -d $NEWDOMAIN \
               --hostname $NEWDOMAIN \
               --root-password random \
               --password sysuser:random  >> $LOGFILE

	echo "- starting domain" > /dev/stderr
	virsh start $NEWDOMAIN >> $LOGFILE

	echo "- save passwords to file" > /dev/stderr
	cat $LOGFILE | grep "Setting random password" | awk '{ print $6 ": \"" $8 "\"" }' > ${NEWDOMAIN}_passwords.yml

fi

echo "passwords for domain" > /dev/stderr
cat ${NEWDOMAIN}_passwords.yml
exit 0

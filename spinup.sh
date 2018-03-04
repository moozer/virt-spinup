#!/bin/sh

VMHOST="beast"
DEFAULTIMAGE="deb9-base"
#USER: sysuser
PUBKEYFILE="~/.ssh/id_rsa.pub"
SPINUPSCRIPT="/opt/virt-spinup/spinupmachine.sh"
PASSWDFILE="passwords.log"
USERNAME="sysuser"
ANSIBLE_PASSWDFILE="passwords.yml"

## add stuff realted to parameters
NEWHOST="deb9-test"

# ssh $VMHOST sudo $SPINUPSCRIPT $NEWHOST $DEFAULTIMAGE > $PASSWDFILE
# if [ "$?" -gt "0" ]; then
#   echo "failed - see output above for possible reasons"
#   exit 1
# fi

echo "success"

USERPASS=$(cat $PASSWDFILE | grep $USERNAME | cut -d'"' -f2)
ROOTPASS=$(cat $PASSWDFILE | grep root | cut -d'"' -f2)

echo "passwords:"
echo " - root: $ROOTPASS"
echo " - $USERNAME: $USERPASS"

echo "waiting for $NEWHOST to come online"
until ping -c 1 $NEWHOST
do
  sleep 5s
done

NEWHOST_IP=$(dig +short $NEWHOST)
echo "remove entry in known_hosts corresponding to any previous $NEWHOST"
ssh-keygen -R $NEWHOST
ssh-keygen -R $NEWHOST_IP

SSHPASS=$USERPASS
echo "add entry to known_hosts"
sshpass -e ssh -o StrictHostKeyChecking=no $USERNAME@$NEWHOST exit
echo "add public key"
sshpass -e ssh-copy-id $USERNAME@$NEWHOST

echo creating inventory stuff
mkdir -p host_vars/$NEWHOST
cd host_vars/$NEWHOST
if [ -f $ANSIBLE_PASSWDFILE ]; then
  mv $ANSIBLE_PASSWDFILE ${ANSIBLE_PASSWDFILE}.old
fi

echo root_pass: \"$ROOTPASS\" > $ANSIBLE_PASSWDFILE
echo user_pass: \"$USERPASS\" >> $ANSIBLE_PASSWDFILE

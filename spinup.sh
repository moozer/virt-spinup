#!/usr/bin/env bash

# config options
# this is default values, source will override
VMHOST="beast"
SOURCEHOST="deb9-base"
PUBKEYFILE="~/.ssh/id_rsa.pub"
SPINUPSCRIPT="/opt/virt-spinup/spinupmachine.sh"
PASSWDFILE="passwords.log"
USERNAME="sysuser"
ANSIBLE_PASSWDFILE="passwords.yml"

# ----
show_usage()
{
  echo "usage $0 <config> <newhostname> <sourcehost>"
  echo "  <config>	config file to source"
  echo "  <newhostname>	new vm name"
  echo "  <sourcehost>	(optional) VM to clone"
}

show_params()
{
  echo "Parameters:"
  echo "  VMHOST: $VMHOST"
  echo "  SOURCEHOST: $SOURCEHOST"
  echo "  SPIUNUPSCRIPT: $SPINUPSCRIPT"
  echo "  PASSWDFILE: $PASSWDFILE"
  echo "  USERNAME: $USERNAME"
  echo "  ANSIBLE_PASSWDFILE: $ANSIBLE_PASSWDFILE"
  echo ""
}


# --------------------
#  Setting up params
# --------------------
if [ "x" = "x$1" ]; then
  show_usage
  exit 2
fi
CONF_FILE="$1"
echo sourcing config from $CONF_FILE
. $CONF_FILE

if [ "x" == "x$2" ]; then
  show_usage
  exit 3
fi
NEWHOST="$2"
echo cloning to $NEWHOST

if [ "x" != "x$3" ]; then
    SOURCEHOST="$3"
fi
echo cloning from $SOURCEHOST

show_params

echo "running spinupscript"
ssh $VMHOST sudo $SPINUPSCRIPT $NEWHOST $SOURCEHOST > $PASSWDFILE
if [ "$?" -gt "0" ]; then
  echo "failed - see output above for possible reasons"
  exit 1
fi

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

echo "add entry to known_hosts"
SSHPASS=$USERPASS sshpass -e ssh -o StrictHostKeyChecking=no $USERNAME@$NEWHOST exit
echo "add public key"
SSHPASS=$USERPASS sshpass -e ssh-copy-id $USERNAME@$NEWHOST

echo creating inventory stuff
mkdir -p host_vars/$NEWHOST
cd host_vars/$NEWHOST
if [ -f $ANSIBLE_PASSWDFILE ]; then
  mv $ANSIBLE_PASSWDFILE ${ANSIBLE_PASSWDFILE}.old
fi

echo root_pass: \"$ROOTPASS\" > $ANSIBLE_PASSWDFILE
echo user_pass: \"$USERPASS\" >> $ANSIBLE_PASSWDFILE

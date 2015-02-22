#!/bin/bash
HOST_IP=192.168.122.1
LXC_TYPE="ssh"

while [ $# -gt 0 ]
do
    case "$1" in
        -l) LXC_TYPE=$2; shift;;
        -help)
            echo -e >&2 "$0 [OPTION] [VALUE]
                       -l) Specify lxc type. Options are = \"ssh\" or \"chef\"" 
            exit 1;;
        -*)
            echo >&2 "Invalid option $1"
            echo >&2 "Try \`$0 -help\` for options"
            exit 1;;
         *)
            echo >&2 "Invalid option $1"
            echo >&2 "Try \`$0 -help\` for options"
            exit 1;;
    esac
    shift
done

function setup_env
{
    #default rootfs PATH exprected
    if [ -z "$LXCROOTFS_PATH" ]; then
      LXCROOTFS_PATH=/opt/ws
      echo "rootfs path is not set.. setting it to $LXCROOTFS_PATH"
    fi
}

function download_ubuntu_lxc
{

if ! cd "$LXCROOTFS_PATH"; then
  echo "ERROR: can't access temporary directory ($LXCROOTFS_PATH)" >&2
  exit 1
fi

if [[ $1 == "ssh" ]]; then
if [[ ! -f $LXCROOTFS_PATH/ubuntu-core-14.04-core-amd64_ssh.tar ]]; then
tftp 192.168.122.1 <<EOF
mode binary
get ubuntu-core-14.04-core-amd64_ssh.tar
quit
EOF
tar -xvf ubuntu-core-14.04-core-amd64_ssh.tar
fi
elif [[ $1 == "chef" ]]; then
if [[ ! -f $LXCROOTFS_PATH/ubuntu-core-14.04-core-amd64_chef.tar ]]; then
tftp 192.168.122.1 <<EOF
mode binary
get ubuntu-core-14.04-core-amd64_chef.tar
quit
EOF
tar -xvf ubuntu-core-14.04-core-amd64_chef.tar
fi
fi

}

function download_helper_scripts
{
mkdir -p $LXCROOTFS_PATH
if ! cd "$LXCROOTFS_PATH"; then
  echo "ERROR: can't access temporary directory ($LXCROOTFS_PATH)" >&2
  exit 1
fi

if [[ ! -f $LXCROOTFS_PATH/chrootscript.sh ]]; then

tftp 192.168.122.1 <<EOF
mode binary
get chrootscript.sh
quit
EOF
chmod +x $LXCROOTFS_PATH/chrootscript.sh
fi

if [[ ! -f $LXCROOTFS_PATH/createlxc.sh ]]; then
tftp 192.168.122.1 <<EOF
mode binary
get createlxc.sh 
quit
EOF
chmod +x $LXCROOTFS_PATH/createlxc.sh
fi
}

function run_chroot_script
{ 
chroot /opt/ws/ ./chrootscript.sh 
}

function create_bridge
{
brctl addbr bridge0
ifconfig bridge0 172.17.51.1 netmask 255.255.255.0

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 172.17.51.0/24 -j MASQUERADE

arr=( $(brctl show | awk '{print $1}') )

found=0
while true
do
for intf in "${arr[@]}"
do
    echo $intf
    if [[ $intf == "ieobc_br" ]]; then
        found=1
        break
    fi
done
if [[ $found == "0" ]]; then
    sleep 5
    continue
else
    break
fi
done
ip route add 10.11.12.20/32 dev ieobc_br
}

function run_lxc
{
$LXCROOTFS_PATH/createlxc.sh
virsh -c lxc:/// list
}


function main
{
     setup_env
     download_helper_scripts 
     download_ubuntu_lxc $LXC_TYPE 
     run_chroot_script
     create_bridge
     run_lxc
}
  main
  exit 0


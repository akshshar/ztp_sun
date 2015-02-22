#!/bin/bash
#set -x
function setup_env
{
    #default rootfs PATH exprected
    if [ -z "$LXCROOTFS_PATH" ]; then
      LXCROOTFS_PATH=/opt/ws
      echo "rootfs path is not set.. setting it to $LXCROOTFS_PATH"
    fi
    read LXCNETWORK <<< $( virsh net-list | sed -n 3p | awk '{print $1}') 
    read LIBVIRT_PATH <<<  $(find /usr -name libvirt_lxc)
}

function enable_network
{
    #find the rc.local file in the rootfs
    if [ ! -f $LXCROOTFS_PATH/etc/network/interfaces.d/eth0 ]; then
       #touch eth0 || { echo "Cannot write to file" >&2; exit 1 }
       touch eth0
       echo -e "##eth0 for uvf vm" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "auto eth0" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "iface eth0 inet static" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "address 10.11.12.20" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "netmask 255.255.255.0" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "broadcast 10.11.12.255" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "##eth1 for uvf vm" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "auto eth1" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "iface eth1 inet static" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "address 172.17.51.10" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "netmask 255.255.255.0" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "broadcast 172.17.51.255" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
       echo -e "gateway 172.17.51.1" >> ${LXCROOTFS_PATH}/etc/network/interfaces.d/eth0
   else
       echo "Interface eth0 definition already exists"
   fi

}

function create_xml
{
    LXC_XML="
    <domain type='lxc'>
       <name>3rdP</name>
       <memory>327680</memory>
       <os>
         <type>exe</type>
         <init>/sbin/init</init>
       </os>
       <vcpu>1</vcpu>
       <clock offset='utc'/>
       <on_poweroff>destroy</on_poweroff>
       <on_reboot>restart</on_reboot>
       <on_crash>destroy</on_crash>
       <devices>
           <emulator>$LIBVIRT_PATH</emulator>
           <filesystem type='mount'>
             <source dir='$LXCROOTFS_PATH'/>
             <target dir='/'/>
           </filesystem>
           <interface type='network'>
              <source network='$LXCNETWORK'/>
           </interface>
           <interface type='bridge'>
              <source bridge='bridge0'/>
              <target dev='vnet7'/>
              <mac address='00:11:22:33:44:55'/>
           </interface>           
            <filesystem type='mount'>
              <source dir='/etc/resolv.conf'/>
              <target dir='/etc/resolv.conf'/>
            </filesystem>
           <console type='pty'/>
       </devices>
    </domain>
    "
    echo $LXC_XML > /tmp/3rdlxc.xml 
}
function start_lxc
{
    echo "Starting the 3rd party lxc with virsh."
    #also save the container pid
    ps -aef | grep init | awk '{print $2}' > /tmp/b4 
    #start the lxc container
    virsh -c lxc:/// create /tmp/3rdlxc.xml
    ps -aef | grep init | awk '{print $2}' > /tmp/aft
    diff /tmp/aft /tmp/b4 > /tmp/3rdP.pid 

    #get into the uvf container
    #echo "execute: ssh root@10.11.12.115 to get to  container, password lab"
}

function parseargs
{
#http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
for i in "$@"
do
case $i in
    -p=*|--prefix=*)
    PREFIX="${i#*=}"

    ;;
    -s=*|--searchpath=*)
    SEARCHPATH="${i#*=}"
    ;;
    -l=*|--lib=*)
    DIR="${i#*=}"
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
done
echo PREFIX = ${PREFIX}
echo SEARCH PATH = ${SEARCHPATH}
echo DIRS = ${DIR}
}

function main 
{
     setup_env
     enable_network
     #parseargs
     create_xml
     #echo $LXCROOTFS_PATH
     echo $LXCNETWORK
     #echo $LIBVIRT_PATH
     #echo $LXC_XML
     start_lxc
}
  main
  exit 0

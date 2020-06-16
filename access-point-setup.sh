#!/bin/bash

#GLOBAL VARIABLES
PASSWORD_FLAG="no"
#

##exit function block##
exit_function(){
read -p "Type y for yes and n for no : " ANS
if [ $ANS == 'y' ];then
echo "restarting raspberry pi.."
sudo reboot
elif [ $ANS == "n" ];then
echo ""
echo "Manually reboot your system later....."
echo "exiting setup..."
exit 0
else
exit_function
fi
}

##uninstall function block##
uninstall(){
echo "reverting changes in dhcpcd.conf..." | tee -a logs.txt
sudo sed -i "s|denyinterfaces wlan0||g" /etc/dhcpcd.conf
echo ""

echo "reverting changes in wlan0..." | tee -a logs.txt
FILE=/etc/network/interfaces.d/wlan0.backup
if [ -f "$FILE" ]; then
 echo "$FILE exist" | tee -a logs.txt
 sudo rm /etc/network/interfaces.d/wlan0
 sudo mv /etc/network/interfaces.d/wlan0.backup /etc/network/interfaces.d/wlan0
else
 echo "$FILE didnt exist" | tee -a logs.txt
 sudo rm /etc/network/interfaces.d/wlan0
echo ""
fi

echo "reverting changes in hostapd.conf..." | tee -a logs.txt
FILE=/etc/hostapd/hostapd.conf.backup
if [ -f "$FILE" ]; then
 echo "$FILE exist" | tee -a logs.txt
 sudo rm /etc/hostapd/hostapd.conf
 sudo mv /etc/hostapd/hostapd.conf.backup /etc/hostapd/hostapd.conf
else
 echo "$FILE didnt exist" | tee -a logs.txt
 sudo rm /etc/hostapd/hostapd.conf
echo ""
fi

echo "reverting changes in hostapd..." | tee -a logs.txt
sudo sed -i "s|"DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""||g" /etc/default/hostapd

echo "disabling hostapd service..." | tee -a logs.txt
sudo systemctl stop hostapd.service
sudo systemctl disable hostapd.service | tee -a logs.txt

FILE=/etc/systemd/system/hostapd.service.backup
if [ -f "$FILE" ]; then
 echo "$FILE exist" | tee -a logs.txt
 sudo rm /etc/systemd/system/hostapd.service
 sudo mv /etc/systemd/system/hostapd.service.backup /etc/systemd/system/hostapd.service
else
 echo "$FILE didnt exist" | tee -a logs.txt
 sudo rm /etc/systemd/system/hostapd.service
echo ""
fi

echo "reverting changes in dnsmasq.conf..." | tee -a logs.txt
FILE=/etc/dnsmasq.conf.backup
if [ -f "$FILE" ]; then
 echo "$FILE exist" | tee -a logs.txt
 sudo rm /etc/dnsmasq.conf
 sudo mv /etc/dnsmasq.conf.backup /etc/dnsmasq.conf
else
 echo "$FILE didnt exist" | tee -a logs.txt
 sudo rm /etc/dnsmasq.conf
echo ""
fi

echo "disabling ipv4 forwarding......"
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
sudo sh -c "echo 0 > /proc/sys/net/ipv6/conf/all/forwarding"
sudo sed -z 's|#for accesspoint configuration\nnet.ipv4.ip_forward=1||g' -i /etc/sysctl.conf
sudo rm -r /etc/iptables.ipv4.nat

echo "reverting changes in rc.local..." | tee -a logs.txt
sudo sed -i 's|sudo service hostapd start||g' /etc/rc.local
sudo sed -i 's|iptables-restore < /etc/iptables.ipv4.nat||g' /etc/rc.local
echo "--- Finished reverting configurations for Access point ---" | tee -a logs.txt
echo "--- Reboot system to apply changes ---" | tee -a logs.txt
read -p "Do you want to reboot now ? :  " ANS
if [ $ANS == 'y' ];then
echo "restarting raspberry pi.."
sudo reboot
elif [ $ANS == "n" ];then
echo ""
echo "Manually reboot your system later....."
echo "exiting setup..."
exit 0
else
exit_function
fi
exit 0
}

if [ "$1" == "--uninstall" ];then
echo "uninstalling accesspoint configurations..." | tee -a logs.txt
uninstall
elif [ "$1" == "" ];then
echo "continuing to configure wlan0 as Access-point..." | tee -a logs.txt
else
echo "use --uninstall to revert changes made for Access-point in wlan0"
exit 0
fi

sudo apt-get install figlet
echo ""
echo "PI ACCESS POINT SETUP" | figlet -f slant
echo ""
echo "Novitat" | figlet -f smslant
echo "Engineering " | figlet -f smslant
echo "Solutions" | figlet -f smslant
echo "----------CHECKING FOR UPDATES--------" | tee -a logs.txt
echo ""
sudo apt-get update
echo ""
echo "-----------INSTALLING UPDATES---------" | tee -a logs.txt
echo ""
sudo apt-get upgrade
echo ""

#ACCESS POINT SETUP PROCESS
sudo rfkill unblock 0
echo "--------SETTING UP ACCESS POINT-----------" | tee -a logs.txt
echo ""
echo "You cannot use your raspberry pi as a WIFI and it will be converted to a Access point-WIFI Hotspot" | tee -a logs.txt
echo ""
read -p "Please provide your new SSID to be broadcasted by Raspberry pi (Example: My_Raspi_AP): " AP_SSID
echo ""
echo  "Do you want the Access point to be open to everyone or to be accessed by people who have password ? " | tee -a logs.txt
read -p "Type y for yes and n for no : " ANS

condition1(){
read -p "Type y for yes and n for no : " ANS
if [ $ANS == 'y' ];then
PASSWORD_FLAG="yes"
read -p "Type your password with a minimun length of 8 characters,***OR else Access-point wont work and you have to install it again***:" AP_PASSWORD
elif [ $ANS == "n" ];then
echo ""
echo "Access point will be created without security and any one can join the network"
else
condition1
fi
}

if [ $ANS == 'y' ];then
PASSWORD_FLAG="yes"
read -p "Type your password with a minimun length of 8 characters,***OR else Access-point wont work and you have to install it again***:" AP_PASSWORD
elif [ $ANS == "n" ];then
echo ""
echo "Access point will be created without security and any one can join the network"
else
condition1
fi

echo ""
echo "Installing dependencies"
sudo apt-get install hostapd dnsmasq
echo ""
echo "editing dhcpcd.conf..."
FILE="/etc/dhcpcd.conf"
sudo echo "denyinterfaces wlan0" >> $FILE
FILE="/etc/network/interfaces.d/wlan0"
echo "editing interfaces..."
echo "Please type in your IPV4 IP-ADDRESS to configure the Access point * Make sure , the ip address you are providing is not used by any other surrounding networks* : "
read IPADDRESS

sudo echo "
allow-hotplug wlan0
iface wlan0 inet static
    address $IPADDRESS
    netmask 255.255.255.0
    network ${IPADDRESS:0:10}.0
    broadcast ${IPADDRESS:0:10}.255
" > wlan0


FILE=/etc/network/interfaces.d/wlan0
if [ -f "$FILE" ]; then
    echo "$FILE exist" | tee -a logs.txt
 sudo mv /etc/network/interfaces.d/wlan0 /etc/network/interfaces.d/wlan0.backup
 sudo mv wlan0 /etc/network/interfaces.d/
else
 sudo mv wlan0 /etc/network/interfaces.d/
echo ""
fi

echo ""
echo "editing hostapd configuration file...." | tee -a logs.txt
sudo echo "
# The Wi-Fi interface configured for static IPv4 addresses
interface=wlan0

# Use the 802.11 Netlink interface driver
driver=nl80211

# The user-defined name of the network
ssid=$AP_SSID

# Use the 2.4GHz band
hw_mode=g

# Use channel 6
channel=6

# Enable 802.11n
ieee80211n=1

# Enable WMM
wmm_enabled=1

# Enable 40MHz channels with 20ns guard interval
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Use WPA authentication
auth_algs=1

# Require clients to know the network name
ignore_broadcast_ssid=0 " > hostapd.conf

if [ $PASSWORD_FLAG == "yes" ];then
echo "
# Use WPA2
wpa=2

# Use a pre-shared key
wpa_key_mgmt=WPA-PSK

# The network passphrase
wpa_passphrase=$AP_PASSWORD" >> hostapd.conf
else

echo "
# For no passpharase
wpa=0" >> hostapd.conf
fi
echo "
# Use AES, instead of TKIP
rsn_pairwise=CCMP" >> hostapd.conf

FILE=/etc/hostapd/hostapd.conf
if [ -f "$FILE" ]; then
    echo "$FILE exist" | tee -a logs.txt
 sudo mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.backup
 sudo mv hostapd.conf /etc/hostapd/
else
 sudo mv hostapd.conf /etc/hostapd/
echo ""
fi

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

echo "making hostapd to run at startup ...." | tee -a logs.txt
sudo systemctl unmask hostapd | tee -a logs.txt
sudo systemctl start hostapd

echo  "
Description=Hostapd IEEE 802.11 Access Point
After=sys-subsystem-net-devices-wlan0.device
BindsTo=sys-subsystem-net-devices-wlan0.device

[Service]
Type=forking
PIDFile=/var/run/hostapd.pid
ExecStart=/usr/sbin/hostapd -B /etc/hostapd/hostapd.conf -P /var/run/hostapd.pid

[Install]
WantedBy=multi-user.target " > hostapd.service

FILE=/etc/systemd/system/hostapd.service
if [ -f "$FILE" ]; then
    echo "$FILE exist" | tee -a logs.txt
 sudo mv /etc/systemd/system/hostapd.service /etc/systemd/system/hostapd.service.backup
 sudo mv hostapd.service /etc/systemd/system/
else
 sudo mv hostapd.service /etc/systemd/system/
echo ""
fi
sudo sed -i 's|fi|fi\nsudo service hostapd start|g' /etc/rc.local

echo "configuring dnsmasq...." | tee -a logs.txt
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

echo "
# The Wi-Fi interface configured for static IPv4 addresses
interface=wlan0

# Explicitly specify the address to listen on
listen-address=$IPADDRESS

# Bind to the interface to make sure we aren't sending things elsewhere
bind-interfaces

# Forward DNS requests to the Google DNS
server=8.8.8.8

# Don't forward short names
domain-needed

# Never forward addresses in non-routed address spaces
bogus-priv

# Assign IP addresses between *****.50 and *********.150 with a 12 hour lease time
dhcp-range=${IPADDRESS:0:10}.50,${IPADDRESS:0:10}.150,12h " > dnsmasq.conf

sudo mv dnsmasq.conf /etc/

echo "enabling ipv4 forwarding......" | tee -a logs.txt

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"

sudo echo "
#for accesspoint configuration
net.ipv4.ip_forward=1
" >> /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

sudo sed -i 's|fi|fi\niptables-restore < /etc/iptables.ipv4.nat|g' /etc/rc.local

echo ""
echo "+++++++ACCESS POINT SETUP HAS BEEN COMPLETED++++++++"
echo ""

echo ""
echo "++++ The system needs to reboot ++++"
read -p "Do you want to reboot now ? : " ANS


if [ $ANS == 'y' ];then
echo "restarting raspberry pi.."
sudo reboot
elif [ $ANS == "n" ];then
echo ""
echo "Manually reboot your system later....."
echo "exiting setup..."
exit 0
else
exit_function
fi

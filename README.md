<a href="https://www.raspberrypi.org"><img src="https://www.raspberrypi.org/wp-content/uploads/2012/03/raspberry-pi-logo.png" alt="Raspberry Pi Logo" align="left" style="margin-right: 25px" height=150></a>
#
# Raspberry Access Point Setup
##
##
## About
A single script to convert your Raspberry pi into Wifi Access-point , just using a command line.
## Steps to install 
 Pull the repository and change the directory to repository directory

`git clone https://github.com/novitatlabs/raspberrypi-ap-setup.git`

`cd raspberrypi-ap-setup/`

Run the shell script

`sudo bash access-point-setup.sh`

This will install all dependencies and configure your raspberry as Wifi Access-point.

Give your inputs while running the shell script when prompted , such as ssid,password,ip-address etc.

## Reverting the changes
To revert the changes made by the shell script for configuration of Access point, run the shell script with `--uninstall` as option.

`sudo bash access-point-setup.sh --uninstall`

This will revert all the changes made for Access-point setup

## Known issues 
- The install and uninstall procedure , goes hands to hands.Only if you run the setup procedure for access point completely, the `--uninstall` procedure can revert the changes it had made.If you stop the setup process in between and if you call `--uninstall` ,the script can still remove the changes and configuration made so far, but it can also remove configuration files of hostapd,wlan0,dnsmasq if you have any existing files already.
- Use static ip address of format `XXX.XXX.XX.X`  when promted to enter ip address during Access point setup procedure,  `Example : 192.168.20.4`.
## Contribution
[![Awesome](https://media-exp1.licdn.com/dms/image/C4E0BAQFinUWCTBXJYQ/company-logo_200_200/0?e=1600300800&v=beta&t=cb42HSKOF6s1EjBKpewXCzEtDS40WeEHKCyhGogs6Yo)](https://github.com/novitatlabs)

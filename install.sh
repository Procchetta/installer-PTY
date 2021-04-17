#!/bin/sh

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install screen -y
############################################


######################################################################################################
#direwolf

sudo apt-get install gcc -y
sudo apt-get install g++ -y
sudo apt-get install make -y
sudo apt-get install cmake -y
sudo apt-get install libasound2-dev -y
sudo apt-get install libudev-dev -y
sudo apt-get install libusb-1.0-0-dev -y
sudo apt-get install libgps-dev -y
sudo apt-get install libx11-dev -y
sudo apt-get install libfftw3-dev -y
sudo apt-get install libpulse-dev -y
sudo apt-get install build-essential -y
sudo apt-get install alsa-utils -y
sudo apt-get install rsyslog -y
sudo apt-get install logrotate -y
sudo apt-get install gpsd -y
sudo apt-get install screen -y
sudo apt-get install qt4-qmake -y
sudo apt-get install libtool -y
sudo apt-get install autoconf -y
sudo apt-get install automake -y
sudo apt-get install python-pkg-resources -y
sudo apt-get install sox -y
sudo apt-get install git-core -y
sudo apt-get install libi2c-dev -y
sudo apt-get install i2c-tools -y
sudo apt-get install lm-sensors -y
sudo apt-get install wiringpi -y
sudo apt-get install chkconfig -y
sudo apt-get install wavemon -y

mkdir /opt/YSF2DMR

cd /opt
git clone https://github.com/juribeparada/MMDVM_CM.git
sudo cp -r /opt/MMDVM_CM/YSF2DMR /opt/
cd YSF2DMR
sudo make
sudo make install

cd /opt
git clone https://github.com/g4klx/YSFClients.git
sudo cp -r /opt/YSFClients/YSFReflector /opt/
cd YSFReflector
sudo make
sudo make install

cd /opt
git clone https://github.com/osmocom/rtl-sdr.git
cd rtl-sdr/
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
sudo make
sudo make install
sudo ldconfig

cd /opt
git  clone https://github.com/asdil12/kalibrate-rtl.git
cd kalibrate-rtl/
./bootstrap
./configure
sudo make
sudo make install
################################################
#Direwolf

#sudo apt-get remove â€“purge pulseaudio y
#sudo apt-get autoremove -y
#rm -rf /home/pi/.pulse%

cd /opt	
git clone https://www.github.com/wb2osz/direwolf
cd direwolf
git checkout dev
mkdir build && cd build
cmake ..
make -j4
sudo make install
make install-conf

##################################################################
#multimon-ng
cd /opt
git clone https://github.com/EliasOenal/multimon-ng.git
cd multimon-ng/
mkdir build
cd build
cmake ..
make
sudo make install

cd /opt
git clone https://github.com/asdil12/pymultimonaprs.git
cd pymultimonaprs
sudo python2 setup.py install

############################################################################################
sudo mkdir /var/www
sudo mkdir /var/www/html
sudo mkdir /var/www/setup
sudo mkdir /var/www/setup/mmdvm
sudo mkdir /var/www/setup/ysf

sudo mkdir /var/www/web-mmdvm
sudo mkdir /var/www/web-ysf
sudo chmod +777 /var/www/*

cd /var/www/
git clone https://github.com/dg9vh/YSFReflector-Dashboard
sudo mv /var/www/YSFReflector-Dashboard/* /var/www/web-ysf/
sudo rm -r /var/www/YSFReflector-Dashboard/
git clone https://github.com/dg9vh/MMDVMHost-Dashboard.git
sudo mv /var/www/MMDVMHost-Dashboard/* /var/www/web-mmdvm/
sudo rm -r /var/www/MMDVMHost-Dashboard/

sudo mv /var/www/web-mmdvm/setup.php /var/www/setup/mmdvm/
sudo mv /var/www/web-ysf/setup.php /var/www/setup/ysf/
sudo chmod +777 /var/www/html

sudo chmod +777 /var/log
sudo mkdir /var/log/ysf
sudo mkdir /var/log/ysf2dmr
sudo mkdir /var/log/mmdvm
sudo chmod +777 /var/log/*

####################################

cd /boot
sudo sed -i 's/console=serial0,115200 //' cmdline.txt

sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl stop bluetooth.service
sudo systemctl disable serial-getty@ttyAMA0.service
sudo systemctl disable bluetooth.service

sudo sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' config.txt
sudo sed -i 's/dtparam=audio=on/#dtparam=audio=on/' config.txt

echo "enable_uart=1" >> config.txt
echo "dtoverlay=pi3-disable-bt" >> config.txt
echo "dtparam=spi=on" >> config.txt

##################
cat > /lib/systemd/system/monp.service  <<- "EOF"
[Unit]
Description=sudo modprobe i2c-dev
#Wants=network-online.target
#After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=sudo modprobe i2c-dev
[Install]
WantedBy=multi-user.target
EOF

##########
cd /opt
git clone https://github.com/g4klx/MMDVMHost.git
cd MMDVMHost/
make
make install
git clone https://github.com/hallard/ArduiPi_OLED
cd ArduiPi_OLED
sudo make
cd /opt/MMDVMHost/
make clean
sudo make -f Makefile.Pi.OLED 

groupadd mmdvm 
useradd mmdvm -g mmdvm -s /sbin/nologin 
chown mmdvm /var/log/

#############################################################################################################################################################
######
cat > /bin/menu-mm-rtl <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Multimon-ng  APRS " \
2 " Iniciar APRS " \
3 " Detener APRS " \
4 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /etc/pymultimonaprs.json;;
2)
sudo systemctl restart multimon-rtl.service && sudo systemctl enable multimon-rtl.service;;
3)
sudo systemctl stop multimon-rtl.service && sudo systemctl disable multimon-rtl.service;;
4)
break;
esac
done
exit 0
EOF
#######service YSFREflector
cat > /lib/systemd/system/ysfr.service <<- "EOF"
[Unit]
Description=YSFReflector Service
After=network-online.target netcheck.service
[Service]
Type=simple
Restart=always
RestartSec=3
StandardOutput=null
WorkingDirectory=/usr/local/bin
ExecStartPre=/bin/sleep 30
ExecStart=/usr/local/bin/YSFReflector /opt/YSFReflector/YSFReflector.ini
#&& systemctl start ysfreflector.service
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
[Install]
# To make the network-online.target available
# systemctl enable systemd-networkd-wait-online.service
WantedBy=network-online.target
#ExecStart=/usr/local/bin/YSFReflector /opt/YSFReflector/YSFReflector.ini
EOF
#####

###menu
cat > /bin/menu <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 22 50 12 \
1 " APRS Direwolf Analogo" \
2 " APRS Direwolf RTL-SDR " \
3 " APRS Multimon-ng " \
4 " APRS Ionosphere " \
5 " MMDVMHost " \
6 " Dvswitch " \
7 " YSFReflector " \
8 " YSF2DMR " \
9 " Editar WiFi " \
10 " Reiniciar Raspberry " \
11 " APAGAR Raspberry " \
12 " Salir del menu " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
menu-dw-analogo;;
2)
menu-dw-rtl;;
3)
menu-mm-rtl;;
4)
menu-ionos;;
5)
menu-mmdvm;;
6)
menu-dvs;;
7)
menu-ysf;;
8)
menu-ysf2dmr;;
9)
menu-wifi;;
10)
sudo reboot ;;
11)
menu-apagar;;
12)
break;
esac
done
exit 0
EOF
######menu-wifi
cat > /bin/menu-wifi <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar redes WiFi " \
2 " Reiniciar dispositivo WiFi " \
3 " Buscar redes wifi cercanas " \
4 " Ver intensidad de seÃ±al  " \
5 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf ;;
2)
sudo rfkill unblock all && sudo ip link set wlan0 up && sudo ifconfig wlan0 down && sudo ifconfig wlan0 up ;;
3)
sudo iwlist wlan0 scanning | grep ESSID ;;
4)
sudo wavemon ;;
5)
break;
esac
done
exit 0
EOF


####menu-mmdvm
cat > /bin/menu-mmdvm <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar MMDVMHost " \
2 " Iniciar MMDVMHost " \
3 " Detener MMDVMHost " \
4 " Dashboard ON " \
5 " Dashboard Off " \
6 " Setup Dashboard on " \
7 " Setup Dashboard Off " \
8 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/MMDVMHost/MMDVM.ini;;
2)
sudo sh /opt/MMDVMHost/DMRIDUpdate.sh && sudo systemctl enable dmrid-mmdvm.service ;;
3)
sudo systemctl stop mmdvmh.service && sudo systemctl stop dmrid-mmdvm.service && sudo systemctl disable dmrid-mmdvm.service;;
4)
sudo cp -r /var/www/web-mmdvm/* /var/www/html/ && sudo systemctl restart lighttpd.service && sudo systemctl enable lighttpd.service && sudo chown -R www-data:www-data /var/www/html  && chmod +777 /var/www/html/* ;;
5)
sudo systemctl disable lighttpd.service && sudo systemctl stop lighttpd.service && sudo rm -r  /var/www/html/* ;;
6)
sudo cp -r /var/www/setup/mmdvm/setup.php /var/www/html/ && sudo chown -R www-data:www-data /var/www/html;;
7)
sudo rm -r /var/www/html/setup.php ;;
8)
break;
esac
done
exit 0
EOF
########menu-ysf
cat > /bin/menu-ysf <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar YSFReflector Server " \
2 " Iniciar Reflector  " \
3 " Detener Reflector  " \
4 " Dashbord on  " \
5 " Dashbord off  " \
6 " Setup Dashbord on  " \
7 " Setup Dashbord off  " \
8 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/YSFReflector/YSFReflector.ini ;;
2)
sudo systemctl stop ysfr.service && sudo systemctl start ysfr.service  && sudo systemctl enable ysfr.service ;;
3)
sudo systemctl stop ysfr.service && sudo systemctl disable ysfr.service ;;
4)
sudo cp -r /var/www/web-ysf/* /var/www/html/ && sudo systemctl restart lighttpd.service && sudo systemctl enable lighttpd.service && sudo chown -R www-data:www-data /var/www/html sudo && chmod +777 /var/www/html/* ;;
5)
sudo systemctl disable lighttpd.service && sudo systemctl stop lighttpd.service && sudo rm -r  /var/www/html/* ;;
6)
sudo cp -r /var/www/setup/ysf/setup.php /var/www/html/ && sudo chown -R www-data:www-data /var/www/html ;;
7)
sudo rm -r /var/www/html/setup.php ;;
8)
break;
esac
done
exit 0
EOF
##########menu-dvs
cat > /bin/menu-dvs <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Dvswitch Server " \
2 " Iniciar Dvswitch  " \
3 " Detener Dvswitch  " \
4 " Dashbord on  " \
5 " Dashbord off  " \
6 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo /usr/local/dvs/dvs ;;
2)
sudo systemctl restart dmrid-dvs.service && sudo systemctl restart analog_bridge.service && sudo systemctl enable analog_bridge.service && sudo systemctl enable dmrid-dvs.service ;;
3)
sudo systemctl stop mmdvm_bridge.service && sudo systemctl stop dmrid-dvs.service && sudo systemctl stop analog_bridge.service && sudo systemctl disable analog_bridge.service && sudo systemctl disable mmdvm_bridge.service && sudo systemctl disable dmrid-dvs.service ;;
4)
sudo cp -r /var/www/web-dvs/* /var/www/html/ && sudo systemctl restart lighttpd.service && sudo systemctl enable lighttpd.service && sudo chown -R www-data:www-data /var/www/html && sudo chmod +777 /var/www/html/* ;;
5)
sudo systemctl disable lighttpd.service && sudo systemctl stop lighttpd.service && sudo rm -r  /var/www/html/* ;;
6)
break;
esac
done
exit 0
EOF
###menu-apagar
cat > /bin/menu-apagar <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 11 100 3 \
1 " Iniciar apagado seguro" \
2 " Retornar  menu " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo shutdown -h now
;;
2) break;
esac
done
exit 0
EOF
###menu-cp-rtl
cat > /bin/menu-cp-rtl <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Direwolf " \
2 " Iniciar APRS " \
3 " Detener APRS " \
4 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/direwolf/dw.conf;;
2)
sudo systemctl restart direwolf.service && sudo systemctl enable direwolf.service;;
3)
sudo systemctl stop direwolf.service && sudo systemctl disable direwolf.service;;
4)
 break;
esac
done
exit 0
EOF
#####menu-dw-analogo
cat > /bin/menu-dw-analogo <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Direwolf Analogo " \
2 " Iniciar APRS " \
3 " Detener APRS " \
4 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/direwolf/dw.conf;;
2)
sudo systemctl restart direwolf.service && sudo systemctl enable direwolf.service;;
3)
sudo systemctl stop direwolf.service && sudo systemctl disable direwolf.service;;
4)
break;
esac
done
exit 0
EOF
######menu-dw-rtl
cat > /bin/menu-dw-rtl <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Direwolf RTL " \
2 " Editar RTL-SDR " \
3 " Iniciar APRS RX-IGate " \
4 " Detener APRS RX-IGate " \
5 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/direwolf/sdr.conf ;;
2)
sudo nano /opt/direwolf/rtl.sh ;;
3)
sudo systemctl restart direwolf-rtl.service && sudo systemctl enable direwolf-rtl.service;;
4)
sudo systemctl stop direwolf-rtl.service && sudo systemctl disable direwolf-rtl.service;;
5)
break;
esac
done
exit 0
EOF

#####
cat > /opt/direwolf/sdr.conf <<- "EOF"
#############################################################
#                                                           #
#               Configuration file for Dire Wolf            #
#                                                           #
#                   Linux version setting by HP1PAR         #
#                configuration for SDR read-only IGate.     #
#############################################################
ADEVICE null null
CHANNEL 0
MYCALL HP1PAR-10
PBEACON sendto=IG delay=0:40 every=30 symbol="/r" lat=08^30.01N long=080^20.83W comment="APRS RX-IGATE / Raspbian Proyect by HP1PAR"
# First you need to specify the name of a Tier 2 server.
# The current preferred way is to use one of these regional rotate addresses:
#       noam.aprs2.net          - for North America
#       soam.aprs2.net          - for South America
#       euro.aprs2.net          - for Europe and Africa
#       asia.aprs2.net          - for Asia
#       aunz.aprs2.net          - for Oceania
IGSERVER  igates.aprs.fi:14580
#noam.aprs2.net
# You also need to specify your login name and passcode.
# Contact the author if you can't figure out how to generate the passcode.
IGLOGIN HP1PAR-10 19376
# That's all you need for a receive only IGate which relays
# messages from the local radio channel to the global servers.
AGWPORT 9000
KISSPORT 9001
EOF
###
######menu-ysf2dmr
cat > /bin/menu-ysf2dmr <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar YSF2DMR " \
2 " Iniciar YSF2DMR " \
3 " Detener YSF2DMR " \
4 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/YSF2DMR/YSF2DMR.ini;;
2)
sudo sh /opt/YSF2DMR/DMRIDUpdate.sh && sudo systemctl enable dmrid-ysf2dmr.service;;
3)
sudo systemctl stop ysf2dmr.service && sudo systemctl stop dmrid-ysf2dmr.service && sudo systemctl disable dmrid-ysf2dmr.service;;
4)
break;
esac
done
exit 0
EOF
########ionosphere
mkdir /opt/ionsphere 
cd /opt/ionsphere 
wget https://github.com/cceremuga/ionosphere/releases/download/v1.0.0-beta1/ionosphere-raspberry-pi.tar.gz
tar vzxf ionosphere-raspberry-pi.tar.gz

cd /opt/ionsphere/ionosphere-raspberry-pi

cat > /opt/ionsphere/ionosphere-raspberry-pi/ionos.sh <<- "EOF"
#!/bin/sh
PATH=/bin:/usr/bin:/usr/local/bin
unset LANG
/opt/ionsphere/ionosphere-raspberry-pi/ionosphere
EOF

chmod +x /opt/ionsphere/ionosphere-raspberry-pi/ionosphere
chmod +x /opt/ionsphere/ionosphere-raspberry-pi/ionos.sh
chmod +777 /opt/ionsphere/ionosphere-raspberry-pi/ionos.sh
###nano /opt/ionsphere/ionosphere-raspberry-pi/config/config.yml

#####menu-ionos
cat > /bin/menu-ionos <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "Suba o Baje con las flechas del teclado y seleccione el numero de opcion" 20 50 11 \
1 " Editar Ionosphere  APRS " \
2 " Iniciar APRS " \
3 " Detener APRS " \
4 " Menu Principal " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo nano /opt/ionsphere/ionosphere-raspberry-pi/config/config.yml ;;
2)
systemctl enable ionos.service && sudo systemctl restart ionos.service ;;
3)
sudo systemctl stop ionos.service && sudo systemctl disable ionos.service ;;
4)
break;
esac
done
exit 0
EOF
################################
cat > /lib/systemd/system/ionos.service <<- "EOF"
[Unit]
Description=Ionphere-RTL Service
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
Type=simple
Restart=always
RestartSec=3
StandardOutput=null
WorkingDirectory=/opt/ionsphere/ionosphere-raspberry-pi
#ExecStartPre=/bin/sleep 30
ExecStart=sh /opt/ionsphere/ionosphere-raspberry-pi/ionos.sh
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
[Install]
# To make the network-online.target available
# systemctl enable systemd-networkd-wait-online.service
WantedBy=network-online.target
EOF
##########################################
####################################
####################################


cp /bin/menu /bin/MENU
chmod +x /bin/MENU 

###################
cat > /opt/direwolf/dw.conf <<- "EOF"
#############################################################
#                                                           #
#               Configuration file for Dire Wolf            #
#                                                           #
#                   Linux version setting by HP1PAR         #
#                                                           #
#############################################################
#############################################################
#                                                           #
#               FIRST AUDIO DEVICE PROPERTIES               #
#               (Channel 0 + 1 if in stereo)                #
#                                                           #
#############################################################
ADEVICE plughw:1,0
#ADEVICE null null
# ADEVICE - plughw:1,0
# ADEVICE UDP:7355 default
# Number of audio channels for this souncard:  1 or 2.
#
ACHANNELS 1
#############################################################
#                                                           #
#               CHANNEL 0 PROPERTIES                        #
#                                                           #
#############################################################
CHANNEL 0
MYCALL HP1PAR-10
MODEM 1200
#MODEM 1200 1200:2200
#MODEM 300  1600:1800
#MODEM 9600 0:0
#
#MODEM 1200 E+ /3
#
#
# If not using a VOX circuit, the transmitter Push to Talk (PTT)
# DON'T connect it directly!
#
# For the PTT command, specify the device and either RTS or DTR.
# RTS or DTR may be preceded by "-" to invert the signal.
# Both can be used for interfaces that want them driven with opposite polarity.
#
# COM1 can be used instead of /dev/ttyS0, COM2 for /dev/ttyS1, and so on.
#
#PTT COM1 RTS
#PTT COM1 RTS -DTR
#PTT /dev/ttyUSB0 RTS
#PTT GPIO 25
#PTT GPIO 26
# The Data Carrier Detect (DCD) signal can be sent to the same places
# as the PTT signal.  This could be used to light up an LED like a normal TNC.
#DCD COM1 -DTR
#DCD GPIO 24
#pin18 (GPIO 24) - (cathode) LED (anode) - 270ohm resistor - 3.3v
#DCD GPIO 13
#############################################################
#                                                           #
#               VIRTUAL TNC SERVER PROPERTIES               #
#                                                           #
#############################################################
#
# Dire Wolf acts as a virtual TNC and can communicate with
# client applications by different protocols:
#
#       - the "AGW TCPIP Socket Interface" - default port 8000
#       - KISS protocol over TCP socket - default port 8001
#       - KISS TNC via pseudo terminal   (-p command line option)
#
#Setting to 0 disables UI-proto only AGW and TCP-KISS ports
AGWPORT 8000
KISSPORT 8001
#KISSPORT 0
#
# It is sometimes possible to recover frames with a bad FCS.
# This applies to all channels.
#       0  [NONE] - Don't try to repair.
#       1  [SINGLE] - Attempt to fix single bit error.  (default)
#       2  [DOUBLE] - Also attempt to fix two adjacent bits.
#       ... see User Guide for more values and in-depth discussion.
#
#FIX_BITS 0
#Enable fixing of 1 bits and use generic AX25 heuristics data (not APRS heuristi$
#FIX_BITS 1 AX25
#
#############################################################
#                                                           #
#               BEACONING PROPERTIES                        #
#                                                           #
#############################################################
#PBEACON delay=0:01 every=30 symbol="/r" lat=08^30.01N long=080^20.83W comment="APRS DIGI-IGATE / Raspbian Proyect by HP1PAR" via=WIDE2-2
#PBEACON sendto=IG delay=0:40 every=30 symbol="/r" lat=08^30.01N long=080^20.83W comment="APRS DIGI-IGATE / Raspbian Proyect by HP1PAR"
#############################################################
#                                                           #
#               DIGIPEATER PROPERTIES                       #
#                                                           #
#############################################################
DIGIPEAT 0 0 ^WIDE[3-7]-[1-7]$|^TEST$ ^WIDE[12]-[12]$ TRACE
FILTER 0 0 t/poimqstunw
#############################################################
#                                                           #
#               INTERNET GATEWAY                            #
#                                                           #
#############################################################
# First you need to specify the name of a Tier 2 server.
# The current preferred way is to use one of these regional rotate addresses:
#       noam.aprs2.net          - for North America
#       soam.aprs2.net          - for South America
#       euro.aprs2.net          - for Europe and Africa
#       brazil.d2g.com
#IGSERVER noam.aprs2.net:14580
#ontario.aprs2.net:14580
#cx2sa.net:14580
#soam.aprs2.net
#204.110.191.232
#noam.aprs2.net
#IGLOGIN HP1PAR-10  19376
IGTXVIA 0 WIDE2-2
#
IGFILTER p/hp
#p/HP
#m/600
FILTER IG 0 t/poimqstunw
IGTXLIMIT 6 10
EOF
########################
cat > /lib/systemd/system/dmrid-mmdvm.service  <<- "EOF"
[Unit]
Description=DMRIDupdate MMDVMHost
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=/opt/MMDVMHost/DMRIDUpdate.sh
[Install]
WantedBy=multi-user.target
EOF
###################
cat > /lib/systemd/system/mmdvmh.service  <<- "EOF"
[Unit]
Description=MMDVM Host Service
After=syslog.target network.target
[Service]
User=root
WorkingDirectory=/opt/MMDVMHost
#ExecStartPre=/bin/sleep 10
ExecStart=/opt/MMDVMHost/MMDVMHost /opt/MMDVMHost/MMDVM.ini
#ExecStart=/usr/bin/screen -S MMDVMHost -D -m /home/MMDVMHost/MMDVMHost /home/M$
ExecStop=/usr/bin/screen -S MMDVMHost -X quit
[Install]
WantedBy=multi-user.target
EOF
################
cat > /lib/systemd/system/direwolf.service  <<- "EOF"
[Unit]
Description=DireWolf is a software "soundcard" modem/TNC and APRS decoder
Documentation=man:direwolf
AssertPathExists=/opt/direwolf/dw.conf
[Unit]
Description=Direwolf Service
#Wants=network-online.target
After=sound.target syslog.target
#network-online.target
[Service]
User=root
ExecStart=sudo direwolf -c /opt/direwolf/dw.conf
#ExecStart=/usr/bin/direwolf -t 0 -c /opt/direwolf/dw.conf
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=direwolf
[Install]
WantedBy=multi-user.target
EOF
#####
cat > /lib/systemd/system/dmrid-ysf2dmr.service  <<- "EOF"
[Unit]
Description=DMRIDupdate YSF2DMR
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=/opt/YSF2DMR/DMRIDUpdate.sh
[Install]
WantedBy=multi-user.target
EOF
#########
cat > /lib/systemd/system/direwolf-rtl.service  <<- "EOF"
[Unit]
Description=Direwolf-RTL Service
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=/opt/direwolf/rtl.sh
# | direwolf -c /home/pi/direwolf/sdr.conf
[Install]
WantedBy=multi-user.target
#ExecStart= /usr/local/bin/rtl_fm -M fm -f 144.39M -p 0 -s 24000 -g 42 - | /usr/local/bin/direwolf-rtl -c /home/pi/direwolf/sdr.conf -r 24000 -D 1 -B 1200 -
EOF
#############

cat > /lib/systemd/system/multimon-rtl.service  <<- "EOF"
[Unit]
Description=Direwolf-RTL Service
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=sudo pymultimonaprs
[Install]
WantedBy=multi-user.target
EOF
#####################
cat > /lib/systemd/system/ysf2dmr.service  <<- "EOF"
[Unit]
Description=YSF2DMR Service
After=syslog.target network.target
[Service]
User=root
WorkingDirectory=/opt/YSF2DMR
ExecStartPre=/bin/sleep 30
ExecStart=/opt/YSF2DMR/YSF2DMR /opt/YSF2DMR/YSF2DMR.ini
[Install]
WantedBy=multi-user.target
EOF
############

###############
cat > /opt/MMDVMHost/MMDVM.ini  <<- "EOF"
[General]
Callsign=HP1PAR
Id=714000000
Timeout=180
Duplex=0
ModeHang=3
#RFModeHang=10
#NetModeHang=3
Display=None
#Display=OLED
Daemon=0
[Info]
RXFrequency=438800000
TXFrequency=438800000
Power=1
# The following lines are only needed if a direct connection to a DMR master is being used
Latitude=0.0
Longitude=0.0
Height=0
Location=Panama
Description=Multi-Mode-MMDVM
URL=www.google.co.uk
[Log]
# Logging levels, 0=No logging
DisplayLevel=1
FileLevel=1
FilePath=/var/log/mmdvm
FileRoot=MMDVMHost
FileRotate=1
[CW Id]
Enable=0
Time=10
# Callsign=
[DMR Id Lookup]
File=/opt/MMDVMHost/DMRIds.dat
Time=24
[NXDN Id Lookup]
File=NXDN.csv
Time=24
[Modem]
# Port=/dev/ttyACM0
Port=/dev/ttyAMA0
#Port=\\.\COM4
#Protocol=uart
# Address=0x22
TXInvert=1
RXInvert=0
PTTInvert=0
TXDelay=100
RXOffset=0
TXOffset=0
DMRDelay=0
RXLevel=50
TXLevel=50
RXDCOffset=0
TXDCOffset=0
RFLevel=50
# CWIdTXLevel=50
# D-StarTXLevel=50
DMRTXLevel=50
YSFTXLevel=50
# P25TXLevel=50
# NXDNTXLevel=50
# POCSAGTXLevel=50
FMTXLevel=50
RSSIMappingFile=RSSI.dat
UseCOSAsLockout=0
Trace=0
Debug=0
[Transparent Data]
Enable=0
RemoteAddress=127.0.0.1
RemotePort=40094
LocalPort=40095
# SendFrameType=0
[UMP]
Enable=0
# Port=\\.\COM4
Port=/dev/ttyACM1
[D-Star]
Enable=0
Module=C
SelfOnly=0
AckReply=1
AckTime=750
AckMessage=0
ErrorReply=1
RemoteGateway=0
# ModeHang=10
WhiteList=
[DMR]
Enable=1
Beacons=0
BeaconInterval=60
BeaconDuration=3
ColorCode=1
SelfOnly=0
EmbeddedLCOnly=1
DumpTAData=0
# Prefixes=234,235
# Slot1TGWhiteList=
# Slot2TGWhiteList=
CallHang=3
TXHang=4
# ModeHang=10
# OVCM Values, 0=off, 1=rx_on, 2=tx_on, 3=both_on, 4=force off
# OVCM=0
[System Fusion]
Enable=1
LowDeviation=0
SelfOnly=0
TXHang=4
RemoteGateway=1
# ModeHang=10
[P25]
Enable=0
NAC=293
SelfOnly=0
OverrideUIDCheck=0
RemoteGateway=0
TXHang=5
# ModeHang=10
[NXDN]
Enable=0
RAN=1
SelfOnly=0
RemoteGateway=0
TXHang=5
# ModeHang=10
[POCSAG]
Enable=0
Frequency=439987500
[FM]
Enable=0
# Callsign=HP1PAR
CallsignSpeed=20
CallsignFrequency=1000
CallsignTime=10
CallsignHoldoff=0
CallsignHighLevel=50
CallsignLowLevel=20
CallsignAtStart=1
CallsignAtEnd=1
CallsignAtLatch=0
RFAck=K
ExtAck=N
AckSpeed=20
AckFrequency=1750
AckMinTime=4
AckDelay=1000
AckLevel=50
# Timeout=180
TimeoutLevel=80
CTCSSFrequency=88.4
CTCSSThreshold=30
# CTCSSHighThreshold=30
# CTCSSLowThreshold=20
CTCSSLevel=20
KerchunkTime=0
HangTime=7
AccessMode=1
COSInvert=0
RFAudioBoost=1
MaxDevLevel=90
ExtAudioBoost=1
[D-Star Network]
Enable=0
GatewayAddress=127.0.0.1
GatewayPort=20010
LocalPort=20011
# ModeHang=3
Debug=0
[DMR Network]
Enable=1
# Type may be either 'Direct' or 'Gateway'. When Direct you must provide the Master's
# address as well as the Password, and for DMR+, Options also.
Type=Direct
Address=74.91.114.19
Port=62031
#Local=62032
Password=*********
Jitter=360
Slot1=1
Slot2=1
# Options=
# ModeHang=3
Debug=0
[System Fusion Network]
Enable=1
LocalAddress=127.0.0.1
#LocalPort=3200
GatewayAddress=europelink.pa7lim.nl
GatewayPort=42000
# ModeHang=3
Debug=0
[P25 Network]
Enable=0
GatewayAddress=127.0.0.1
GatewayPort=42020
LocalPort=32010
# ModeHang=3
Debug=0
[NXDN Network]
Enable=0
Protocol=Icom
LocalAddress=127.0.0.1
LocalPort=14021
GatewayAddress=127.0.0.1
GatewayPort=14020
# ModeHang=3
Debug=0
[POCSAG Network]
Enable=0
LocalAddress=127.0.0.1
LocalPort=3800
GatewayAddress=127.0.0.1
GatewayPort=4800
# ModeHang=3
Debug=0
[TFT Serial]
# Port=modem
Port=/dev/ttyAMA0
Brightness=50
[HD44780]
Rows=2
Columns=16
# For basic HD44780 displays (4-bit connection)
# rs, strb, d0, d1, d2, d3
Pins=11,10,0,1,2,3
# Device address for I2C
I2CAddress=0x20
# PWM backlight
PWM=0
PWMPin=21
PWMBright=100
PWMDim=16
DisplayClock=1
UTC=0
[Nextion]
# Port=modem
Port=/dev/ttyAMA0
Brightness=50
DisplayClock=1
UTC=0
#Screen Layout: 0=G4KLX 2=ON7LDS
ScreenLayout=2
IdleBrightness=20
[OLED]
Type=3
Brightness=1
Invert=0
Scroll=0
Rotate=1
Cast=0
LogoScreensaver=0
[LCDproc]
Address=localhost
Port=13666
#LocalPort=13667
DimOnIdle=0
DisplayClock=1
UTC=0
[Lock File]
Enable=0
File=/tmp/MMDVM_Active.lck
[Remote Control]
Enable=0
Address=127.0.0.1
Port=7642
EOF
########
cat > /opt/YSF2DMR/YSF2DMR.ini  <<- "EOF"
[Info]
RXFrequency=435000000
TXFrequency=435000000
Power=1
Latitude=0.0
Longitude=0.0
Height=0
Location=Panama
Description=Multi-Mode
URL=www.google.co.uk
[YSF Network]
Callsign=HP1PAR
Suffix=ND
#Suffix=RPT
DstAddress=127.0.0.1
DstPort=42000
LocalAddress=127.0.0.1
#LocalPort=42013
EnableWiresX=0
RemoteGateway=0
HangTime=1000
WiresXMakeUpper=0
# RadioID=*****
# FICHCallsign=2
# FICHCallMode=0
# FICHBlockTotal=0
# FICHFrameTotal=6
# FICHMessageRoute=0
# FICHVOIP=0
# FICHDataType=2
# FICHSQLType=0
# FICHSQLCode=0
DT1=1,34,97,95,43,3,17,0,0,0
DT2=0,0,0,0,108,32,28,32,3,8
Daemon=0
[DMR Network]
Id=714000000
#XLXFile=XLXHosts.txt
#XLXReflector=950
#XLXModule=D
StartupDstId=714
# For TG call: StartupPC=0
StartupPC=0
Address=74.91.114.19
Port=62031
Jitter=500
EnableUnlink=0
TGUnlink=4000
PCUnlink=0
# Local=62032
Password=****************
# Options=
TGListFile=TGList-DMR.txt
Debug=0
[DMR Id Lookup]
File=/opt/YSF2DMR/DMRIds.dat
Time=24
DropUnknown=0
[Log]
# Logging levels, 0=No logging
DisplayLevel=1
FileLevel=1
FilePath=/var/log/ysf2dmr/
FileRoot=YSF2DMR
[aprs.fi]
Enable=0
AprsCallsign=HP1PAR
Server=noam.aprs2.net
#Server=euro.aprs2.net
Port=14580
Password=12345
APIKey=APIKey
Refresh=240
Description=APRS Description
EOF
###################
cat > /opt/YSFReflector/YSFReflector.ini  <<- "EOF"
[General]
Daemon=0
[Info]
# Remember to register your YSFReflector at:
# https://register.ysfreflector.de
# Id=5 digits only
Name=Nombre del reflector sin espacios - 16 characters max
Description=descripcion del reflector, si soporta espacios 14 characters max
[Log]
# Logging levels, 0=No logging
DisplayLevel=1
FileLevel=1
FilePath=/var/log/ysf/
FileRoot=YSFReflector
FileRotate=1
[Network]
Port=42000
Debug=0
#[Block List]
#File=BlockList.txt
#Time=5
EOF
##########
cat > /etc/pymultimonaprs.json  <<- "EOF"
{
        "callsign": "HP1PAR-10",
        "passcode": "19384",
        "gateway": ["igates.aprs.fi:14580","noam.aprs2.net:14580"],
        "preferred_protocol": "any",
        "append_callsign": true,
        "source": "rtl",
        "rtl": {
                "freq": 144.390,
                "ppm": 0,
                "gain": 24,
                "offset_tuning": false,
                "device_index": 0
        },
        "alsa": {
                "device": "default"
        },
        "beacon": {
                "lat": 8.5002,
                "lng": -80.3472,
                "table": "/",
                "symbol": "r",
                "comment": "APRS RX-IGATE / Raspbian Proyect by HP1PAR",
                "status": {
                        "text": "",
                        "file": false
                },
                "weather": false,
                "send_every": 300,
                "ambiguity": 0
        }
}
EOF
#######
cat > /opt/ionsphere/ionosphere-raspberry-pi/config/config.yml  <<- "EOF"
rtl:
  path: "rtl_fm"
  frequency: "144.390M"
  gain: "49.6"
  ppm-error: "0"
  squelch-level: "0"
  sample-rate: "22050"
  additional-flags: ""
multimon:
  path: "multimon-ng"
  additional-flags: ""
beacon:
  enabled: false
  call-sign: ""
  interval: 30m
  comment: ""
handlers:
- id: "4967ade5-7a97-416f-86bf-6e2ae8a5e581"
  name: "stdout"
- id: "b67ac5d5-3612-4618-88a9-a63d36a1777c"
  name: "aprsis"
  options:
    enabled: true
    server: "igates.aprs.fi:14580"
    call-sign: "HP1PAR-10"
    passcode: "19384"
    filter: ""
EOF
#############
cat > /opt/direwolf/rtl.sh  <<- "EOF"
#!/bin/sh
PATH=/bin:/usr/bin:/usr/local/bin
unset LANG
rtl_fm -M fm -f 144.39M -p 0 -s 24000 -g 42 - | /usr/local/bin/direwolf -c /opt/direwolf/sdr.conf -r 24000 -D 1 -B 1200 -
EOF
sudo chmod +x /opt/direwolf/rtl.sh
#############
cat > /var/www/web-mmdvm/index.php <<- "EOF"
<?php
header("Cache-Control: no-cache, must-revalidate");
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");
// do not touch this includes!!! Never ever!!!
include "config/config.php";
if (!defined("LOCALE"))
   define("LOCALE", "en_GB");
include "locale/".LOCALE."/settings.php";
$codeset = "UTF8";
putenv('LANG='.LANG_LOCALE.'.'.$codeset);
putenv('LANGUAGE='.LANG_LOCALE.'.'.$codeset);
bind_textdomain_codeset('messages', $codeset);
bindtextdomain('messages', dirname(__FILE__).'/locale/');
setlocale(LC_ALL, LANG_LOCALE.'.'.$codeset);
textdomain('messages');
include("config/networks.php");
include "include/tools.php";
startStopwatch();
showLapTime("Start of page");
include "include/functions.php";
include "include/init.php";
include "version.php";
?>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
     <meta name="viewport" content="width=device-width, initial-scale=0.6,maximum-scale=1, user-scalable=yes">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script>
    <!-- Das neueste kompilierte und minimierte CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css">
    <!-- Optionales Theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/latest/css/bootstrap-theme.min.css">
    <!-- Das neueste kompilierte und minimierte JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="https://cdn.datatables.net/1.10.13/css/jquery.dataTables.min.css">
    <script type="text/javascript" src="https://cdn.datatables.net/1.10.13/js/jquery.dataTables.min.js"></script>
    <!-- Default-CSS -->
    <link rel="stylesheet" href="css/style.css">
    <!-- CSS for tooltip display -->
    <link rel="stylesheet" href="css/tooltip.css">
    <!-- CSS for monospaced fonts in tables -->
    <link rel="stylesheet" href="css/monospacetables.css">
   <style>
   .nowrap {
      white-space:nowrap
   }
   </style>
    <title><?php echo getCallsign($mmdvmconfigs) ?> - MMDVM-Dashboard by DG9VH</title>
  </head>
  <body>
  <div class="page-header" style="position:relative;">
  <h1><small>MMDVM-Dashboard by DG9VH  <?php
  echo _("for");
  if (getConfigItem("General", "Duplex", $mmdvmconfigs) == "1") {
   echo " "._("Repeater");
  } else {
   echo " "._("Hotspot");
  }
  ?>:</small>  <?php echo getCallsign($mmdvmconfigs) ?><br>
  <small>DMR-Id: <?php echo getDMRId($mmdvmconfigs) ?></small></h1><hr>
  <h5>MMDVMHost by G4KLX Version: <?php echo getMMDVMHostVersion() ?><br>Firmware: <?php echo getFirmwareVersion();
  if (defined("ENABLEDMRGATEWAY")) {
?>
<br>DMRGateway by G4KLX Version: <?php echo getDMRGatewayVersion(); 
  } ?>
  <?php
  if (defined("JSONNETWORK")) {
    $key        = recursive_array_search(getDMRNetwork(),$networks);
    $network    = $networks[$key];
    echo "<br>";
    echo _("Configuration").": ".$network['label'];
    
  } else {
    if (strlen(getDMRNetwork()) > 0 ) {
      echo "<br>";
      echo _("DMR-Network: ").getDMRNetwork();
    }
  }
  ?></h5>
  <?php
  $logourl = "";
  if (defined("JSONNETWORK")) {
    $key        = recursive_array_search(getDMRNetwork(),$networks);
    $network    = $networks[$key];
    $logourl    = $network['logo'];
  } else {
    if (getDMRNetwork() == "BrandMeister") {
      if (constant('BRANDMEISTERLOGO') !== NULL) {
        $logourl = BRANDMEISTERLOGO;
      }
    }
    if (getDMRNetwork() == "DMRplus") {
      if (constant('DMRPLUSLOGO') !== NULL) {
        $logourl = DMRPLUSLOGO;
      }
    }
  }
  if ($logourl == "") {
   $logourl = LOGO;
  }
  if ($logourl !== "") {
?>
<div id="Logo" style="position:absolute;top:-43px;right:10px;"><img src="<?php echo $logourl ?>" width="100px" style="width:100px; border-radius:10px;box-shadow:2px 2px 2px #808080; padding:1px;background:#FFFFFF;border:1px solid #808080;" border="0" hspace="10" vspace="50" align="absmiddle"></div>
<?php
  }
?>
</div>
<?php
if (defined("ENABLEMANAGEMENT")) {
?>
  <button onclick="window.location.href='./scripts/log.php'"  type="button" class="btn btn-default navbar-btn"><span class="glyphicon glyphicon-folder-open" aria-hidden="true"></span>&nbsp;<?php echo _("View Log"); ?></button>
  <button onclick="window.location.href='./scripts/rebootmmdvm.php'"  type="button" class="btn btn-default navbar-btn"><span class="glyphicon glyphicon-refresh" aria-hidden="true"></span>&nbsp;<?php echo _("Reboot MMDVMHost"); ?></button>
  <button onclick="window.location.href='./scripts/reboot.php'"  type="button" class="btn btn-default navbar-btn"><span class="glyphicon glyphicon-repeat" aria-hidden="true"></span>&nbsp;<?php echo _("Reboot System"); ?></button>
  <button onclick="window.location.href='./scripts/halt.php'"  type="button" class="btn btn-default navbar-btn"><span class="glyphicon glyphicon-off" aria-hidden="true"></span>&nbsp;<?php echo _("ShutDown System"); ?></button>
<?php
}
if (defined("ENABLENETWORKSWITCHING")) {
  if (defined("JSONNETWORK")) {
  	echo '  <br>';
  	foreach ($networks as $network) {
  	  echo '  <button onclick="window.location.href=\'./scripts/switchnetwork.php?network='.$network['ini'].'\'"  type="button" ';
          if (getDMRNetwork() == $network['label'] )
            echo 'class="btn btn-active navbar-btn">';
          else
            echo 'class="btn btn-default navbar-btn">';
          echo '<span class="glyphicon glyphicon-link" aria-hidden="true"></span>&nbsp;'.$network['label'].'</button>';
  	}
  	
  } else {
?>
  <button onclick="window.location.href='./scripts/switchnetwork.php?network=DMRPLUS'"  type="button" <?php
      if (getDMRNetwork() == "DMRplus" )
        echo 'class="btn btn-active navbar-btn">';
      else
        echo 'class="btn btn-default navbar-btn">'; ?><span class="glyphicon glyphicon-plus" aria-hidden="true"></span>&nbsp;<?php echo _("DMRplus"); ?></button>
  <button onclick="window.location.href='./scripts/switchnetwork.php?network=BRANDMEISTER'"  type="button" <?php
      if (getDMRNetwork() == "BrandMeister" )
        echo 'class="btn btn-active navbar-btn">';
      else
        echo 'class="btn btn-default navbar-btn">'; ?><span class="glyphicon glyphicon-fire" aria-hidden="true"></span>&nbsp;<?php echo _("BrandMeister"); ?></button>
<?php
  }
  if (defined("ENABLEREFLECTORSWITCHING") && (getEnabled("DMR Network", $mmdvmconfigs) == 1) && recursive_array_search(gethostbyname(getConfigItem("DMR Network", "Address", $mmdvmconfigs)),getDMRplusDMRMasterList()) ) {
  	$reflectors = getDMRReflectors();
?>
  <form method = "get" action ="./scripts/switchreflector.php" class="form-inline" role="form">
  <div class="form-group">
  	<select id="reflector" name="reflector" class="form-control" style="width: 80px;">
<?php
    foreach ($reflectors as $reflector) {
	  if (isset($reflector[1]))
		echo'<option value="'.$reflector[0].'">'.mb_convert_encoding($reflector[1], "UTF-8", "ISO-8859-1").'</option>';
    }
?>
    </select>
    <button type="submit" class="btn btn-default navbar-btn"><span class="glyphicon glyphicon-refresh" aria-hidden="true"></span>&nbsp;<?php echo _("ReflSwitch"); ?></button>
  
  </div></form>
<?php
  }
}
checkSetup();
// Here you can feel free to disable info-sections by commenting out with // before include
include "include/txinfo.php";
showLapTime("txinfo");
if (!defined("SHOWCPU") AND !defined("SHOWDISK") AND !defined("SHOWRPTINFO") AND !defined("SHOWMODES") AND !defined("SHOWLH") AND !defined("SHOWLOCALTX")) {
   define("SHOWCPU", "on");
   define("SHOWDISK", "on");
   define("SHOWRPTINFO", "on");
   define("SHOWMODES", "on");
   define("SHOWLH", "on");
   define("SHOWLOCALTX", "on");	
}
if (defined("SHOWCUSTOM")) {
   print "<div class=\"panel panel-default\">\n";
   print "<div class=\"panel-heading\">";
   echo _("Custom Info");
   print "<span class=\"pull-right clickable\"><i class=\"glyphicon glyphicon-chevron-up\"></i></span></div>\n";
   print "<div class=\"panel-body\">\n";
   $custom = 'custom.php';
   if (file_exists($custom)) {
      include $custom;
   } else {
      print "<div class=\"alert alert-danger\" role=\"alert\">";
      echo _("File custom.php not found! Did you forget to create it?");
      print "</div>\n";
   }
   print "</div>\n";
   print "</div>\n";
}
if (defined("SHOWCPU")) {
   include "include/sysinfo_ajax.php";
   showLapTime("sysinfo");
}
if (defined("SHOWDISK")) {
   include "include/disk.php";
   showLapTime("disk");
}
if (defined("SHOWRPTINFO")) {
    include "include/repeaterinfo.php";
    showLapTime("repeaterinfo");
}
if (defined("SHOWMODES")) {
   include "include/modes.php";
   showLapTime("modes");
}
if (defined("SHOWLH")) {
   include "include/lh_ajax.php";
   showLapTime("lh_ajax");
}
if (defined("SHOWLOCALTX")) {
   include "include/localtx_ajax.php";
   showLapTime("localtx_ajax");
}
if (defined("SHOWDAPNET")) {
   include "include/dapnet_ajax.php";
   showLapTime("dapnet_ajax");
}
if (defined("ENABLEYSFGATEWAY")|| defined("ENABLEDMRGATEWAY")) {
   include "include/gatewayinfo.php";
   showLapTime("gatewayinfo");
}
?>
   <div class="panel panel-info">
<?php
$lastReload = new DateTime();
$lastReload->setTimezone(new DateTimeZone(TIMEZONE));
echo "MMDVMHost-Dashboard V ".VERSION." | "._("Last Reload")." ".$lastReload->format('Y-m-d, H:i:s')." (".TIMEZONE.")";
echo '<!--Page generated in '.getLapTime().' seconds.-->';
?> |
<?php
if (!isset($_GET['stoprefresh'])) {
   echo '<a href="?stoprefresh">'._("stop refreshing").'</a>';
} else {
   echo '<a href=".">'._("start refreshing").'</a>';
}
?>
 | <?php echo _("get your own at:");?> <a href="https://github.com/dg9vh/MMDVMHost-Dashboard">https://github.com/dg9vh/MMDVMHost-Dashboard</a> | <?php echo _("Follow me");?> <a href="https://twitter.com/DG9VH">@DG9VH</a> | <a href="credits.php"><?php echo _("Credits");?></a>
   </div>
   <noscript>
    For full functionality of this site it is necessary to enable JavaScript.
    Here are the <a href="http://www.enable-javascript.com/" target="_blank">
    instructions how to enable JavaScript in your web browser</a>.
   </noscript>
  </body>
  <script>
  		$(document).on('click', '.panel-heading span.clickable', function(e){
    var $this = $(this);
	if(!$this.hasClass('panel-collapsed')) {
		$this.parents('.panel').find('.panel-body').slideUp();
		$this.addClass('panel-collapsed');
		$this.find('i').removeClass('glyphicon-chevron-up').addClass('glyphicon-chevron-down');
	} else {
		$this.parents('.panel').find('.panel-body').slideDown();
		$this.removeClass('panel-collapsed');
		$this.find('i').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-up');
	}
})
  </script>
</html>
<?php
   showLapTime("End of Page");
?>
EOF
#####################
cat > /var/www/web-ysf/index.php <<- "EOF"
<?php
$time = microtime();
$time = explode(' ', $time);
$time = $time[1] + $time[0];
$start = $time;
// do not touch this includes!!! Never ever!!!
include "config/config.php";
include "include/tools.php";
include "include/functions.php";
include "include/init.php";
include "version.php";
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta name="description" content="YSF-Reflector Dashboard by DG9VH">
  <meta name="author" content="DG9VH, KC1AWV">
  <meta http-equiv="refresh" content="<?php echo REFRESHAFTER?>">
  <!-- So refresh works every time -->
  <meta http-equiv="expires" content="0">
  <title><?php echo getConfigItem("Info", "Name", $configs); ?> - YSFReflector-Dashboard by DG9VH</title>
  <!-- Bootstrap core CSS -->
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
  <!-- Bootstrap core JavaScript -->
  <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
  <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
  <!-- Datatables -->
  <link rel="stylesheet" href="https://cdn.datatables.net/1.10.21/css/jquery.dataTables.min.css">
  <script type="text/javascript" src="https://cdn.datatables.net/1.10.21/js/jquery.dataTables.min.js"></script>
</head>
<body>
  <!-- Navigation -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark static-top">
    <div class="container-fluid">
      <span class="float:left">
        <a class="navbar-brand" href="#">YSFReflector-Dashboard by DG9VH for Reflector: <?php echo getConfigItem("Info", "Name", $configs); ?> / <?php echo getConfigItem("Info", "Description", $configs); ?> (#<?php echo getConfigItem("Info", "Id", $configs); ?>)</a>
      </span>
      <span class="navbar-brand float:right">
        YSFReflector by G4KLX Version: <?php  echo getYSFReflectorVersion(); ?>
      </span>
    </div>
  </nav>
  <!-- Page Content -->
  <div class="container-fluid">
    <?php
      checkSetup();
    ?>
    <div class="row">
      <div class="col-10">
        <?php
          include "include/txinfo.php";
        ?>
      </div>
      <?php if (LOGO !== "") { ?>
      <div id="Logo" class="col-2">
        <img src="<?php echo LOGO ?>" width="125px" style="width:125px; border-radius:10px;box-shadow:2px 2px 2px #808080; padding:1px;background:#FFFFFF;border:1px solid #808080;" border="0" hspace="10" vspace="10" align="justify-content-center">
      </div>
      <?php } else { ?>
      <div id="Logo" class="col-2">
        <h3 class="text-center">YSF-Reflector<br />Dashboard</h3>
      </div>
      <?php } ?>
    </div>
  </div>
    <div class="row">
      <div class="col">
        <?php
          include "include/sysinfo.php";
        ?>
      </div>
      <div class="col">
        <?php
          include "include/disk.php";
        ?>
      </div>
    </div>
    <?php
      include "include/gateways.php";
      include "include/lh.php";
      include "include/allheard.php";
      if (defined("SHOWOLDMHEARD")) {
        include "include/oldheard.php";
      }
    ?>
  </div>
  <div class="card">
    <div class="card-body">
      <?php
        $lastReload = new DateTime();
        $lastReload->setTimezone(new DateTimeZone(TIMEZONE));
        echo "YSFReflector-Dashboard V ".VERSION." | Last Reload ".$lastReload->format('Y-m-d, H:i:s')." (".TIMEZONE.")";
        $time = microtime();
        $time = explode(' ', $time);
        $time = $time[1] + $time[0];
        $finish = $time;
        $total_time = round(($finish - $start), 4);
        echo '<!--Page generated in '.$total_time.' seconds.-->';
      ?> | get your own at: <a href="https://github.com/dg9vh/YSFReflector-Dashboard">https://github.com/dg9vh/YSFReflector-Dashboard</a>
    </div>
  </div>
</body>
</html>
EOF
######################
sudo mkdir /var/www/web-ysf/config
#rm /var/www/web-ysf/config/config.php
cat > /var/www/web-ysf/config/config.php <<- "EOF"
<?php
# This is an auto-generated config file!
# Be careful, when manually editing this!
date_default_timezone_set('UTC');
define("YSFREFLECTORLOGPATH", "/var/log/ysf/");
define("YSFREFLECTORLOGPREFIX", "YSFReflector");
define("YSFREFLECTORINIPATH", "/opt/YSFReflector/");
define("YSFREFLECTORINIFILENAME", "YSFReflector.ini");
define("YSFREFLECTORPATH", "/usr/local/bin/");
define("TIMEZONE", "America/Panama");
define("LOGO", "https://cdn-bio.qrz.com/c/hp3icc/ysf_logo_sq_243px.jpg");
define("REFRESHAFTER", "30");
define("SHOWOLDMHEARD", "30");
define("TEMPERATUREHIGHLEVEL", "60");
define("SHOWQRZ", "on");
?>
EOF
##########

sudo mkdir /var/www/web-mmdvm/config
cat > /var/www/web-mmdvm/config/config.php <<- "EOF"
<?php
# This is an auto-generated config-file!
# Be careful, when manual editing this!
date_default_timezone_set('UTC');
define("MMDVMLOGPATH", "/var/log/mmdvm/");
define("MMDVMINIPATH", "/opt/MMDVMHost/");
define("MMDVMINIFILENAME", "MMDVM.ini");
define("MMDVMHOSTPATH", "/usr/local/bin");
define("ENABLEXTDLOOKUP", "on");
define("DMRIDDATPATH", "/opt/MMDVMHost/DMRIds.dat");
define("YSFGATEWAYLOGPATH", "");
define("YSFGATEWAYLOGPREFIX", "");
define("YSFGATEWAYINIPATH", "");
define("YSFGATEWAYINIFILENAME", "");
define("YSFHOSTSPATH", "");
define("YSFHOSTSFILENAME", "");
define("DMRGATEWAYLOGPATH", "");
define("DMRGATEWAYLOGPREFIX", "");
define("DMRGATEWAYINIPATH", "");
define("DMRGATEWAYPATH", "");
define("DMRGATEWAYINIFILENAME", "");
define("DAPNETGATEWAYLOGPATH", "");
define("DAPNETGATEWAYLOGPREFIX", "");
define("DAPNETGATEWAYINIPATH", "");
define("DAPNETGATEWAYPATH", "");
define("DAPNETGATEWAYINIFILENAME", "");
define("LINKLOGPATH", "");
define("IRCDDBGATEWAY", "");
define("TIMEZONE", "America/Panama");
define("LOCALE", "en_US");
define("LOGO", "https://cdn-bio.qrz.com/c/hp3icc/rsz_1logo_cat_mmdvm.jpg");
define("DMRPLUSLOGO", "");
define("BRANDMEISTERLOGO", "");
define("REFRESHAFTER", "30");
define("SHOWRPTINFO", "on");
define("SHOWMODES", "on");
define("SHOWLH", "on");
define("SHOWLOCALTX", "on");
define("TEMPERATUREHIGHLEVEL", "60");
define("SWITCHNETWORKUSER", "");
define("SWITCHNETWORKPW", "");
define("VIEWLOGUSER", "pi");
define("VIEWLOGPW", "raspberry");
define("HALTUSER", "");
define("HALTPW", "");
define("REBOOTUSER", "");
define("REBOOTPW", "");
define("RESTARTUSER", "");
define("RESTARTPW", "");
define("REBOOTYSFGATEWAY", "");
define("REBOOTMMDVM", "");
define("REBOOTSYS", "");
define("HALTSYS", "");
define("POWERONLINEPIN", "");
define("POWERONLINESTATE", "");
define("SHOWQRZ", "on");
define("RSSI", "avg");
?>
EOF


###############################################
##############################
#dvswitch

cd /opt

wget http://dvswitch.org/buster

chmod +x buster

./buster

apt-get update -y

apt-get install dvswitch-server -y


####
cat > /opt/MMDVM_Bridge/MMDVM_Bridge.ini  <<- "EOF"
[General]
Callsign=N0CALL
Id=1234567
Timeout=180
Duplex=0
[Info]
RXFrequency=147000000
TXFrequency=147000000
Power=1
Latitude=41.7333
Longitude=-50.3999
Height=0
Location=Panama
Description=MMDVM_Bridge
URL=https://groups.io/g/DVSwitch
[Log]
# Logging levels, 0=No logging, 1=Debug, 2=Message, 3=Info, 4=Warning, 5=Error, 6=Fatal
DisplayLevel=1
FileLevel=2
FilePath=/var/log/mmdvm
FileRoot=MMDVM_Bridge
[DMR Id Lookup]
File=/var/lib/mmdvm/DMRIds.dat
Time=24
[NXDN Id Lookup]
File=/var/lib/mmdvm/NXDN.csv
Time=24
[Modem]
Port=/dev/null
RSSIMappingFile=/dev/null
Trace=0
Debug=0
[D-Star]
Enable=0
Module=B
[DMR]
Enable=0
ColorCode=1
EmbeddedLCOnly=1
DumpTAData=0
[System Fusion]
Enable=0
[P25]
Enable=0
NAC=293
[NXDN]
Enable=0
RAN=1
Id=12345
[D-Star Network]
Enable=0
GatewayAddress=127.0.0.1
GatewayPort=20010
LocalPort=20011
Debug=0
[DMR Network]
Enable=0
Address=hblink.dvswitch.org
Port=62031
Jitter=360
Local=62032
Password=passw0rd
# for DMR+ see https://github.com/DVSwitch/MMDVM_Bridge/blob/master/DOC/DMRplus_startup_options.md
# for XLX the syntax is: Options=XLX:4009
# Options=
Slot1=0
Slot2=1
Debug=0
[System Fusion Network]
Enable=0
LocalAddress=0
LocalPort=3200
GatewayAddress=127.0.0.1
GatewayPort=4200
Debug=0
[P25 Network]
Enable=0
GatewayAddress=127.0.0.1
GatewayPort=42020
LocalPort=32010
Debug=0
[NXDN Network]
Enable=0
#LocalAddress=127.0.0.1
Debug=0
LocalPort=14021
GatewayAddress=127.0.0.1
GatewayPort=14020
EOF
####
##################
##DMRI DVS service 
cat > /lib/systemd/system/dmrid-dvs.service <<- "EOF"
[Unit]
Description=DMRIDupdate DVS
Wants=network-online.target
After=syslog.target network-online.target
[Service]
User=root
#ExecStartPre=/bin/sleep 1800
ExecStart=/opt/MMDVM_Bridge/DMRIDUpdate.sh
[Install]
WantedBy=multi-user.target
EOF
##########
#web

sudo groupadd www-data

sudo usermod -G www-data -a pi

sudo chown -R www-data:www-data /var/www/html

sudo chmod -R 775 /var/www/html
#############################


mkdir /var/www/web-dvs
chmod +777 /var/www/web-dvs
chmod +777 /var/www/html/*
sudo cp -r /var/www/html/* /var/www/web-dvs/
sudo rm -r /var/www/html/*
##

cat > /opt/DMRIDUpdate.sh <<- "EOF"
#! /bin/bash
###############################################################################
#
#                              CONFIGURATION
#
# Full path to DMR ID file, without final slash
DMRIDPATH=/opt
DMRIDFILE=${DMRIDPATH}/DMRIds.dat
# DMR IDs now served by RadioID.net
#DATABASEURL='https://ham-digital.org/status/users.csv'
DATABASEURL='https://www.radioid.net/static/user.csv'
#
# How many DMR ID files do you want backed up (0 = do not keep backups)
DMRFILEBACKUP=1
#
# Command line to restart MMDVMHost
RESTARTCOMMAND="systemctl restart mmdvmhost.service"
# RESTARTCOMMAND="killall MMDVMHost ; /path/to/MMDVMHost/executable/MMDVMHost /path/to/MMDVM/ini/file/MMDVM.ini"
###############################################################################
#
# Do not edit below here
#
###############################################################################
# Check we are root
if [ "$(id -u)" != "0" ]
then
        echo "This script must be run as root" 1>&2
        exit 1
fi
# Create backup of old file
if [ ${DMRFILEBACKUP} -ne 0 ]
then
        cp ${DMRIDFILE} ${DMRIDFILE}.$(date +%d%m%y)
fi
# Prune backups
BACKUPCOUNT=$(ls ${DMRIDFILE}.* | wc -l)
BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${DMRFILEBACKUP})
if [ ${BACKUPCOUNT} -gt ${DMRFILEBACKUP} ]
then
        for f in $(ls -tr ${DMRIDFILE}.* | head -${BACKUPSTODELETE})
        do
               rm $f
        done
fi
# Generate new file
curl ${DATABASEURL} 2>/dev/null | sed -e 's/\t//g' | awk -F"," '/,/{gsub(/ /, "", $2); printf "%s\t%s\t%s\n", $1, $2, $3}' | sed -e 's/\(.\) .*/\1/g' > ${DMRIDPATH}/DMRIds.tmp
NUMOFLINES=$(wc -l ${DMRIDPATH}/DMRIds.tmp | awk '{print $1}')
if [ $NUMOFLINES -gt 1 ]
then
   mv ${DMRIDPATH}/DMRIds.tmp ${DMRIDFILE}
else
   echo " ERROR during file update "
   rm ${DMRIDPATH}/DMRIds.tmp
fi
# Restart ysf2dmr
eval ${RESTARTCOMMAND}
EOF
#######

cp /opt/DMRIDUpdate.sh /opt/MMDVMHost/
cd /opt/MMDVMHost/
sudo sed -i 's/\/opt/\/opt\/MMDVMHost/' DMRIDUpdate.sh
sudo sed -i 's/systemctl restart mmdvmhost.service/systemctl restart mmdvmh.service/' DMRIDUpdate.sh


cp /opt/DMRIDUpdate.sh /opt/YSF2DMR/
cd /opt/YSF2DMR/
sudo sed -i 's/\/opt/\/opt\/YSF2DMR/' DMRIDUpdate.sh
sudo sed -i 's/systemctl restart mmdvmhost.service/systemctl restart ysf2dmr.service/' DMRIDUpdate.sh



cp /opt/DMRIDUpdate.sh /opt/MMDVM_Bridge/
cd /opt/MMDVM_Bridge/
sudo sed -i 's/\/opt/\/opt\/MMDVM_Bridge/' DMRIDUpdate.sh
sudo sed -i 's/systemctl restart mmdvmhost.service/systemctl restart mmdvm_bridge.service/' DMRIDUpdate.sh

rm /opt/DMRIDUpdate.sh

###########################
sudo systemctl stop mmdvm_bridge.service 
sudo systemctl stop dmrid-dvs.service 
sudo systemctl stop analog_bridge.service 
sudo systemctl disable analog_bridge.service 
sudo systemctl disable mmdvm_bridge.service 
sudo systemctl disable dmrid-dvs.service
sudo systemctl disable lighttpd.service
sudo systemctl stop lighttpd.service
sudo rm -r  /var/www/html/* 
###########################
cat > /etc/modprobe.d/raspi-blacklist.conf <<- "EOF"
blacklist snd_bcm2835
# blacklist spi and i2c by default (many users don't need them)
#blacklist spi-bcm2708
#blacklist i2c-bcm2708
blacklist snd-soc-pcm512x
blacklist snd-soc-wm8804
# dont load default drivers for the RTL dongle
blacklist dvb_usb_rtl28xxu
blacklist rtl_2832
blacklist rtl_2830
EOF
########


################################
cd /usr/share/alsa/
sudo sed -i 's/defaults.ctl.card 0/defaults.ctl.card 1/' alsa.conf
sudo sed -i 's/defaults.pcm.card 0/defaults.pcm.card 0/' alsa.conf
###################################

sudo chmod +777 /opt/*
sudo chmod +777 /opt/direwolf/*
sudo chmod +777 /opt/direwolf/dw.conf
sudo chmod +777 /opt/direwolf/sdr.conf
sudo chmod +777 /opt/direwolf/src/*
sudo chmod +777 /opt/MMDVMHost/*
sudo chmod +777 /opt/MMDVMHost/MMDVM.ini
sudo chmod +777 /opt/YSF2DMR/*
sudo chmod +777 /opt/YSF2DMR/YSF2DMR.ini
sudo chmod +777 /opt/ionsphere/*
sudo chmod +777 /opt/ionsphere/ionosphere-raspberry-pi/config/config.yml
sudo chmod +777 /opt/YSFReflector/*
sudo chmod +777 /opt/YSFReflector/YSFReflector.ini
sudo chmod +777 /opt/pymultimonaprs/* 
sudo chmod +777 /opt/multimon-ng/*
sudo chmod +777 /opt/kalibrate-rtl/*
sudo chmod +777 /opt/YSFClients/*
sudo chmod +777 /opt/MMDVM_CM/*
sudo chmod +777 /opt/MMDVM_Bridge/*
sudo chmod +777 /opt/MMDVM_Bridge/MMDVM_Bridge.ini
sudo chmod +777 /etc/pymultimonaprs.json

sudo chmod +x  /opt/MMDVM_Bridge/DMRIDUpdate.sh
sudo chmod +x  /opt/YSF2DMR/DMRIDUpdate.sh
sudo chmod +x  /opt/MMDVMHost/DMRIDUpdate.sh

sudo chmod 755 /lib/systemd/system/monp.service
sudo chmod 755 /lib/systemd/system/dmrid-ysf2dmr.service
sudo chmod 755 /lib/systemd/system/dmrid-dvs.service
sudo chmod 755 /lib/systemd/system/dmrid-mmdvm.service
sudo chmod 755 /lib/systemd/system/mmdvmh.service
sudo chmod 755 /lib/systemd/system/direwolf.service
sudo chmod 755 /lib/systemd/system/direwolf-rtl.service
sudo chmod 755 /lib/systemd/system/multimon-rtl.service
sudo chmod 755 /lib/systemd/system/ionos.service
sudo chmod 755 /lib/systemd/system/ysfr.service
sudo chmod 755 /lib/systemd/system/ysf2dmr.service

sudo systemctl daemon-reload

sudo systemctl enable monp.service
###################

chmod +x /bin/menu*



##########################

sudo timedatectl set-timezone America/Panama

#####
sudo cat > /boot/wpa_supplicant.conf <<- "EOF"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=PA
##################################################################
# 							         #
#  Favor tomar como referencia, las dos redes wifi  que aparecen #
#  abajo, puede editar con los datos de su red wifi o agregar un #
#  network nuevo, por cada red wifi nueva que quiera almacenar.  #
#  							         #
#  Raspbian proyect by HP1PAR, 73.			         #
#							         #
##################################################################
network={
        ssid="Coloque_aqui_nombre_de_red_wifi"
        psk="Coloque_aqui_la_clave_wifi"
}
network={
        ssid="WiFi-Net"
        psk="Panama310"
}
EOF
#######
cat > /tmp/completado.sh <<- "EOF"
#!/bin/bash
while : ; do
choix=$(whiptail --title "Instalador APPs HP1PAR" --menu "   Precione enter (return o intro) para finalizar la instalacion y reiniciar su equipo " 11 100 3 \
1 " Iniciar Reinicio de Raspberry " 3>&1 1>&2 2>&3)
exitstatus=$?
#on recupere ce choix
#exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $choix
else
    echo "You chose cancel."; break;
fi
# case : action en fonction du choix
case $choix in
1)
sudo reboot
;;
esac
done
exit 0
EOF
sudo chmod +x /tmp/completado.sh
sh /tmp/completado.sh


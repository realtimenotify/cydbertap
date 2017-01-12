<span id="anchor"></span>CydberTap

The CydberTap is a small cheap solution for forensic analysis based on Cider Drinking, Cyber Security and finding something to do with my pi zero.

The Goal is to create a small cheap forensic device for network defenders whether hobiests or proffesional.

Aims (Currently developing Aim 1 :-)

1: - Create an image for a pi zero that when plugged into a powered on (Windows) computer is recognised as a USB eternet device and automatically collects 30 minutes of inetwork traffic attempting to access the internernet.

2: - Automate removal of legitmate network traffic so only interesting stuff has to be looked at.

3: - Automatically perform a Memory capture without relying on compromising the computer.

4: - Automatic capture of logs, events, registry hives, etc.

5: - Automatically perform capture of files and/or directories.

6: - Automatically perform Full disk capture (Probably wont do this ;-)

References and thanks:
----------------------

-   [Andrew Mulholland gbaman](https://gist.github.com/gbaman/975e2db164b3ca2b51ae11e45e8fd40a)
-   [Samy Kamkar samyk](https://github.com/samyk)
-   James Woolley [www.jamesdotcom.com](http://www.jamesdotcom.com)

Hardware:
---------

-   Pi Zero     [thepihut.com](https://thepihut.com/collections/raspberry-pi-zero/products/raspberry-pi-zero?variant=14062715972)
-   Micro SD 32GB [(Samsung Micro SD on Amazon)](https://www.amazon.co.uk/gp/product/B00J29BR3Y/)
-   USB hub (micro USB to 3 port) [(3 port Hub on Amazon)](https://www.amazon.co.uk/Acasis-H027-Charging-Simultaneous-Transmisson/dp/B00SZNT0ZU/)
-   Ethernet. (Logic3) [(USB Ethernet adapter on Amazon)](https://www.amazon.co.uk/Logic-3-Ethernet-Adapter-Wii/dp/B002GYVTSU/)
-   Keyboard (and mouse)
-   HDMI Monitor

Software:
---------

-   Raspbian Jessie lite : <https://www.raspberrypi.org/downloads/raspbian/>
-   *Download cydbertap files from github: *<https://github.com/cydber-seth/cydbertap>* *
-   WINSCP (<https://winscp.net/eng/download.php>)
-   Putty (<http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html>)
-   Win32disimage (<https://sourceforge.net/projects/win32diskimager/files/latest/download>)

Image Build Process on windows PC:
----------------------------------

1.  Use win32diskimager to copy Raspbian Jessie Lite image to Micro SD
2.  Eject safely and place in pi zero.

Image Build Process on Linux PC:
----------------------------------

1.  mount micros SD card or use lsblk to determine if already mounted (Mine was sdb) change following "dd" comand to reflect img and card
2.  sudo dd if=2016-09-23-raspbian-jessie-lite.img of=/dev/sdb1
3.  Eject safely and place in pi zero.

Install process on the Pi
-------------------------

2.  Booted pi zero (let it do its resize and reboot)
3.  sudo raspi-config

        option 3 boot options
        -   option B1 desktop/cli
            -   option B2 console autologin

4.  back to main menu & option 7 advanced options

        -   option A4 enable SSH
            -   enable SSH

5.  back to main menu & option 7 advanced options

        -   option A3 change memory available to GPU
            -   set memory to 16 (Not sure if this helps or not and canny find original post)

6.  back to main menu

        -   Finish (and reboot)

7.  sudo apt-get update
8.  sudo apt-get upgrade
9.  sudo apt-get install tcpdump
10.  sudo apt-get install isc-dhcp-server
11.  sudo apt-get install dsniff
12.  sudo apt-get install screen
13.  putty’ed in to device to do the following:
14.  added the following to /etc/rc.local (before “exit 0”)

            # poisontap startup
            /bin/sh /home/pi/cydbertap/pi_startup.sh
            printf "defanged poison tap started up"
            sleep 5
            #kick off packet capture
            printf "Starting Packet Capture Script"
            /bin/sh /home/pi/cydbertap/capture-packets.sh &
            printf "Packet Capture should be running"

15.  added the following to /etc/network/interfaces

             \\nauto usb0\\nallow-hotplug usb0\\niface usb0 inet static\\n\\taddress 1.0.0.1\\n\\tnetmask 0.0.0.0

16.  added the following to /boot/config.txt

             dtoverlay=dwc2

17.  added the following to /etc/modules

             dwc2\ng_ether

18.  created file /home/pi/cydbertap/capture-packets.sh

            #!/bin/bash
            cd /home/pi/cydbertap
            count=1
            while [ $count -le 6 ] # splits 30 minutes across 6 files
            do
            if [ $count -le 6 ]
             then
             FILETIME=$(date +"%Y%m%d-%H%M%S") #gives date in format YYYYMMDD-HHMMSS
             FILENAME="PC-"$FILETIME".pcap" #Sets filename
             tcpdump -Z root -w $FILENAME -G 300 -W 1 #Runs TCPDump as root captures 5 mins
             fi
             (( count++ ))
            done

19.  chmod 755 /home/pi/cydbertap/capture-packets.sh

1.  created file /home/pi/cydbertap/pi\_startup.sh

            #!/bin/sh
            # PoisonTap by samy kamkar http://samy.pl/poisontap 01/08/2016
            # If you find this doesn't come up automatically as an ethernet device
            # change idVendor/idProduct to 0x04b3/0x4010
            cd /sys/kernel/config/usb_gadget/
            mkdir -p poisontap
            cd poisontap
            #echo 0x04b3 &gt; idVendor # IN CASE BELOW DOESN'T WORK
            #echo 0x4010 &gt; idProduct # IN CASE BELOW DOESN'T WORK
            echo 0x1d6b &gt; idVendor # Linux Foundation
            echo 0x0104 &gt; idProduct # Multifunction Composite Gadget
            echo 0x0100 &gt; bcdDevice # v1.0.0
            echo 0x0200 &gt; bcdUSB # USB2
            mkdir -p strings/0x409
            echo "badc0deddeadbeef" &gt; strings/0x409/serialnumber
            echo "Samy Kamkar" &gt; strings/0x409/manufacturer
            echo "PoisonTap" &gt; strings/0x409/product
            mkdir -p configs/c.1/strings/0x409
            echo "Config 1: ECM network" &gt; configs/c.1/strings/0x409/configuration
            echo 250 &gt; configs/c.1/MaxPower
            mkdir -p functions/acm.usb0
            ln -s functions/acm.usb0 configs/c.1/
            # End functions
            mkdir -p functions/ecm.usb0
            # first byte of address must be even
            HOST="48:6f:73:74:50:43"
            SELF="42:61:64:55:53:42"
            echo \$HOST &gt; functions/ecm.usb0/host_addr
            echo \$SELF &gt; functions/ecm.usb0/dev_addr
            ln -s functions/ecm.usb0 configs/c.1/
            ls /sys/class/udc &gt; UDC
            ifup usb0
            ifconfig usb0 up
            /sbin/route add -net 0.0.0.0/0 usb0
            /etc/init.d/isc-dhcp-server start
            /sbin/sysctl -w net.ipv4.ip_forward=1
            /sbin/iptables -t nat -A PREROUTING -i usb0 -p tcp --dport 80 -j REDIRECT --to-port 1337
            /usr/bin/screen -dmS dnsspoof /usr/sbin/dnsspoof -i usb0 port 53
            #/usr/bin/screen -dmS node /usr/bin/nodejs/home/pi/poisontap/pi_poisontap.js

1.  chmod 755/home/pi/cydbertap/pi_startup.sh

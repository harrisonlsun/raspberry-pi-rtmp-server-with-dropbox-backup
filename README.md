# raspberry-pi-rtmp-server-with-dropbox-backup

## Open Source License Acknowledgements 


This product contains software provided by NGINX and its contributors.

### NGINX
License: BSD 2-Clause License  
https://github.com/nginx/nginx  
Copyright (c) 2002-2021 Igor Sysoev  
Copyright (c) 2011-2022 Nginx, Inc. 

### NGINX RTMP Module
License: BSD 2-Clause License  
https://github.com/arut/nginx-rtmp-module  
Copyright (c) 2012-2014, Roman Arutyunyan  



## Setup from Command Line

### Introduction
This setup utilizes a Raspberry Pi 3 Model B as an RTMP server. Video data is streamed to the RTMP server by IP cameras via the local network and each camera is assigned a unique address rtmp://192.168.1.XX/live/camera_name. The video data is stored in a recordings folder and is automatically uploaded to cloud storage at a designated time each day. 

### Network Settings
```bash
sudo raspi-config
> ↵ # 1.  System Options
> ↵ # S1. Wireless LAN
> {Enter SSID}
> {Enter Password}
```

### Build Tools
```bash
sudo apt update
sudo apt install build-essential git
sudo apt install vim
```

### Dependencies
```bash
sudo apt install libpcre3-dev libssl-dev zlib1g-dev
```

### NGINX Server
```bash
cd ~
mkdir nginx
cd nginx
# Please check to ensure these repositories are not deprecated
git clone https://github.com/arut/nginx-rtmp-module.git
git clone https://github.com/nginx/nginx.git
cd nginx 
# Note: The current path should be ~/nginx/nginx.
# The pwd command would return /home/pi/nginx/nginx.
./auto/configure --add-module=../nginx-rtmp-module
make
sudo make install
vim nginx.conf # see Configure RTMP instructions below
# copy the configuration file to /usr/local/nginx/conf
sudo cp ~/nginx/nginx/nginx.conf /usr/local/nginx/conf
# test the configuration file
sudo /usr/local/nginx/sbin/nginx -t
# run the RTMP server
sudo /usr/local/nginx/sbin/nginx
```

### Configure RTMP
```bash
# Configure RTMP
user pi;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}

rtmp {
	server {
		listen 1935;
		application live { # live can be changed to any name
			live on;
			interleave on;
			record all; # Record off/all/audio/video
			# Video location
			record_path home/pi/Desktop/RTMP/Recordings; 
			record_unique on; # Append timestamps to name

			hls on;
			hls_path /tmp/hls;
			hls_fragment 15s;

			dash on;
			dash_path /tmp/dash;
			dash_fragment 15s;
		}
	}
}
```

### RTMP Folder
```bash
# Create an RTMP directory on the desktop
cd ~/Desktop/
mkdir RTMP
sudo chmod -R a+rwx RTMP # allow read, write, and execute to all users
cd RTMP
mkdir Recordings # make a recordings folder for video data
chmod a+rwx Recordings # allow read, write, and execute to all users
```

### RClone
```bash
# Install the rclone tool

# Download installation bash script and pipe to sudo bash command
curl https://rclone.org/install.sh | sudo bash
<<OAUTH
To generate an OAUTH2 Token, visit the following link:
https://www.dropbox.com/developers/apps
In the app console, create an app or click on an existing app and click on Generate OAUTH2 Token.
Under the Permissions tab, allow the following:
files.content.write and files.content.read
OAUTH

<<remote
In this step, an rclone remote is configured.
remote

rclone config
> n # this creates a new remote - use e to modify existing remote
> dropbox # this can be named anything
> dropbox # this must be the name of the cloud solution being used
> y # edit advanced configuration
> ↵ # App key is not needed
> ↵ # App secret is not needed
> {Insert OAUTH2 Token Here}
> ↵ # Skip all remaining choices
# Note: This part will open up a browser. Therefore, this is the only portion that benefits from a GUI. 
# If this needs to be done in headless mode, answer 'n' to auto config. This will prompt you to authorize 
# rclone using a different machine with access to a web browser and copy a string. See instructions below.

<<Headless
> rclone authorize "Dropbox" # Or your preferred cloud storage solution
Log into the cloud storage using a web browser.
Copy the {access_token} over to the Raspberry Pi.
The format of the access token should be as follows:
{"access token":"", "token_type":"bearer","refresh_token":"","expiry":""}
Headless
```

### Upload to Cloud
```bash
# Create Bash Script
cd ~/Desktop/RTMP
touch upload.sh
vim upload.sh
```
```bash
# upload.sh
cd ~/Desktop/RTMP # change to RTMP directory

# rename recordings to upload date 
# date syntax is ddmonthyy e.g. 07March22, this can be changed as needed
mv Recordings `date +%d%B%y` 
<<Date
Technically, renaming the Recordings folder is not necessary. However, this step is useful to make it 
easier to save videos locally in the future if needed. (Comment out the rm -r `date` line.) If this 
step is skipped, copy the ~/Desktop/RTMP/Recordings path instead of the dated path. The folder will 
still need to be emptied using rm -r or other means so that new recordings can be saved without conflicts.
Date

# upload the recordings to Dropbox (Or other cloud storage)
# Note: dropbox:/ should be changed to whatever the remote was named
rclone copyto ~/Desktop/RTMP/`date +%d%B%y` dropbox:/Recordings/`date +%d%B5y`

# delete the uploaded directory to save space on the Pi
sudo rm -r `date +%d%B%y`

# recreate an empty Recordings directory
mkdir Recordings
chmod a+rwx Recordings # allow read, write, and execute to all users

exit
```


### Update RTMP Configuration File
```bash
# Create Bash Script
cd ~/Desktop/RTMP
touch updateconfig.sh
vim updateconfig.sh

# updateconfig.sh
sudo cp ~/nginx/nginx/conf/nginx.conf /usr/local/nginx/conf
```

### Start RTMP Server
```bash
# Create Bash Script
cd ~/Desktop/RTMP
touch start.sh
vim start.sh
```
```bash
# start.sh
# test the configuration file
sudo /usr/local/nginx/sbin/nginx -t
# run the RTMP server
sudo /usr/local/nginx/sbin/nginx
```

### Stop RTMP Server
```bash
# Create Bash Script
cd ~/Desktop/RTMP
touch stop.sh
vim stop.sh
```
```bash
# stop.sh
# stop the RTMP server
sudo /usr/local/nginx/sbin/nginx -s stop
```

### Scheduled Upload
```bash
# schedule an upload via crontab
sudo crontab -e
```
```bash
# crontab - syntax: MIN HOUR DOM MON DOW CMD
# The following command automatically runs upload.sh every day at 11 pm.
0 23 * * * bash ~/Desktop/RTMP/upload.sh 
```

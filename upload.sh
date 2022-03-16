# upload.sh
cd ~/Desktop/RTMP # change to RTMP directory

# rename recordings to upload date 
# date syntax is ddmonthyy e.g. 07March22, this can be changed as needed
mv Recordings `date +%d%B%y` 

# upload the recordings to Dropbox (Or other cloud storage)
# Note: dropbox:/ should be changed to whatever the remote was named
rclone copyto ~/Desktop/RTMP/`date +%d%B%y` dropbox:/Recordings/`date +%d%B%y`

# delete the uploaded directory to save space on the Pi
sudo rm -r `date +%d%B%y`

# recreate an empty Recordings directory
mkdir Recordings
chmod a+rwx Recordings # allow read, write, and execute to all users

exit

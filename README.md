# bing-wallpaper-sway
Use systemd timer to update desktop wallpaper and lock screen wallpaper for sway from bing every day

Dependencies:
swaybg
swaylock
curl
imagemagec

Note:
This is a simple script, I made it with the help of GPT, there is no automated installation process, you need to modify some things to make it work

How to use:
1. Download all script files and service, timer template files
2. Modify line 97 of bing-wallpaper.sh FOLDER="$HOME/Applications/file" to set it to the directory where all files are stored
3. Modify ExecStart of bing-wallpaper.service to point to the path of bing-wallpaper.sh
4. Run bing-wallpaper.sh

Check timer:

systemctl --user list-timers

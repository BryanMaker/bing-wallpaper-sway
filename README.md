# bing-wallpaper-sway
Use systemd timer to update sway's desktop and lock screen wallpapers from bing every day

Note:
Running bing-wallpaper.sh will automatically set a one-time timer based on the fullstartdate (bing wallpaper update time) obtained from Bing, which is 24 hours and 5 minutes later than the fullstartdate by default. At the same time, the script will modify "bg" in ~/.config/sway/config and "image" in ~/.config/swaylock/config

You can manually run bing-wallpaper.sh at any time to refresh the wallpaper and lock screen immediately. If bing has a new wallpaper available, it will be set immediately

Dependencies:
swaybg
swaylock
curl
imagemagec

How to use:
1. Download or clone this project
2. Run bing-wallpaper.sh

Check the timer:
systemctl --user list-timers
Output:
NEXT LEFT LAST PASSED UNIT ACTIVATES
Sun 2025-04-06 09:05:08 CST 16min Sat 2025-04-05 09:05:08 CST 23h ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2025-04-06 15:05:00 CST 6h - - bing-wallpaper.timer bing-wallpaper.service
- - Sat 2025-03-29 08:55:08 CST 1 week 0 days ago grub-boot-success.timer grub-boot-success.service

3 timers listed.
Pass --all to see loaded but inactive timers, too.

delete:
systemctl --user disable bing-wallpaper.timer
systemctl --user stop bing-wallpaper.timer
rm ~/.config/systemd/user/bing-wallpaper.timer ~/.config/systemd/user/bing-wallpaper.service
systemctl --user daemon-reload

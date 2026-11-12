#!/bin/sh
# The RTL8723CS (SDIO) loses power in deep suspend and the 8723cs driver does not
# reliably bring it back: Wi-Fi stayed down after resume until a reboot. Unload the
# driver before suspend and load it again after resume, then make sure it reconnects.

have_nm() { command -v nmcli >/dev/null 2>&1; }

reload() {
	have_nm && nmcli radio wifi off
	modprobe -r 8723cs
	modprobe 8723cs
	sleep 2
	have_nm && nmcli radio wifi on
}

case "$1" in
	pre)
		have_nm && nmcli radio wifi off && sleep 1
		modprobe -r 8723cs
		;;
	post)
		modprobe 8723cs
		sleep 2
		have_nm || exit 0
		nmcli radio wifi on
		# Reload once more if Wi-Fi is still not connected after 45 s.
		(
			sleep 45
			nmcli -t -f TYPE,STATE device | grep -q '^wifi:connected$' || reload
		) >/dev/null 2>&1 &
		;;
esac

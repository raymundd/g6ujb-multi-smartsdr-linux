#!/bin/bash

SDR_VER="v2.7.6"
RADIO="RDX6500"
USER="A_USER"
LOCK_DIR="/tmp/smartsdr"
LOCK_FILE="${LOCK_DIR}/lock"

# Make the lock folder
if [ ! -d $LOCK_DIR ]; then
	mkdir -p $LOCK_DIR
fi

while [ -e $LOCK_FILE ]
do
	#wait for the lock to clear
	echo "waiting..."
	sleep 2
done

touch $LOCK_FILE
echo "LOCKED..."

cp ~/Flexradio/SSDR_${RADIO}.settings "/home/${USER}/radiotools/drive_c/users/${USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings"
env WINEPREFIX=$HOME/radiotools wine "c:\Program Files\FlexRadio Systems\SmartSDR ${SDR_VER}\SmartSDR.exe" &

PROC=$$

while [ ! `pgrep -cf "${SDR_VER}.+SmartSDR.exe"` ]
do
	# wait for it to start
	echo "Wait for SmartSDR to start..."
	sleep 1
done

sleep 5

# Get the PID of SmartSDR.exe
for pid in "$(pgrep --parent $PROC)"
do
	echo $pid
	if [[ -n $pid ]] && [[ $(ps --no-headers -fp $pid | egrep -c "${SDR_VER}.+SmartSDR.exe") -eq 1 ]]
	then
		SDR=$pid
		break
	else
		echo "SmartSDR.exe not running."
		exit 1
	fi
done

rm $LOCK_FILE
echo "UNLOCKED..."
echo $SDR

while [[ $(ps --no-headers -p $SDR) ]]
do
	# wait for it to finish
	echo -n "."
	sleep 5
done

touch $LOCK_FILE
echo "LOCKED..."

cp "/home/${USER}/radiotools/drive_c/users/${USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings" ~/Flexradio/SSDR_${RADIO}.settings_saved

rm $LOCK_FILE
echo "UNLOCKED..."

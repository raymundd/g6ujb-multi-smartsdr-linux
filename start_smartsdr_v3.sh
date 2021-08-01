#!/bin/bash
# start_smartsdr_v3.sh
#
# Copyright 2021 Ray Delaforce
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# Preparations before running this script.
#
# Preparations before running this script.
#
# Create WINE Prefix folder:
# env WINEPREFIX=$HOME/<PREFIX_NAME> wineboot --init
# Run winetricks to install .Net version in new WINEPREFIX
# env WINEPREFIX=$HOME/<PREFIX_NAME> winetricks --force dotnet40 corefonts
# env WINEPREFIX=$HOME/<PREFIX_NAME> winetricks --force dotnet462 corefonts

# These options are hardwired here for now, but this could be placed on the command lie.
SDR_VER="v3.2.39"
RADIO="RDX6600"

# Assuming that the copy of Wine will be running as the user running this script.
SDR_USER=$USER

# Using a less than ideal lock file technique to shield the execution of an instance of
# SmartSDR so that its instance of SSDR.settings can be provided to SmartSDR.exe on its launch.
LOCK_DIR="/tmp/smartsdr"
LOCK_FILE="${LOCK_DIR}/lock"

if [ ! -d $LOCK_DIR ]; then
	mkdir -p $LOCK_DIR
fi

while [ -e $LOCK_FILE ]
do
	echo "waiting..."
	sleep 2
done

touch $LOCK_FILE
echo "LOCKED..."

# Get a copy of the SSDR.settings in place if its available, otherwise when SmartSDR.exe launches it will create a new one.
if [ -s ~/Flexradio/SSDR_${RADIO}.settings ]; then
	cp ~/Flexradio/SSDR_${RADIO}.settings "/home/${SDR_USER}/radiotools/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings"
fi

# Launch SmartSDR.exe in the WINE Prefix previosly created - see comments in header.
env WINEPREFIX=$HOME/radiotools wine "c:\Program Files\FlexRadio Systems\SmartSDR ${SDR_VER}\SmartSDR.exe" &

# Lets remember the pid of this bash session so that we can find the associated instance of SmartSDR.exe that was launched.
PROC=$$

# Wait for SmartSDR.exe to appear in the process list before proceeding.
while [ ! `pgrep -cf "${SDR_VER}.+SmartSDR.exe"` ]
do
	# wait for it to start
	echo "Wait for SmartSDR to start..."
	sleep 1
done

sleep 5

# Using the BASH sessions PID locate the PID of SmartSDR.exe, or bail.
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

# Spinner routine - Lets just show that the script is alive and waiting for SmartSDR.exe to exit.
spin='-\|/'
i=0
while [[ $(ps --no-headers -p $SDR) ]]
do
	# wait for it to finish
    	i=$(( (i+1) %4 ))
		printf "\r${spin:$i:1}"
  		sleep .5
done

touch $LOCK_FILE
echo "LOCKED..."

# Place a copy of the existing SSDR.settings into a backup location to retaine any changes ready for subsequent launches.
cp "/home/${SDR_USER}/radiotools/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings" ~/Flexradio/SSDR_${RADIO}.settings

rm $LOCK_FILE
echo "UNLOCKED..."
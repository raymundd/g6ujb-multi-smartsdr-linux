#!/bin/bash
# start_smartsdr_v2.sh
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
#
# Preparations before running this script.
#
# Create WINE Prefix folder:
# env WINEPREFIX=$HOME/<PREFIX_NAME> wineboot --init
# Run winetricks to install .Net version in new WINEPREFIX
# env WINEPREFIX=$HOME/<PREFIX_NAME> winetricks --force dotnet40 corefonts
# env WINEPREFIX=$HOME/<PREFIX_NAME> winetricks --force dotnet462 corefonts

# These options are required on the command line so that I can simplify the launch scripts.
if [ $# -lt 4 ]; then
	echo "Usage: $0 <SDR_VERSION> <STATION> <USER> <WINE_PREFIX>"
	echo "e.g. $0 2.7.6 RADIO_1"
	echo
	exit 1
fi

SDR_VER="v${1}"
RADIO=$2
SDR_USER=$3
PREFIX=$4

# Some basic validations before we try to do anything.
# Make sure this is a valid user before proceeding.
if ! id $SDR_USER &>/dev/null; then
	echo "ERROR: User not found."
	echo
	exit 1
fi

# Version should be #.#.#
if [[ ! $SDR_VER =~ ^v[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
	echo "ERROR: Invalid version."
	echo
	exit 1
fi

# Make sure the radio name is a sensinble length - Can't expect it to be more than 50 characters,
# can be alphanumeric with _-.
if [[ ! ${RADIO} =~ ^[-,0-9,a-z,A-Z,_,\.,:]{1,50}$ ]]; then
	echo "ERROR: Invalid STATION name or length (valid characters [0-9,a-z,A-Z,-,_,.,:] length <= 20)."
	echo
	exit 1
fi

#Make sure the PREFIX folder exists
if [ ! -d $HOME/$PREFIX ]; then
	echo "ERROR: WINE Prefix folder missing."
	echo
	exit 1
fi

# Using a less than ideal lock file technique to shield the execution of an instance of
# SmartSDR so that its instance of SSDR.settings can be provided to SmartSDR.exe on its launch.
LOCK_DIR="/tmp/smartsdr"
LOCK_FILE="${LOCK_DIR}/lock"

# Make the lock folder
if [ ! -d $LOCK_DIR ]; then
	mkdir -p $LOCK_DIR
fi

# Check for lock state before locking for this instance.
while [ -e $LOCK_FILE ]
do
	echo "INFO: Waiting for lock to clear..."
	sleep 2
done

touch $LOCK_FILE
echo "INFO:...LOCKED..."

# Get a copy of the SSDR.settings in place if its available, otherwise when SmartSDR.exe launches it will create a new one.
if [ -s ~/Flexradio/SSDR_${RADIO}.settings ]; then
	cp ~/Flexradio/SSDR_${RADIO}.settings "/home/${SDR_USER}/${PREFIX}/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings"
	echo "INFO: Restored settings file."
fi

SMARTSDR="c:\Program Files\FlexRadio Systems\SmartSDR ${SDR_VER}\SmartSDR.exe"
REAL_DIR=$(env WINEPREFIX=$HOME/$PREFIX winepath --unix "${SMARTSDR}" 2>/dev/null)

# Launch SmartSDR.exe in the WINE Prefix previosly created - see comments in header.
if [ -e "${REAL_DIR}" ]; then
	env WINEPREFIX=$HOME/$PREFIX wine "${SMARTSDR}" &>/dev/null &
else
	echo "ERROR: File not found, ${SMARTSDR} is not available, check version matches installed."
	rm $LOCK_FILE
	echo "INFO:...UNLOCKED..."
	echo
	exit 1
fi

# Lets remember the pid of this bash session so that we can find the associated instance of SmartSDR.exe that was launched.
PROC=$$

# Wait for SmartSDR.exe to appear in the process list before proceeding.
while [ ! `pgrep -cf "${SDR_VER}.+SmartSDR.exe"` ]
do
	# wait for it to start
	echo "INFO: Waiting for SmartSDR to start..."
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
		echo "ERROR: SmartSDR.exe not running."
		echo
		exit 1
	fi
done

rm $LOCK_FILE
echo "INFO:...UNLOCKED..."
echo "INFO: Active SmartSDR PID = $SDR"

# Spinner routine - Lets just show that the script is alive and waiting for SmartSDR.exe to exit.
spin='-\|/'
i=0
while [[ $(ps --no-headers -p $SDR) ]]
do
	# wait for it to finish
    	i=$(( (i+1) %4 ))
		printf "\rINFO: Running ${spin:$i:1}"
  		sleep .5
done

echo

# Check for lock state before locking for this instance.
while [ -e $LOCK_FILE ]
do
	echo "INFO: Waiting for lock to clear..."
	sleep 2
done

touch $LOCK_FILE
echo "INFO:...LOCKED..."
echo "INFO: Saving settings file."

# Place a copy of the existing SSDR.settings into a backup location to retaine any changes ready for subsequent launches.
cp "/home/${SDR_USER}/${PREFIX}/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings" ~/Flexradio/SSDR_${RADIO}.settings

rm $LOCK_FILE
echo "INFO:...UNLOCKED..."
echo

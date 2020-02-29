#!/bin/bash

# SAM Helper script; Written by Furquan Ahmad
# Will run under any Linux/Unix(s) running any kind of bash
# compatible shell.

# Last Edited: [2018-11-22 2101]

# Global Variables/Constants:
source def_color.sh # load color constants

std_in=""

LOOKUP_PATH_1="/dev/sda2" # <-- is the lookup path by default
LOOKUP_PATH_2="/dev/sda3"
LOOKUP_PATH_3="/dev/sda4"
LOOKUP_PATH_X="/dev/sda1"

LOOKUP_DEFAULT=$LOOKUP_PATH_1 # stores the default lookup path

MOUNT_DEFAULT="/mnt/sda"

# Functions:
terminate() {
	echo -e "
${LIGHT_CYAN}Thank you for using sam-helper!${NC}"
	exit
}

readln() {
	echo -n "$1"
	read std_in
}

root_check() {
	if [ ! "$EUID" = 0 ]; then
		echo -e "${RED}User is not root${NC}. Stop."
		terminate
	fi
}

checkSystem32() {
	echo -e "\tRunning mount commands..."
	mkdir $MOUNT_DEFAULT
	mount "$1" $MOUNT_DEFAULT
	echo -e "\tChecking for System32..."
	if [ ! -d "$MOUNT_DEFAULT/Windows" ]; then
		echo -e "\tSystem32 not found."
		echo -e "\tUnmounting..."
		umount "$1"
		rmdir $MOUNT_DEFAULT
		return 1
	else
		echo -e "\t${GREEN}System32 found${NC} in $1."
		echo -e "Using ${YELLOW}$1${NC} as lookup path."
		LOOKUP_DEFAULT="$1"
		return 0
	fi
}

runLookupDiagnosis() {
	echo -e "${CYAN}Running detailed diagnosis...${NC}
"
	echo -e "Running mount commands...
Mounting at $MOUNT_DEFAULT...
Lookup path $LOOKUP_PATH_1"
	mkdir $MOUNT_DEFAULT
	mount $LOOKUP_PATH_1 $MOUNT_DEFAULT
	echo "Listing directory..."
	ls --color=auto $MOUNT_DEFAULT
	echo "Dumping hierarchy..."
	echo -e "\n\t\t---$LOOKUP_PATH_1---\n" > HIERDUMP
	find $MOUNT_DEFAULT -maxdepth 2 -type d -not -path '*/\.*' >> HIERDUMP
	echo -e "Unmount $LOOKUP_PATH_1..."
	umount "$LOOKUP_PATH_1"
	
	echo -e "
Mounting at $MOUNT_DEFAULT...
Lookup path $LOOKUP_PATH_2"
	mount $LOOKUP_PATH_2 $MOUNT_DEFAULT
	echo "Listing directory..."
	ls $MOUNT_DEFAULT
	echo "Dumping hierarchy..."
	echo -e "\n\t\t---$LOOKUP_PATH_2---\n" >> HIERDUMP
	find $MOUNT_DEFAULT -maxdepth 2 -type d -not -path '*/\.*' >> HIERDUMP
	echo -e "Unmount $LOOKUP_PATH_2.."
	umount "$LOOKUP_PATH_2"
	
	echo -e "
Mounting at $MOUNT_DEFAULT...
Lookup path $LOOKUP_PATH_3"
	mount $LOOKUP_PATH_3 $MOUNT_DEFAULT
	echo "Listing directory..."
	ls $MOUNT_DEFAULT
	echo "Dumping hierarchy..."
	echo -e "\n\t\t---$LOOKUP_PATH_3---\n" >> HIERDUMP
	find $MOUNT_DEFAULT -maxdepth 2 -type d -not -path '*/\.*' >> HIERDUMP
	echo -e "Unmount $LOOKUP_PATH_3.."
	umount "$LOOKUP_PATH_3"
	
	echo -e "
Mounting at $MOUNT_DEFAULT...
Lookup path $LOOKUP_PATH_X"
	mount $LOOKUP_PATH_X $MOUNT_DEFAULT
	echo "Listing directory..."
	ls $MOUNT_DEFAULT
	echo "Dumping hierarchy..."
	echo -e "\n\t\t---$LOOKUP_PATH_X---\n" >> HIERDUMP
	find $MOUNT_DEFAULT -maxdepth 2 -type d -not -path '*/\.*' >> HIERDUMP
	echo -e "Unmount $LOOKUP_PATH_X.."
	umount "$LOOKUP_PATH_X"
	
	echo "Finishing up..."
	rmdir "$MOUNT_DEFAULT"
	echo -e "File hierarchy dumped to ${LIGHT_GREEN}./HIERDUMP${NC}."
}



# Errors
system32NotFound() {
	echo -e "${RED}System32 not found on system${NC}. Stop."
	readln "
Do you wish to see a detailed diagnosis? (Y/N) "
	if [ "$std_in" = "Y" ]; then
		runLookupDiagnosis
	fi
	echo -e "\nExitting...
"
	terminate
}

# Main code

whiptail --yesno "WARNING: Improper usage of this script may damage your system or render it unusable. Proceed with caution.
The author(s) of this script will NOT be liable for any damages incurred through the usage of this script.

Are you sure you want to run this script?" 10 110

if [ $? -eq 1 ]; then
	exit
fi

clear
echo "chntpw/interactive-mount and helper script
Written April 17 2016; Ahmad, Furquan
Edited Nov 22 2018 by Furquan Ahmad
"

root_check

echo -e "Available lookup-paths are:
1. ${WHITE}$LOOKUP_PATH_1${NC}"
checkSystem32 $LOOKUP_PATH_1
echo -e "2. ${WHITE}$LOOKUP_PATH_2${NC}"
checkSystem32 $LOOKUP_PATH_2
echo -e "3. ${WHITE}$LOOKUP_PATH_3${NC}"
checkSystem32 $LOOKUP_PATH_3
echo -e "4. ${WHITE}$LOOKUP_PATH_X${NC}"
checkSystem32 $LOOKUP_PATH_X

if [ "$?" = 1 ]; then
	readln "System32 was not found in any of the lookup devices. Enter one manually? (Y/N) "
	if [ "$std_in" = "Y" ]; then
		readln "Enter the device path (/dev/xxx): "
		checkSystem32 $std_in
		if [ "$?" = 1 ]; then
			system32NotFound
		fi
	else
		system32NotFound
	fi
fi

readln "Do you wish to proceed? (Y/N) "

if [ "$std_in" = "Y" ]; then
	echo "
Changing to %WINDIR%/System32 in mount directory..."
	cd "$MOUNT_DEFAULT/Windows/System32"
else
	echo -e "Okay then.

Unmount $LOOKUP_DEFAULT.."
	umount "$LOOKUP_DEFAULT"
	echo "Finishing up..."
	rmdir "$MOUNT_DEFAULT"	
	echo -e "Exitting..."
	terminate
fi

cd config > /dev/null
if [ ! "$?" = 0 ]; then
	pwd
	echo "
Error: We were unable to find the config directory."
	ls --color=auto -d */
	readln "Please enter the correct name for the config directory: "
	cd "$std_in"
fi
if [ ! -f "SAM" ]; then
	echo "
Error: We were unable to find the SAM file. The SAM file is a single file without any extension and is usually named sam, Sam, SAM, etc."
	ls --color=auto
	readln "Please enter the correct name for the SAM file: "
	echo "Running chntpw...
"
	chntpw -i $std_in
else
	echo -e "${LIGHT_GREEN}SAM file found${NC} at ${LIGHT_BLUE}`pwd`/SAM${NC}."
	echo "Running chntpw...
"
	chntpw -i SAM
fi
cd ~
echo "Unmounting $LOOKUP_DEFAULT..."
umount $LOOKUP_DEFAULT
rmdir $MOUNT_DEFAULT

terminate
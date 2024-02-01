# mobdevim
**Mobile Device Improved**: Command line utility that interacts with plugged in iOS devices. Uses Apple's MobileDevice framework 

---

Yet another MobileDevice utility

---

## Installation 

1. clone
2. build project
3. Upon build success,` mobdevim` will be placed in **/usr/local/bin**

Make sure you have permissions to write to `/usr/local/bin` or else the Xcode build script will fail

---

Alternatively, a precompiled version is available <a href="https://github.com/DerekSelander/mobdevim/raw/master/compiled" target="_blank">here</a>.

## Commands

```	
Name
  mobdevim -- (mobiledevice-improved) Interact with an iOS device (compiled Nov  7 2023, 15:50:43)

  The mobdevim utlity interacts with your plugged in iOS device over USB using Apple's
  private framework, MobileDevice.

  The options are as follows:
	-F	# List all available connections, or connect to a specific device

		mobdevim -F       # List all known devices
		mobdevim -F 00234 # Connect to first device that has a UDID containing 00234
		mobdevim -F\?     # Check for devices

		mobdevim -U       # Prefer connection over USB

		mobdevim -W       # Prefer connection over WIFI

	-f	# Get device info to a connected device (defaults to first USB connection)

	-g	# Get device logs/issues (TODO Broken in 16.5)

		mobdevim -g com.example.name # Get issues for com.example.name app
		mobdevim -g 3                # Get the 3rd most recent issue
		mobdevim -g __all            # Get all the logs

	-l	# List app information

		mobdevim -l                     # List all apps
		mobdevim -l com.example.test    # Get detailed info about app, com.example.test
		mobdevim -l com.example.test Entitlements # List "Entitlements" key from com.example.test

	-r	# Remove file

		mobdevim -r /fullpath/to/file # removes file (sandbox permitting)

	-y	# Yoink sandbox content

		mobdevim -y com.example.test   # Yoink contacts from app

	-s	# Send content to device (use content from yoink command)

		mobdevim -s com.example.test /tmp/com.example.test # Send contents in /tmp/com.example.test to app

	-i	# Install application (expects path to bundle)

	-I	# Install/mount a DDI (via Xcode subdir or repos like https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images

		mobdevim -I /path/to/ddi.signature /path/to/ddi.dmg # Install DDI

	-M	# unMount a DDI (via Xcode subdir or repos like https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images

		mobdevim -M # Unmount an alreaady mounted dev DDI

	-u	# Uninstall application, expects bundleIdentifier

		mobdevim -u com.example.test # Uninstall app

	-w	# Connect device to WiFi mode

		mobdevim -w              # Connect device to wifi for this computer
		mobdevim -w uuid_here    # Connect device to wifi for UUID
		mobdevim -w off          # Disable device wifi
		mobdevim -w uuid         # Display the computer's host uuid

	-S	# Arrange SpringBoard icons

		mobdevim -S                # Get current SpringBoard icon layout
		mobdevim -S /path/to/plist # Set SpringBoard icon layout from plist file
		mobdevim -S asshole        # Set SpringBoard icon layout to asshole mode
		mobdevim -S restore        # Restore SpringBoard icon layout (if backup was created)

	-L	# Simulate location (requires DDI)

		mobdevim -L 0 0                # Remove location simulation
		mobdevim -L 40.7128 -73.935242 # Simulate phone in New York

	-c	# Dump out the console information. Use ctrl-c to terminate

	-C	# Get developer certificates on device

	-p	# Display running processes on the device (requiers DDI)

	-k	# Kill a process (requiers DDI)

		TODO	-b	# Backup device

	-P	# Display developer provisioning profile info

		mobdevim -P # List all installed provisioning profiles
		mobdevim -P b68410a1-d825-4b7c-8e5d-0f76a9bde6b9 # Get detailed provisioning UUID info

	-o	# Open application (requires DDI)

		mobdevim -o com.reverse.domain # open app
		mobdevim -o com.reverse.domain -A "Some args here" -V AnEnv=EnValue -V A=Bmobdevim # open app with launch args and env vars

	-R	# Use color

	-Q	# Quiet mode, ideal for limiting output or checking if a value exists based upon return status

Environment variables:           	DSCOLOR - Use color (same as -R)

           	DSDEBUG - verbose debugging

           	DSPLIST - Display output in plist form (mobdevim -l com.test.example)

           	OS_ACTIVITY_DT_MODE - Combine w/ DSDEBUG to enable MobileDevice logging

```
 
![mobdevim example](https://github.com/DerekSelander/mobdevim/raw/main/media/color_wow.png)


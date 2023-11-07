# mobdevim
**Mobile Device Improved**: Command line utility that interacts with plugged in iOS devices. Uses Apple's MobileDevice framework 

---

<a href="https://store.raywenderlich.com/products/advanced-apple-debugging-and-reverse-engineering" target="_blank"><img align="right"  height="90"  src="https://github.com/DerekSelander/LLDB/blob/master/Media/dbgbook.png"></a>

This information was extracted out using the help of <a href="https://github.com/DerekSelander/LLDB" target="_blank">**these LLDB scripts  found here**</a>. If you want to learn how to create these scripts or have a better understanding how one can reverse engineer a compiled binary, check out <a href="https://store.raywenderlich.com/products/advanced-apple-debugging-and-reverse-engineering" target="_blank">**Advanced Apple Debugging and Reverse Engineering**</a>

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
        -f	Get device info

  	-d	Debug application
          		mobdevim -d /application/bundle/on/mac/ Debugs application (must install app first)

  	-g	Get device logs/issues
          		mobdevim -g com.example.name Get issues for com.example.name app
          		mobdevim -g 3 Get the 3rd most recent issue
          		mobdevim -g __all Get all the logs

  	-y	Yoink sandbox content
          		mobdevim -y com.example.test Yoink contacts from app

  	-s	Send content to device (use content from yoink command)
          		mobdevim -s com.example.test /tmp/com.example.test Send contents in /tmp/com.example.test to app

  	-i	Install application, expects path to bundle
          		mobdevim -i /path/to/app/bundle Install app

  	-u	Uninstall application, expects bundleIdentifier
          		mobdevim -u com.example.test Uninstall app

  	-c	Dump out the console information. Use ctrl-c to terminate

  	-C	Get developer certificates on device

  	-p	Display developer provisioning profile info
            		mobdevim -p List all installed provisioning profiles
            		mobdevim -p b68410a1-d825-4b7c-8e5d-0f76a9bde6b9 Get detailed provisioning UUID info

  	-l	List app information
        		mobdevim -l List all apps
        		mobdevim -l com.example.test Get detailed information about app, com.example.test
        		mobdevim -l com.example.test Entitlements List "Entitlements" key from com.example.test

  	-R	Use color

  	-q	Quiet mode, ideal for limiting output or checking if a value exists based upon return status


  Environment variables:
	DSCOLOR - Use color (same as -R)

  	DSDEBUG - verbose debugging

  	DSPLIST - Display output in plist form (mobdevim -l com.test.example)

  	OS_ACTIVITY_DT_MODE - Combine w/ DSDEBUG to enable MobileDevice logging
```
 
![mobdevim example](https://github.com/DerekSelander/mobdevim/raw/master/media/color_wow.png)

More commands will be coming soon...

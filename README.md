**THIS STILL IS A PRE-ALPHA BE PREPARED TO LOOSE ALL YOUR DATA!**

# macOS-eGPU.sh
## Purpose
Make your Mac compatible with NVIDIA and AMD eGPUs.

## Requirements
- macOS 10.13.X ≤ 10.13.4 2018-001 (17E202)
- a NVIDIA or an AMD graphics card
- an eGPU enclosure (T82 & T83 controllers are supported)
- a Mac (TB 1/2/3 are supported)
- ***BACKUP***
- sufficiently disabled SIP; more information under **SIP**

## Howto
This script is still in pre-alpha stage it may damage your system.  
Do not abort the script during uninstallation/installation/patch phase this *will* damage your system. 

1. Remove all prior eGPU solutions. (e.g. after upgrading to 10.13, **the temporary script for 10.13.4 is currently not supported. DO NOT EXECUTE IF YOU'VE USED THAT, yet**)
2. Back up your system.
2. Disconnect all unnecessary peripherals. Especially eGPUs!  
	The script may explicitly ***ask*** you to connect your eGPU.  
	Please follow the instructions given by the script.
3. Save your work. The script will kill all running programs.
4. Execute: 

`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`

*A quick note to all the pros out there: the #sh shell does not support the syntax given above. You need a #bash shell.*

## Parameters
### Basic
`--install | -i`

Tells the script to install/update eGPU software. *internet required*  
The install parameter tells the script to fetch your Mac’s parameters (such as installed software, installed patches, macOS version etc.) and to fetch the newest software versions. It then cross-references and deducts what needs to be done. This includes all packages listed below. This works best on new systems or systems that have been updated. Deductions on corrupt systems are limited. Note that earlier enablers for 10.12 won’t be touched. If you have used such software you must uninstall it yourself. To override deductions use the #Package parameters below.

`--uninstall | -U`

Tells the script to uninstall eGPU software.  
The uninstall parameter tells the script to search for eGPU software and fully uninstall it. Note that earlier enablers for 10.12 won’t be touched. If you have used such software you must uninstall it yourself. To override deductions use the #Package parameters below.

`--checkSystem | -C`

Not yet available.


### Packages
`--nvidiaDriver [revision] | -n [revision]`

Specify that the NVIDIA drivers shall be touched.  
The NVIDIA driver parameter tells the script to perform either an install or uninstall of the NVIDIA drivers. If the script determines that the currently installed NVIDIA driver shall be used after an update it will patch it. One can optionally specify a custom driver revision. The specified revision will automatically be patched, if necessary.

`amdLegacyDriver | -a`

Specify that the AMD legacy drivers shall be touched. *drivers by @goalque*  
The AMD legacy driver parameter tells the script to make older AMD graphics cards compatible with macOS 10.13.X  
These include: 
- Polaris - RX: 460, 560 | Radeon Pro: WX5100, WX4100
	- Fiji - R9: Fury X, Fury, Nano
	- Hawaii - R9: 390X, 390, 290X, 290
	- Tonga - R9: 380X, 380, 285
	- Pitcairn - R9: 370X, 270X, 270 | R7: 370, 265 | FirePro: W7000
	- Tahiti - R9: 280x, 280 | HD: 7970, 7870, 7850

`--nvidiaEGPUsupport | -e`

Specify that the NVIDIA eGPU support shall be touched. *kext by yifanlu*  
The NVIDIA eGPU support parameter tells the script to make the NVIDIA drivers compatible with an NVIDIA eGPU. On macOS 10.13.4 an additional patch is necessary. See `--unlockNvidia`.

`--deactivateNvidiaDGPU | -d`

Not yet available. Only for AMD eGPU users. *patch by @mac\_editor*

`--unlockThunderboltV12 | -V`

Specify that thunderbolt versions 1 and 2 shall be unlocked for use of an eGPU. *patch by @mac\_editor, @fricorico*  
The unlock thunderbolt v1, v2 parameter tells the script to make older Macs with thunderbolt ports of version 1 or 2 compatible for eGPU use. This is not GPU vendor specific. This is only required for macOS 10.13.4.

`--unlockNvidia | -N`

Specify that NVIDIA eGPU support shall be unlocked. *patch by @fr34k, @goalque*  
The unlock NVIDIA parameter tells the script to make the Mac compatible with NVIDIA eGPUs. This is only required for macOS 10.13.4. This might cause issues/crashes with AMD graphics cards.  

`--cudaDriver | -c`

Specify that CUDA drivers shall be touched.  
The CUDA driver parameter tells the script to perform either an install or uninstall of the CUDA drivers. Note that the toolkit and samples are depended on the drivers. Uninstalling them will cause the script to uninstall the toolkit and samples as well.

`--cudaDeveloperDriver | -D`

Specify that CUDA developer drivers shall be touched.  
The CUDA developer drivers parameter tells the script to perform either an install or uninstall of the CUDA developer drivers. Note that the toolkit and samples are depended on the developer/drivers. Uninstalling them will cause the script to uninstall the toolkit and samples as well. This should theoretically be identical to `--cudaDriver`

`--cudaToolkit | -t`

Specify that CUDA toolkit shall be touched.  
The CUDA toolkit parameter tells the script to perform either an install or uninstall of the CUDA toolkit. Note that the samples are depended on the toolkit and the toolkit itself depends on the drivers. Uninstalling the toolkit will cause the script to uninstall the samples as well. Installing the toolkit will cause the script to install the drivers as well.

`--cudaSamples | -s`

Specify that CUDA samples shall be touched.  
The CUDA samples parameter tells the script to perform either an install or uninstall of the CUDA samples. Note that the samples are depended on the toolkit and drivers. Installing the samples will cause the script to install the drivers and toolkit as well.

### Advanced
`--full | -F`

Select all #Packages. This might cause issues. Read the descriptions of the #Packages as well.

`--forceReinstall | -R`

Specify that the script shall reinstall already installed software.  
The force reinstall parameter tells the script to reinstall all software regardless if it already is up to date. This does not influence deductions or other installations.

`--forceNewest | -f`

Specify that the script shall install only newest software.  
The force newest parameter tells the script to prefer newer instead of more stable software. This might resolve and/or cause issues.

`--noReboot | -r`

Specify that even if something has been done no reboot shall be performed.

`--acceptLicenseTerms`

Specify that the question of whether the license terms have been accepted shall be automatically answered with yes and then skipped.

`--skipWarnings | -k`

Specify that the initial warnings of the script shall be skipped.

`--help | -h`

Not yet available.


## Problems
If you’ve got a problem then try the tweaks first.  
If nothing works head over to [eGPU.io][1] and ask.

## Donate
You think it’s amazing what we did? Then head over to [eGPU.io][2] and then say thanks.  
  
But because people have insisted:

[![paypal][image-1]][3] (*@fr34k*)  
[![paypal][image-2]][4] (*@mac\_editor*)

*@ shows that it’s the alias on eGPU.io*

[1]:	https://egpu.io/forums/mac-setup/script-fr34ks-macos-egpu-sh-one-script-all-solutions-fully-automated/#post-35722 "Link to Thread"
[2]:	https://egpu.io/forums/mac-setup/script-fr34ks-macos-egpu-sh-one-script-all-solutions-fully-automated/#post-35722 "Link to Thread"
[3]:	https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=learex2@icloud.com&lc=US&item_name=learex&no_note=0&currency_code=EUR&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest
[4]:	https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=mac_editor&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest

[image-1]:	https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif
[image-2]:	https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif
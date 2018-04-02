
# macOS-eGPU
**NOTE: THE SCRIPT DOES NOT WORK FOR 10.13.4  
It is currently unknown if and when support will arrive.  
The current recommendation is to downgrade macOS to 10.13.3 using Time Machine.  
To check whether the script has been updated, visit its GitHub homepage.**
## Purpose
Setup/Update/Uninstall NVIDIA eGPU Support on a Mac with macOS Sierra (10.12) or High Sierra (10.13).

## Howto
Simply execute the following Terminal command:  
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`  
***Installing NVIDIA drivers with SIP fully disabled may not work. Use enabled unsigned kext or a tweak below. You may, however, try it yourself.***  
**DO NOT DETACH ANY MOUNTED DMGs DURING EXECUTION!**
  
Advanced users may want to take a look at the parameters below.

## Requirements
- macOS 10.12 or 10.13 (≤10.13.3)
- enabled unsigned kext/disabled SIP

Howto enable unsigned kext or disable **S**ystem **I**ntegrity **P**rotection (SIP) entirely:
1. Reboot your Mac into recovery mode ([Howto][1])
2. Open Terminal (Utilities -\> Terminal)
3. Execute:
	1. Enable unsigned kext: `csrutil enable --without kext; reboot;`
	2. Disable SIP: `csrutil disable; reboot;`

## Tweaks
1. Execute in new order:
	1. Uninstall everything: `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -u`
	2. Enable SIP in recovery mode: `csrutil clear`
	3. Install NVIDIA drivers: `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -i -d`
	4. Disable SIP in recovery mode: `csrutil disable`
	5. Install rest: `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`
2. Change SIP setting
	1. `csrutil enable --without kext`
	2. `csrutil disable`
3. Using newest driver, instead of most stable:
	1. `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -i -d -f`
	2. `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -i -d` (to revert 3.i)
4. Only using HDMI output
5. Change booting procedure:
	1. Boot with eGPU attached
	2. Boot without eGPU attached, login, hotplug, logout, login
6. Clean your Mac using OnyX
	1. Download [OnyX][2]
	2. Go to optimize
	3. Check everything
	4. Execute
	5. Reboot (It might take two, since a lot of caches need to be rebuild)

## Example
On an already working eGPU system you might want to execute  
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -r`  
in order to update the installed eGPU software.

## External Content
This script may use some of the following external content:
- goalque's automate-eGPU ([Link][3])
- Benjamin Dobell’s nvidia-update ([Link][4])
- NVDAEGPUSupport by devild/ricosuave0922 ([Link][5])
- CUDA Drivers ([Link][6])
- CUDA Toolkit ([Link][7])

The external content above may download additional content.
All external content may be subject to different licenses.

## Parameters
### Standard
`--install | -i` (default)  
Installs software. If not specified otherwise, the script will determine itself what to install. If some software is already installed, it will be updated.  
Cannot be used with `--check | -h`, `--uninstall | -u` and `--update | -r`.

`--uninstall | -u`  
Uninstalls software. If not specified otherwise, the script will try to uninstall the NVIDIA drivers, the eGPU support and all CUDA installations.  
Cannot be used with `--check | -h`, `--install | -i` and `--update | -r`.

`--update | -r`  
This will try to update your drivers, eGPU support and CUDA installations. It will not install new software.  
Cannot be used with #Packages, `--check | -h`, `--install | -i` and `--uninstall | -u`.

### Check
`--check | -h`  
Searches for installed eGPU software and other system properties and displays information about it. No changes are being made to the system. No personal information is displayed.  
Cannot be used with #Standard, #Packages, `--forceNewest | -f`, `--forceReinstall | -l` and `--minimal | -m`.  

### Packages
The parameters in this section will override the deductions on what to install/update/uninstall of the script.

`--driver [revision] | -d [revision]`  
NVIDIA GPU drivers for Mac; you can specify the exact driver by providing the version number thereafter  
`[revision]` cannot be used with `--forceNewest | -f`  
Cannot be used with `--update | -r` and `--check | -h`.

`--enabler | -e`  
Tweak to enable eGPU support on the Mac  
Cannot be used with `--update | -r` and `--check | -h`.

`--cuda | -c`  
CUDA drivers, will use the standard driver files  
Cannot be used with `--update | -r`, `--check | -h`, `--cudaDriver | -v`, `--cudaToolkit | -t` and `--cudaSamples | -a`.

`--cudaDriver | -v`  
CUDA drivers, will use the developer driver files (from the toolkit), *should* be identical to `--cuda | -c `  
Cannot be used with `--update | -r`, `--check | -h`, `--cuda | -c`, `--cudaToolkit | -t` and `--cudaSamples | -a`.

`--cudaToolkit | -t`  
CUDA developer toolkit  
Cannot be used with `--update | -r`, `--check | -h`, `--cuda | -c`, `--cudaDriver | -v` and `--cudaSamples | -a`.

`--cudaSamples | -a`  
CUDA developer samples  
Cannot be used with `--update | -r`, `--check | -h`, `--cuda | -c`, `--cudaDriver | -v` and `--cudaToolkit | -t`.

**Dependencies:**

The dependency graph of the CUDA options is:  
Samples -\> Toolkit -\> Driver

Therefore, installing the toolkit will also install the drivers and uninstalling the drivers will also remove the toolkit.

### Advanced
The parameters in this section will change the behavior of the script.

`--forceNewest | -f`  
Force the newest NVIDIA drivers and CUDA drivers to be used. This is not recommended. The script will automatically determine the most *stable* drivers.  
Cannot be used with `--uninstall | -u`, `--check | -h` and a driver `[revision]`.

`--forceReinstall | -l`  
Force an uninstall of installed software although the software may be up to date. Can be used to fix corrupt software installations.  
Cannot be used with  `--check | -h` and `--uninstall | -u`.

`--minimal | -m`  
Only tweak the system as little as possible. This may not work in all cases.  
Cannot be used with `--check | -h`.

`--noReboot | -n`  
Omit the otherwise obligatory reboot at the end of the script.

`--silent | -s`  
Automatically answer every question with yes.  
Can only be used in conjunction with `--acceptLicenseTerms`.

`--acceptLicenseTerms`  
Answer the question of whether to accept the license terms with yes.

`--errorContinue`  
If a non fatal error occurs, try to continue by omitting some arguments. Might result in failure.  
Can only be used in conjunction with `--silent | -s `.  
Cannot be used with `--errorBreakSilence` and `--errorStop`.

`--errorBreakSilence`  
If a non fatal error occurs, ask user whether to continue. Continuation  might result in failure.  
Can only be used in conjunction with `--silent | -s `.  
Cannot be used with `--errorContinue` and `--errorStop`.

`--errorStop`  
If a non fatal error occurs, stop the script.  
Can only be used in conjunction with `--silent | -s `.  
Cannot be used with `--errorContinue` and `--errorBreakSilence`.

[1]:	https://support.apple.com/HT201314%20%22macOS-Recovery%22 "Guide to boot into recovery mode"
[2]:	https://www.titanium-software.fr/en/onyx.html
[3]:	https://github.com/goalque/automate-eGPU "goalque's automate-eGPU"
[4]:	https://github.com/Benjamin-Dobell/nvidia-update "Benjamin Dobell’s nvidia-update"
[5]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[6]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver Archive"
[7]:	https://developer.nvidia.com/cuda-toolkit-archive "Cuda Toolkit Archive"
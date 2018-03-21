
# macOS-eGPU
Setup/Update/Uninstall Nvidia eGPU Support on a mac with macOS Sierra (10.12) or High Sierra (10.13).

## Howto
Simply execute the following Terminal command:  
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`  
Advanced users may want to take a look at the parameters below.

## Example
On an already working eGPU system you might want to execute  
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/newFunctionality/macOS-eGPU.sh) -r`  
in order to update the installed eGPU software.

## External Content
This script may use some of the following external content:
- goalque's automate-eGPU ([Link][1])
- benjamin dobell’s nvidia-update ([Link][2])
- NVDAEGPUSupport by devild/ricosuave0922 ([Link][3])
- CUDA Drivers ([Link][4])
- CUDA Toolkit ([Link][5])

The external content above may download additional content.
All external content may be subject to different licenses.

## Parameters
### Standard
`--install | -i` (default)  
Installs software. If not specified otherwise, the script will determine itself what to install. If some software is already installed, it will be updated.

`--uninstall | -u`  
Uninstalls software. If not specified otherwise, the script will try to uninstall the nvidia drivers, the eGPU support and all CUDA installations.

`--update | -r`  
This will try update your drivers, eGPU support and CUDA installations. It will not install new software.  

### Packages
The parameters in this section will override the deductions on what to install/update/uninstall of the script.

`--driver | -d`  
Nvidia GPU drivers for Mac

`--enabler | -e`  
Tweak to enable eGPU support on the Mac

`--cuda | -c`  
CUDA drivers, will use the standard driver files

`--cudaDriver | -v`  
CUDA drivers, will use the developer driver files (from the toolkit), *should* be identical to `--cuda | -c `

`--cudaToolkit | -t`  
CUDA developer toolkit

`--cudaSamples | -a`  
CUDA developer samples

**Dependencies:**

The dependency graph of the CUDA options is:  
Samples -\> Toolkit -\> Driver

Therefore installing the toolkit will also install the drivers and uninstalling the drivers will also remove the toolkit.

### Advanced
The parameters in this section will change the behavior of the script.

`--forceNewest | -f`  
Force the newest nvidia drivers and CUDA drivers to be used. This is not recommended. The script will automatically determine the most *stable* drivers. Cannot be used with `--uninstall | -u`.

`--minimal | -m`  
Only tweak the system as little as possible. This may not work in all cases.

`--noReboot | -n`  
Omit the otherwise obligatory reboot at the end of the script.

`--silent | -s`  
Automatically answer every question with yes. Can only be used in conjunction with `--acceptLicenseTerms`.

`--acceptLicenseTerms`  
Answer the question of whether to accept the license terms with yes.

`--errorContinue`  
Can only be used in silent mode. If a non fatal error occurs, try to continue by omitting some arguments. Might result in failure.

`--errorBreakSilence`  
Can only be used in silent mode. If a non fatal error occurs, ask user whether to continue. Continuation  might result in failure.

`--errorStop`  
Can only be used in silent mode. If a non fatal error occurs, stop the script.


**DO NOT DETACH ANY MOUNTED DMGs DURING EXECUTION!**

[1]:	https://github.com/goalque/automate-eGPU "automate-eGPU"
[2]:	https://github.com/Benjamin-Dobell/nvidia-update "nvidia-update"
[3]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[4]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver"
[5]:	https://developer.nvidia.com/cuda-toolkit-archive "Cuda Toolkit"
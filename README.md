# macOS-eGPU
Setup/Update Nvidia eGPUs on a mac with macOS Sierra (10.12) or High Sierra (10.13)

## Howto
Simply execute the following Terminal command:
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`

### Options
-install (default)  
-uninstall

-enabler (default)  
-driver (default)  
-cuda (using the standard driver files)  
-cudaD (using driver files from toolkit)  
-cudaT (toolkit)  
-cudaS (samples)

If neither install nor uninstall is set as an option, install will be used.  
If neither enabler/driver/cuda/cudaD/cudaT/cudaS is set as an option, enabler and driver will be used.

The dependency graph of the CUDA options is:  
*cudaS* -\> *cudaT* -\> *cudaD*  
Should you execute `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -install -cudaT` this also implies `-cudaD` but not `-cudaS`.  
The uninstall option reverses that:  
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -uninstall -cudaT` also implies `-cudaS` but not `-cudaD`.

**Example:**

`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -install -enabler -driver -cudaT` installs the enabler, the Nvidia drivers as well as the CUDA driver and toolkit.

**-uninstall is OS-sensitive:**

You cannot use this script to undo changes done on macOS Sierra while running on macOS High Sierra. Uninstall first, then upgrade, then install!

The script may fail if you try to uninstall software that has not been installed.

## Requirements
- macOS 10.12 or 10.13 (≤10.13.3)
- enabled unsigned kext

If you haven’t enabled unsigned kexts or disabled SIP entirely follow the following steps:
1. Reboot your Mac into recovery mode ([Howto][1])
2. Open Terminal (Utilities -\> Terminal)
3. Execute: `csrutil enable --without kext; reboot;`

## External Content
This script may use some of the following external content:
- goalque's automate-eGPU ([Link][2])
- benjamin dobell’s nvidia-update ([Link][3])
- NVDAEGPUSupport by devild/ricosuave0922 ([Link][4])
- CUDA Drivers ([Link][5])
- CUDA Toolkit ([Link][6])

The external content above may download additional content.
All external content may be subject to different licenses.

Should the script fail for any reason, downloaded contents would not be deleted. They are located here:  
\~/Desktop/macOSeGPU\*/

**DO NOT DELETE ANY FILES IN THIS DIRECTORY DURING EXECUTION!**
**DO NOT DETACH ANY MOUNTED .DMGs DURING EXECUTION!**

[1]:	https://support.apple.com/HT201314 "macOS-Recovery"
[2]:	https://github.com/goalque/automate-eGPU "automate-eGPU"
[3]:	https://github.com/Benjamin-Dobell/nvidia-update "nvidia-update"
[4]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[5]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver"
[6]:	https://developer.nvidia.com/cuda-toolkit-archive "Cuda Toolkit"
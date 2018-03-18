# macOS-eGPU
Setup/Update Nvidia eGPUs on a mac with macOS Sierra (10.12) or High Sierra (10.13)

## Howto
Simply execute the following Terminal command:
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`

### Options
-install (default)
If neither install nor uninstall is set as an option, install will be used.
-uninstall

-enabler (default)
-driver (default)
If neither enabler nor driver nor cuda is set as an option, enabler and driver will be used.
-cuda (Only the CUDA driver; no toolkit)

Example: `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -install -enabler -driver -cuda`

**Uninstall is OS-sensitive:**

You cannot use this script to undo changes done on macOS Sierra while running on macOS High Sierra. Uninstall first, then upgrade, then install!

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

The external content above may download additional content.
All external content may be subject to different licenses.


[1]:	https://support.apple.com/HT201314 "macOS-Recovery"
[2]:	https://github.com/goalque/automate-eGPU "automate-eGPU"
[3]:	https://github.com/Benjamin-Dobell/nvidia-update "nvidia-update"
[4]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[5]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver"
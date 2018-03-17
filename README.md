# macOS-eGPU
Setup/Update Nvidia eGPUs on a mac with macOS Sierra (10.12) or High Sierra (10.13)

## Requirements
- macOS 10.12 or 10.13 (≤10.13.3)
- enabled unsigned kext

If you haven’t enabled unsigned kexts or disabled SIP entirely follow the following steps:
1. Reboot your Mac into recovery mode ([Howto][1])
2. Open Terminal (Utilities -\> Terminal)
3. Execute: csrutil enable --without kext; reboot;

## External Content
This script may use some of the following external content:
- goalque's automate-eGPU ([Link][2])
- benjamin dobell’s nvidia-update ([Link][3])
- NVDAEGPUSupport by devild/ricosuave0922 ([Link][4])
- CUDA Drivers ([Link][5])

The external content above may download additional content.
All external content may be subject to different licenses.

## Uninstall
### macOS Sierra:
Use the -uninstall option on the automate-eGPU script
You may still need to remove the Nvidia drivers manually.

### macOS High Sierra:
An uninstaller is currently not available.
To do it manually:
- delete „/Library/Extensions/NVDAEGPUSupport.kext“
- remove the Nvidia drivers


[1]:	https://support.apple.com/HT201314 "macOS-Recovery"
[2]:	https://github.com/goalque/automate-eGPU "automate-eGPU"
[3]:	https://github.com/Benjamin-Dobell/nvidia-update "nvidia-update"
[4]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[5]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver"
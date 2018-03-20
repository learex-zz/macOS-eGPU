# macOS-eGPU
Setup/Update Nvidia eGPUs on a mac with macOS Sierra (10.12) or High Sierra (10.13)

## Howto
Simply execute the following Terminal command:
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`

## External Content
This script may use some of the following external content:
- goalque's automate-eGPU ([Link][1])
- benjamin dobell’s nvidia-update ([Link][2])
- NVDAEGPUSupport by devild/ricosuave0922 ([Link][3])
- CUDA Drivers ([Link][4])
- CUDA Toolkit ([Link][5])

The external content above may download additional content.
All external content may be subject to different licenses.

Should the script fail for any reason, downloaded contents would not be deleted. They are located here:  
\~/Desktop/macOSeGPU\*/

**DO NOT DELETE ANY FILES IN THIS DIRECTORY DURING EXECUTION!**  
**DO NOT DETACH ANY MOUNTED DMGs DURING EXECUTION!**

[1]:	https://github.com/goalque/automate-eGPU "automate-eGPU"
[2]:	https://github.com/Benjamin-Dobell/nvidia-update "nvidia-update"
[3]:	https://egpu.io/forums/mac-setup/wip-nvidia-egpu-support-for-high-sierra/#post-22370 "NVDAEGPUSupport"
[4]:	http://www.nvidia.com/object/mac-driver-archive.html "CUDA Driver"
[5]:	https://developer.nvidia.com/cuda-toolkit-archive "Cuda Toolkit"
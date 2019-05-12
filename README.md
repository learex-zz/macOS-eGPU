# macOS-eGPU.sh
**Version: v1.6**

*A notice to all users:*
This script will not be updated, until new NVIDIA drivers are released (for 10.14.X or 10.15.X).
Should you update your system with new security patches use the command 
`bash <(curl -s  https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)  --beta --nvidiaDriver 387.10.10.10.40.105 --iopcieTunneledPatch`

An update is in the works with new features, better security and much more, however due to heavy time constraints it will take a long time until it's finished. 

## Foreword
- You just stumbled across: Read the whole README.md.
- You want it: Get it, it’s free.
- You like it: Star it.
- You love it: [![paypal][image-1]][1]

## Purpose
Make your Mac compatible with NVIDIA and AMD eGPUs. Works on macOS High Sierra.

## Table of Contents
- [Requirements][2]
- [Howto][3]
	- [Important Information][4]
	- [Step by Step Guide][5]
- [Parameters][6]
	- [Basic][7]
	- [Packages][8]
	- [Advanced][9]
- [Example with parameters][10]
- [I used the temporary script/@goalque's instructions, what should I do?][11]
- [Problems][12]
	- [Known issues][13]
	- [Unknown issues][14]
- [Changelog][15]
- [Upcoming features][16]
- [Thanks to][17]

## Requirements
- macOS 10.13.X ≤ 10.13.6 (17G65)
- a NVIDIA or an AMD graphics card
- an eGPU enclosure (T82 & T83 controllers are supported)
- a Mac (TB 1/2/3 are supported)
- ***BACKUP***
- sufficiently disabled SIP; the script will abort with instructions otherwise
- macOS Terminal (iTerm does not work)

## Howto
Do not abort the script during uninstallation/installation/patch phase this *will* damage your system. 

### Important Information:
- NVIDIA eGPUs must not be hot unplugged, otherwise a kernel panic will occur. Completely shut down first.
- MacBook Pros (2016+) have automatic wake on power an lid opening. This will interfere with eGPU enclosures with power supply. To properly disconnect and shut down the MacBook Pro, choose *reboot* and unplug the moment the eGPU power shuts down. Then fully shutdown. It might help to disable wake (doesn’t work for all macOS’ and eGPU enclosures) by executing `sudo nvram AutoBoot=%00`. To reenable execute `sudo nvram AutoBoot=%03`.
- If you haven’t used an eGPU, the script may ask you about about your setup.
	- Since 10.13.6+ sometimes does not support my automatic eGPU information fetching anymore, prepare the following:
		- eGPU brand (NVIDIA/AMD)
		- T82/T83 Chip  
			Latter can be determined by plugging the eGPU in, opening the Systeminformation app, navigating to Hardware -\> Thunderbolt and searching for the word “unsupported”.  
			Unsupported means you have a T82 Chipset, if it's recognised correctly then you have an T83 Chipset.
	- In any other case the script may ***ask*** you to connect your eGPU during the process.  
		It is of utmost importance to only connect the eGPU once the script asks for it and then remove it once the script asks again. Never try to connect or disconnect if the script didn’t explicitly ask for it. You risk damaging the system.  
		For those, the script determines that a T82 unlock is necessary, must run the script once to unlock and then after a reboot a second time. The script would then not have been able to gather all information needed.


### Step by Step Guide:
1. If you have used an eGPU on macOS Sierra (10.12) or earlier please remove all used eGPU solutions. If you have not, skip this step.
2. Back up your system.
3. Disable SIP. This can be done by booting into recovery mode (command + R during boot), opening the terminal window (Utilities -\> Terminal) and execute  
	`csrutil disable; reboot`
4. Boot normally and log in.
5. Disconnect all unnecessary peripherals. Especially eGPUs!
6. Save your work. The script will ***kill*** all running programs.
7. Open the Terminal App. The script does not support iTerm.
8. Execute:  
	`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`  
	*It is not needed to customize the script with parameters. The script will then determine itself what the system needs.  
	Please follow the instructions given by the script.  
	If you have already used the script once the command `macos-egpu` is available to quicken access. The offline script will be automatically updated if executed with internet access.*

*A quick note to all the pros out there: the #sh shell does not support the syntax given above. You need a #bash shell.*

## Parameters
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh)`  
For second time use: `macos-egpu`


Parameters are optional. If none are provided, the script will self determine what to do.


### Basic
`--install | -i`

Tells the script to install/update eGPU software. *internet may be required*  
The install parameter tells the script to fetch your Mac’s parameters (such as installed software, installed patches, macOS version etc.) and to fetch the newest software versions. It then cross-references and deducts what needs to be done. This includes all packages listed below. This works best on new systems or systems that have been updated. Deductions on corrupt systems are limited. Note that earlier enablers for 10.12 won’t be touched. If you have used such software you must uninstall it yourself. To override deductions use the #Package parameters below.

`--uninstall | -U`

Tells the script to uninstall eGPU software.  
The uninstall parameter tells the script to search for eGPU software and fully uninstall it. Note that earlier enablers for 10.12 won’t be touched. If you have used such software you must uninstall it yourself. Note that only one thing won’t be uninstalled: The short command. To uninstall this one as well execute: `sudo rm /usr/local/bin/macos-egpu`. To override deductions use the #Package parameters below.

`--checkSystem | -C`

Tells the script to gather system information.
The check system command outputs basic information about eGPU software 
as well as basic system information.

`--checkSystemFull`

Tells the script to gather all available system information.
The check full system command outputs all possible information about 
eGPU software as well as system information.


### Packages
`--nvidiaDriver [revision] | -n [revision]`

Specify that the NVIDIA drivers shall be touched.  
The NVIDIA driver parameter tells the script to perform either an install or uninstall of the NVIDIA drivers. If the script determines that the currently installed NVIDIA driver shall be used after an update it will patch it. One can optionally specify a custom driver revision. The specified revision will automatically be patched, if necessary.

`--amdLegacyDriver | -a`

Specify that the AMD legacy drivers shall be touched. **drivers by @goalque**  
The AMD legacy driver parameter tells the script to make older AMD graphics cards compatible with macOS 10.13.X  
These include: 
- Polaris - RX: 460, 560 | Radeon Pro: WX5100, WX4100
- Fiji - R9: Fury X, Fury, Nano
- Hawaii - R9: 390X, 390, 290X, 290
- Tonga - R9: 380X, 380, 285
- Pitcairn - R9: 370X, 270X, 270 | R7: 370, 265 | FirePro: W7000
- Tahiti - R9: 280x, 280 | HD: 7970, 7870, 7850

`--nvidiaEGPUsupport | -e`

Specify that the NVIDIA eGPU support shall be touched. **kext by @yifanlu**  
The NVIDIA eGPU support parameter tells the script to make the NVIDIA drivers compatible with an NVIDIA eGPU. Therefore NVIDIA drivers must be installed in order to be applied.  
This command is for 10.13.5≤ only.  
On macOS 10.13.4/10.13.5 an additional patch is necessary. See `--unlockNvidia`.

`--deactivateNvidiaDGPU | -d`

Not yet available. Only for AMD eGPU users. **patch by @mac\_editor**

`--unlockThunderboltV12 | -V`

Specify that thunderbolt versions 1 and 2 shall be unlocked for use of an eGPU. **patch by @mac\_editor, @fricorico**  
The unlock thunderbolt v1, v2 parameter tells the script to make older Macs with thunderbolt ports of version 1 or 2 compatible for eGPU use. 
For NVIDIA users this is required only for macOS 10.13.4/10.13.5.
For AMD users this is required for macOS 10.13.6≤.

`--thunderboltDaemon | -A`

Specify that thunderbolt options shall be applied.  
The thunderbolt daemon parameter tells the script to create a launch daemon including the thunderbolt arguments. These arguments are reset after each boot which is why a daemon is necessary to keep them up to date. This is beneficial for NVIDIA dGPUs and multi eGPU setups.

`--unlockNvidia | -N`

Specify that NVIDIA eGPU support shall be unlocked. **patch by @fr34k, @goalque**  
The unlock NVIDIA parameter tells the script to make the Mac compatible with NVIDIA eGPUs.  
This is only required for macOS 10.13.4 and macOS 10.13.5. This might cause issues/crashes with AMD graphics cards (external).

`--iopcieTunneledPatch | -l`

Specify that NVIDIA eGPU support shall be unlocked. **patch by @goalque**  
The IOPCITunnelled Patch tells the script to make the Mac compatible with NVIDIA eGPUs.  
This is only required for macOS 10.3.6+. This might cause issues/crashes with AMD graphics cards (external).

`--nvidiaClosedClamshellPatch | -L`

Enables support for closed-clamshell mode when running with an NVIDIA eGPU. **patch by @sashavol**

`--unlockT82 | -T`

Specify that the T82 chipsets shall be unlocked.  
The unlock T82 parameter tells the script to make the Mac compatible with T82 eGPU enclosures. This is not reduced to eGPU enclosures all thunderbolt enclosures with T82 chipset will work.  

`--cudaDriver | -c`

Specify that CUDA drivers shall be touched.  
The CUDA driver parameter tells the script to perform either an install or uninstall of the CUDA drivers. Note that the CUDA driver is dependent on the NVIDIA drivers and cannot be installed without latter. Note that the toolkit and samples are dependent on the drivers. Uninstalling them will cause the script to uninstall the toolkit and samples as well.

`--cudaDeveloperDriver | -D`

Specify that CUDA developer drivers shall be touched.  
The CUDA developer drivers parameter tells the script to perform either an install or uninstall of the CUDA developer drivers. Note that the CUDA driver is dependent on the NVIDIA drivers and cannot be installed without latter. Note that the toolkit and samples are dependent on the developer/drivers. Uninstalling them will cause the script to uninstall the toolkit and samples as well. This should theoretically be identical to `--cudaDriver`

`--cudaToolkit | -t`

Specify that CUDA toolkit shall be touched.  
The CUDA toolkit parameter tells the script to perform either an install or uninstall of the CUDA toolkit. Note that the samples are dependent on the toolkit and the toolkit itself depends on the drivers. Uninstalling the toolkit will cause the script to uninstall the samples as well. Installing the toolkit will cause the script to install the drivers as well.

`--cudaSamples | -s`

Specify that CUDA samples shall be touched.  
The CUDA samples parameter tells the script to perform either an install or uninstall of the CUDA samples. Note that the samples are dependent on the toolkit and drivers. Installing the samples will cause the script to install the drivers and toolkit as well.

### Advanced
`--fullInstall | -F`

Select all #Packages. This might cause issues. Read the descriptions of the #Packages as well.

`--forceReinstall | -R`

Specify that the script shall reinstall already installed software.  
The force reinstall parameter tells the script to reinstall all software regardless if it already is up to date. This does not influence deductions or other installations.

`--forceNewest | -f`

Specify that the script shall install only newest software.  
The force newest parameter tells the script to prefer newer instead of more stable software. This might resolve and/or cause issues.

`--useForce | -o`

Specify that force shall be used.  
In some rare cases the script might not detect the presence of installed software. This is most likely due to faulty installations. Using force skips security checks for uninstalls. Therefore use with highest caution.  
It must be used in conjunction with a package name and `--uninstall`.

`--forceCacheRebuild | -E`

Specify that the caches shall be rebuild.  
The force cache rebuild flag rebuilds the kext, system and dyld cache. This option cannot be paired with other options.

`--noReboot | -r`

Specify that even if something has been done no reboot shall be performed.

`--acceptLicenseTerms`

Specify that the question of whether the license terms have been accepted shall be automatically answered with yes and then skipped.

`--skipWarnings | -k`

Specify that the initial warnings of the script shall be skipped.

`--beta`

Specify that an unsupported version of macOS in use.  
The beta flag removes checks for script requirements. Therefore, it is useful for beta testers. However, since these versions weren't checked by experienced users, the risk of damaging the system is extremely high.  
Only use with caution and backup.

`--help | -h`

Print the help document.

## Example with parameters
`bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) --install --nvidiaDriver 387.10.10.10.30.106`

`macos-egpu --install --nvidiaDriver 387.10.10.10.30.106 `

## I used the temporary script/@goalque's instructions, what should I do?
-  I haven't upgraded yet. I'm still on 17E199. I have used the temporary script.  
	-\> Upgrade to 10.13.5≤. Proceed with this script.
-  I have upgraded since.   
	-\> Execute: `sudo rm -rfv "/Library/Application Support/nvidia10134/"`  
	to remove the KEXT backup. Proceed with this script.
- I have used @goalque’s instructions.  
	-\> Upgrade to 10.13.5≤. Proceed with this script.

## Problems
### Known issues
- My internal monitor doesn't get boosted by the eGPU
	- normal, try a headless adapter and set to mirror
	- apps must be specifically coded for native eGPU to work on iM
	- use an external monitor
- My dGPU is not running the internal screen
	- **do not** deactivate automatic graphics switching
	- this is normal
- System crash on hot-disconnect
	- still researched
- System crash on disconnect button press
	- still reseachred
- Disconnect “(null)” on hot plug
	- still researched
	- does not influence system performance
	- can be mitigated by booting with eGPU
- Information in “About This Mac” is wrong
	- does not influence system performance
- Black external Monitor with/without mouse
	- Step set 1
		- boot without eGPU
		- hot plug eGPU with monitor
		- log out
	- Step set 2
		- boot without eGPU
		- hot plug eGPU only (no external monitor)
		- wait 15 sec
		- log out
		- hot plug monitor
		- wait 15 sec
		- log in
	- Step set 3
		- boot without eGPU
		- log out
		- hot plug eGPU
	- Step set 4 (no FileVault)
		- boot without eGPU
		- hot plug before first login
- I must use a headless HDMI to power my thunderbolt monitor (steps by @robert\_avram)
	- boot without any peripherals
	- hot plug eGPU only
	- log out
	- plug in headless HDMI into eGPU
	- plug in the thunderbolt display into the thunderbolt port next to the eGPU’s port
	- close the MBP’s lid
	- log in
	- select mirror display to mirror the headless
- OpenCL/GL seems not to work on NVIDIA eGPU + dGPU configs
	- still researched
- Macs with NVIDIA dGPU don't boot with TB3 enclosure and NVIDIA eGPU.
	- still researched, plugin during boot
- Mac owners with NVIDIA dGPU, please see [here][18].


### Unknown issues
If you’ve got a problem then try the tweaks (above) first.  
If nothing works  open an issue on GitHub or head over to [eGPU.io][19] and ask.  
**BUT** please include the output of the script when executing, as well as as much information about the issue as possible:  
`macos-egpu -C`  
(or `bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) -C`)

## Changelog
- version 1
	- 1.6
		- bugfix by @rxwei (GitHub)
	- 1.5
		- custom NVIDIA driver uninstaller
		- `--useForce`
		-  tons of bugfixes
	- v1.4
		- bugfixes
	- v1.3
		- 10.13.6 (17G2208) support
		- rearranged script requirement checks
	- v1.2
		- update short command first -\> enable seamless updates
	- v1.1
		- 10.13.6 (17G2112) support
	- v1
		- 10.13.6 (17G65) support
		- true offline short command `macos-egpu [parameter]` *internet not mandatory if not needed*
		- tons of bugfixes
- alpha
	- v0.2α
		- tons of bugfixes
		- `--beta`
		- `--thunderboltDaemon`
		- `--forceCacheRebuild`
		- better error handling, especially with the old wrangler bug
		- 10.13.5 support
		- short command install `macos-egpu [parameter]` *needs internet*
		- more restrictive program kill
	- v0.1α
		- bugfixes
		- `--help`
		- `--checkSystem`
		- `--checkSystemFull`


## Upcoming features
- *iTerm support*
	- will not come in the near future, would require double testing - no real benefit

## Thanks to
@goalque, @mac\_editor, @itsage, @yifanlu  
The people above were crucial for the development of this script.  
  
**Thank you.**

*@ shows that it’s the alias on eGPU.io*

[1]:	https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=learex2@icloud.com&lc=US&item_name=learex&no_note=0&currency_code=EUR&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest
[2]:	https://github.com/learex/macOS-eGPU#requirements
[3]:	https://github.com/learex/macOS-eGPU#howto
[4]:	https://github.com/learex/macOS-eGPU#important-information
[5]:	https://github.com/learex/macOS-eGPU#step-by-step-guide
[6]:	https://github.com/learex/macOS-eGPU#parameters
[7]:	https://github.com/learex/macOS-eGPU#basic
[8]:	https://github.com/learex/macOS-eGPU#packages
[9]:	https://github.com/learex/macOS-eGPU#advanced
[10]:	https://github.com/learex/macOS-eGPU#example-with-parameters
[11]:	https://github.com/learex/macOS-eGPU#i-used-the-temporary-scriptgoalques-instructions-what-should-i-do
[12]:	https://github.com/learex/macOS-eGPU#problems
[13]:	https://github.com/learex/macOS-eGPU#known-issues
[14]:	https://github.com/learex/macOS-eGPU#unknown-issues
[15]:	https://github.com/learex/macOS-eGPU#changelog
[16]:	https://github.com/learex/macOS-eGPU#upcoming-features
[17]:	https://github.com/learex/macOS-eGPU#thanks-to
[18]:	https://egpu.io/forums/mac-setup/script-fr34ks-macos-egpu-sh-one-script-all-solutions-fully-automated/paged/7/#post-36223
[19]:	https://egpu.io/forums/mac-setup/script-fr34ks-macos-egpu-sh-one-script-all-solutions-fully-automated/#post-35722 "Link to Thread"

[image-1]:	https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif

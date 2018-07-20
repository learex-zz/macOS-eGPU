#!/bin/bash

#   macOS-eGPU.sh
#
#   This script handles installation, updating and uninstallation of eGPU support for Mac.
#   AMD and NVIDIA cards, TI82 and T83 enclosures, TB 1/2 and 3, and CUDA are supported.
#
#   Created by learex on 05.04.18.
#
#   Authors: learex
#   Homepage: https://github.com/learex/macOS-eGPU
#   License: https://github.com/learex/macOS-eGPU/blob/master/License.txt
#
#   USAGE TERMS of macOS-eGPU.sh
#   1. You may use this script for personal use.
#   2. You may continue development of this script at it's GitHub homepage.
#   3. You may not redistribute this script or portions thereof from outside of it's GitHub homepage without explicit written permission.
#   4. You may not compile, assemble or in any other way make the source code unreadable by a human.
#   5. You may not implement this script or portions thereof into other scripts and/or applications without explicit written permission.
#   6. You may not use this script, or portions thereof, for any commercial purposes.
#   7. You accept the license terms of all downloaded and/or executed content, even content that has only indirectly been been downloaded and/or executed by macOS-eGPU.sh.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.




#   beginning of the script
#   It is forbidden to execute any code until the very last subroutine. The only execption is to parse incoming options.
#   Global variables are created as needed.


#   script specific information
branch="master"
warningOS="10.13.7"
currentOS="10.13.6"
gitPath="https://raw.githubusercontent.com/learex/macOS-eGPU/""$branch"
scriptVersion="v1"
debug=false

#   external programs
pbuddy="/usr/libexec/PlistBuddy"

#   sudo override
sudoActive=false
function sudov {
    if "$sudoActive"
    then
        sudo "$@"
    else
        "$@"
    fi
}

#   Subroutine A: Basic functions ##############################################################################################################
##  Subroutine A1: Directory handling
dirName="$(uuidgen)"
dirName="/var/tmp/""macOS.eGPU.""$dirName"

## tmpdir creator
function mktmpdir {
    if ! [ -d "$dirName" ]
    then
        mkdir -p "$dirName"
    fi
}

##  tmpdir destructor
function cleantmpdir {
    if [ -d "$dirName" ]
    then
        sudov rm -rf "$dirName"
    fi
}




##  Subroutine A2: Cleanup
#   DMG detachment
attachedDMGVolumes=""
function dmgDetatch {
    while read -r DMGVolumeToDetachTemp
    do
        if [ -d "$DMGVolumeToDetachTemp" ]
        then
            hdiutil detach "$DMGVolumeToDetachTemp" -quiet
        fi
    done <<< "$attachedDMGVolumes"
}

#   system cleanup
function systemClean {
    echoing "   cleaning system"
    cleantmpdir
    dmgDetatch
    echoend "done"
}

#   quit all running apps
function quitAllApps {
    ret=0
    if ! "$debug"
    then
        appsToQuitTemp=""
        appsToQuitTemp=$(osascript -e 'tell application "System Events" to set quitapps to name of every application process whose visible is true and name is not "Finder" and name is not "Terminal"' -e 'return quitapps') &>/dev/null
        if ( ! [[ "$appsToQuitTemp" == "" ]] ) || [[ `ps -A | grep "\-bash" | grep -v "grep" | wc -l | xargs` > 1 ]]
        then
            if [[ "$appsToQuitTemp" =~ "iTerm" ]]
            then
                echo
                echo "An open session of iTerm is detected. The script won't run with iTerm. Please use the Terminal app for now."
                irupt
            fi
            if [[ `ps -A | grep "\-bash" | grep -v "grep" | wc -l | xargs` > 1 ]]
            then
                echo
                echo
                echo `ps -A | grep "\-bash" | grep -v "grep" | wc -l | xargs`" Terminal sessions have been detected. Please only leave one open with which the script is executed."
                echo
                irupt
            fi
            appsToQuitTemp="${appsToQuitTemp//, /\n}"
            appsToQuitTemp="$(echo -e $appsToQuitTemp)"
            while read -r appNameToQuitTemp
            do
                killall "$appNameToQuitTemp"
                if [ "$?" != 0 ]
                then
                    ret=1
                fi
            done <<< "$appsToQuitTemp"
        fi
    fi
    return "$ret"
}




##  Subroutine A3: Print functions
#   print the whole help manual
function printUsage {
    printVariableTemp=`cat <<EOF
bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) [parameter]

Parameters are optional. If none are provided, the script will self determine what to do.

--- Basic ---

--install | -i

    Tells the script to install/update eGPU software. (internet may be required)
    The install parameter tells the script to fetch your Mac’s parameters
    (such as installed software, installed patches, macOS version etc.)
    and to fetch the newest software versions. It then cross-references and
    deducts what needs to be done. This includes all packages listed below.
    This works best on new systems or systems that have been updated.
    Deductions on corrupt systems are limited.
    Note that earlier enablers for 10.12 won’t be touched. 
    If you have used such software you must uninstall it yourself. 
    To override deductions use the #Package parameters below.

--uninstall | -U

    Tells the script to uninstall eGPU software.
    The uninstall parameter tells the script to search for eGPU software and 
    fully uninstall it. Note that earlier enablers for 10.12 won’t be touched. 
    If you have used such software you must uninstall it yourself. Note that
    only one thing won’t be uninstalled: The short command. 
    To uninstall this one as well execute: sudo rm /usr/local/bin/macos-egpu
    To override deductions use the #Package parameters below.

--checkSystem | -C

    Tells the script to gather system information.
    The check system command outputs basic information about eGPU software 
    as well as basic system information.

--checkSystemFull

    Tells the script to gather all available system information.
    The check full system command outputs all possible information about 
    eGPU software as well as system information.


--- Packages ---

--nvidiaDriver [revision] | -n [revision]

    Specify that the NVIDIA drivers shall be touched.
    The NVIDIA driver parameter tells the script to perform either an install
    or uninstall of the NVIDIA drivers. If the script determines that the
    currently installed NVIDIA driver shall be used after an update it will
    patch it. One can optionally specify a custom driver revision.
    The specified revision will automatically be patched, if necessary.

--amdLegacyDriver | -a

    Specify that the AMD legacy drivers shall be touched. (drivers by @goalque)
    The AMD legacy driver parameter tells the script to make older AMD graphics
    cards compatible with macOS 10.13.X
    These include:
        Polaris - RX: 460, 560 | Radeon Pro: WX5100, WX4100
        Fiji - R9: Fury X, Fury, Nano
        Hawaii - R9: 390X, 390, 290X, 290
        Tonga - R9: 380X, 380, 285
        Pitcairn - R9: 370X, 270X, 270 | R7: 370, 265 | FirePro: W7000
        Tahiti - R9: 280x, 280 | HD: 7970, 7870, 7850

--nvidiaEGPUsupport | -e

    Specify that the NVIDIA eGPU support shall be touched. (kext by yifanlu)
    The NVIDIA eGPU support parameter tells the script to make the
    NVIDIA drivers compatible with an NVIDIA eGPU. Therefore NVIDIA drivers
    must be installed in order to be applied.
    This command is for 10.13.5≤ only.
    On macOS 10.13.4/10.13.5 an additional patch is necessary.
        See --unlockNvidia.

--deactivateNvidiaDGPU | -d

    Not yet available. Only for AMD eGPU users. patch by @mac_editor

--unlockThunderboltV12 | -V

    Specify that thunderbolt versions 1 and 2 shall be unlocked
    for use of an eGPU. (patch by @mac_editor, @fricorico)
    The unlock thunderbolt v1, v2 parameter tells the script to make older Macs
    with thunderbolt ports of version 1 or 2 compatible for eGPU use.
    For NVIDIA users this is required only for macOS 10.13.4/10.13.5.
    For AMD users this is required for macOS 10.13.4+.

--thunderboltDaemon | -A

    Specify that thunderbolt options shall be applied.
    The thunderbolt daemon parameter tells the script to create a launch daemon
    including the thunderbolt arguments. These arguments are reset after each
    boot which is why a daemon is necessary to keep them up to date. This is
    beneficial for NVIDIA dGPUs and multi eGPU setups.

--unlockNvidia | -N

    Specify that NVIDIA eGPU support shall be unlocked.
    (patch by @fr34k, @goalque)
    The unlock NVIDIA parameter tells the script to make the Mac
    compatible with NVIDIA eGPUs.
    This is only required for macOS 10.13.4 and macOS 10.13.5.
    This might cause issues/crashes with AMD graphics cards (external).

--iopcieTunneledPatch | -l

    Specify that NVIDIA eGPU support shall be unlocked. (patch by @golaque)
    The IOPCITunnelled Patch tells the script to make the Mac
    compatible with NVIDIA eGPUs.
    This is only required for macOS 10.3.6+.
    This might cause issues/crashes with AMD graphics cards (external).

--unlockT82 | -T

    Specify that the T82 chipsets shall be unlocked.
    The unlock T82 parameter tells the script to make the Mac compatible
    with T82 eGPU enclosures. This is not reduced to eGPU enclosures all
    thunderbolt enclosures with T82 chipset will work.

--cudaDriver | -c

    Specify that CUDA drivers shall be touched.
    The CUDA driver parameter tells the script to perform either an install
    or uninstall of the CUDA drivers. Note that the CUDA driver is dependent
    on the NVIDIA drivers and cannot be installed without latter. 
    Note that the toolkit and samples are dependent on the drivers.
    Uninstalling them will cause the script
    to uninstall the toolkit and samples as well.

--cudaDeveloperDriver | -D

    Specify that CUDA developer drivers shall be touched.
    The CUDA developer drivers parameter tells the script to perform either
    an install or uninstall of the CUDA developer drivers. Note that the
    CUDA driver is dependent on the NVIDIA drivers and cannot be installed
    without latter. Note that the toolkit and samples are dependent on the
    developer/drivers. Uninstalling them will cause the script
    to uninstall the toolkit and samples as well.
    This should theoretically be identical to --cudaDriver

--cudaToolkit | -t

    Specify that CUDA toolkit shall be touched.
    The CUDA toolkit parameter tells the script to perform either an install
    or uninstall of the CUDA toolkit. Note that the samples are dependent on
    the toolkit and the toolkit itself depends on the drivers. Uninstalling the
    toolkit will cause the script to uninstall the samples as well. Installing
    the toolkit will cause the script to install the drivers as well.

--cudaSamples | -s

    Specify that CUDA samples shall be touched.
    The CUDA samples parameter tells the script to perform either an install or
    uninstall of the CUDA samples. Note that the samples are dependent on the
    toolkit and drivers. Installing the samples will cause the script to
    install the drivers and toolkit as well.


--- Advanced ---

--full | -F

    Select all #Packages. This might cause issues.
    Read the descriptions of the #Packages as well.

--forceReinstall | -R

    Specify that the script shall reinstall already installed software.
    The force reinstall parameter tells the script to reinstall all software
    regardless if it already is up to date.
    This does not influence deductions or other installations.

--forceNewest | -f

    Specify that the script shall install only newest software.
    The force newest parameter tells the script to prefer newer instead of more
    stable software. This might resolve and/or cause issues.

--forceCacheRebuild | -h

    Specify that the caches shall be rebuild.
    The force cache rebuild flag rebuilds the kext, system and dyld cache.
    This option cannot be paired with other options.

--noReboot | -r

    Specify that even if something has been done no reboot shall be performed.

--acceptLicenseTerms

    Specify that the question of whether the license terms have been accepted
    shall be automatically answered with yes and then skipped.

--skipWarnings | -k

    Specify that the initial warnings of the script shall be skipped.

--beta

    Specify that an unsupported version of macOS in use.
    The beta flag removes checks for script requirements. Therefore, it is
    useful for beta testers. However, since these versions weren't checked by
    experienced users, the risk of damaging the system is extremely high.
    Only use with caution and backup.

--help | -h

    Print this help document

--- Example with parameters ---

bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) --install --nvidiaDriver 387.10.10.10.30.106

macOS-eGPU  --install --nvidiaDriver 387.10.10.10.30.106

--- Issues ---
Please visit https://github.com/learex/macOS-eGPU#problems
EOF
`
    echo "$printVariableTemp"
}

#   print the short instructions for pro users
function printShortHelp {
    printVariableTemp=`cat <<EOF

bash <(curl -s https://raw.githubusercontent.com/learex/macOS-eGPU/master/macOS-eGPU.sh) [parameter]
parameter:
    --install | -i                  | --uninstall | -U
    --checkSystem | -C              | --checkSystemFull

    --nvidiaDriver [rev] | -n [rev] | --amdLegacyDriver | -a
    --nvidiaEGPUsupport | -e        | --deactivateNvidiaDGPU | -d
    --unlockThunderboltV12 | -V     | --unlockNvidia | -N
    --unlockT82 | -T                | --iopcieTunneledPatch | -l
    --cudaDriver | -c               | --cudaDeveloperDriver | -D
    --cudaToolkit | -t              | --thunderboltDaemon | -A

    --full | -F                     | --forceReinstall | -R
    --forceNewest | -f              | --noReboot | -r
    --acceptLicenseTerms            | --skipWarnings | -k
    --help | -h                     | --beta
    --forceCacheRebuild | -h
EOF
`
    echo "$printVariableTemp"
}

#   print license
function printLicense {
    printVariableTemp=`cat <<EOF
USAGE TERMS of macOS-eGPU.sh
#   1. You may use this script for personal use.
#   2. You may continue development of this script at it's GitHub homepage.
#   3. You may not redistribute this script or portions thereof from outside of it's GitHub homepage without explicit written permission.
#   4. You may not compile, assemble or in any other way make the source code unreadable by a human.
#   5. You may not implement this script or portions thereof into other scripts and/or applications without explicit written permission.
#   6. You may not use this script, or portions thereof, for any commercial purposes.
#   7. You accept the license terms of all downloaded and/or executed content, even content that has only indirectly been been downloaded and/or executed by macOS-eGPU.sh.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.
EOF
`
    echo "$printVariableTemp"
}



##  Subroutine A4: Waiter
function waiter {
    for i in `seq "$1" 1`
    do
        echo -n "$i"".."
        sleep 1
    done
    echo "0"
}




##  Subroutine A5: Aquire elevated privileges
function elevatePrivileges {
    if "$sudoActive" || [ "$(id -u)" == 0 ]
    then
        sudo -v
        if [ "$?" != 0 ]
        then
            echoend "FAILURE" 1
            echo "Elevated privileges could not be aquired. The script will now stop."
            irupt
        fi
    else
        sudo -k
        echo "   elevating privileges"
        echo -n "   "
        lastLength=12
        sudo -v
        if [ "$?" != 0 ]
        then
            echoing "   checking for elevated privileges"
            echoend "FAILURE" 1
            echo "Elevated privileges could not be aquired. The script will now stop."
            irupt
        fi
        echoing "   checking for elevated privileges"
        echoend "OK" 2
    fi
    sudoActive=true
}




##  Subroutine A6: Restore privileges
function restorePrivileges {
    sudo -k
}





##  Subroutine A7: Reboot
scheduleReboot=false
noReboot=false
function rebootSystem {
    if ! "$scheduleReboot" || "$noReboot" || "$debug"
    then
        echo "A reboot of the system is recommended."
    else
        echo "A reboot will soon be performed..."
        elevatePrivileges
        trap '{ echo; echo "Abort..."; exit 1; }' INT
        waiter 5
        echo "reboot: / is busy updating, waiting for lock (this might take approx 15-30s)..."
        sudo reboot & &>/dev/null
        sleep 1
    fi
    echo
    restorePrivileges
    exit
}




##  Subroutine A8: Rebuild Kexts
scheduleKextTouch=false
function rebuildKextCache {
    if "$scheduleKextTouch"
    then
        echo "Rebuilding caches"
        elevatePrivileges
        echoing "   kext cache"
        sudo touch /System/Library/Extensions &>/dev/null
        sudo kextcache -q -update-volume / &>/dev/null
        echoend "done"
        echoing "   system cache"
        sudo touch /System/Library/Extensions &>/dev/null
        sudo kextcache -system-caches &>/dev/null
        echoend "done"
        echoing "   dyld cache"
        sudo update_dyld_shared_cache -root / -force &>/dev/null
        sudo update_dyld_shared_cache -debug &>/dev/null
        sudo update_dyld_shared_cache &>/dev/null
        echoend "done"
    fi
}




##  Subroutine A9: Finish
doneSomething=false
function finish {
    createSpace 2
    echo "Finish..."
    systemClean
    if "$doneSomething"
    then
        rebuildKextCache
        rebootSystem
    else
        echo "Nothing has been changed."
    fi
    restorePrivileges
    echo
    exit
}




##  Subroutine A10: Interrupt
function irupt {
    echo "Interrupt..."
    systemClean
    restorePrivileges
    echo "The script has failed."
    if "$doneSomething"
    then
        rebuildKextCache
    else
        echo "Nothing has been changed."
    fi
    echo
    exit 1
}




##  Subroutine A11: Trap functions
exitScript=false
function trapIrupt {
    if ! "$exitScript"
    then
        exitScript=true
        echo "You pressed ^C. Exiting the script during execution might render your system unrepairable."
        echo "Recommendation: Let the script finish and then run again with uninstall parameter."
        echo "Press again to force quit. Beware of the consequenses."
        sleep 5
    else
        irupt
    fi
}

function trapWithWarning {
    trap trapIrupt INT
}

function trapWithoutWarning {
    trap '{ echo; echo "Abort..."; irupt; }' INT
}

function trapLock {
    trap '' INT
}




##  Subroutine A12: Custom uninstaller
function genericUninstaller {
    elevatePrivileges
    fileListUninstallTemp="$1"
    genericUninstalledTemp=false
    while read -r genericFileTemp
    do
        if [ -e "$genericFileTemp" ]
        then
            genericUninstalledTemp=true
            sudo rm -r -f "$genericFileTemp"
        fi
    done <<< "$fileListUninstallTemp"
    if "$genericUninstalledTemp"
    then
        return 0
    else
        return 1
    fi
}




##  Subroutine A13: Binary Hasher
binaryHashReturn=""
function binaryHasher {
    testDump=$(hexdump -ve '1/1 "%.2X"' "$1" &>/dev/null)
    if [ $? != 0 ]
    then
        echo
        echo "iterupting execution flow..."
        echo "--- incorrect permissions detected ---"
        elevatePrivileges
        sudo chmod 755 "$1"
        echo "--- incorrect permissions fixed ---"
        echo "continuing execution flow..."
        echo
    fi
    hashval1Temp=$(hexdump -ve '1/1 "%.2X"' "$1" | sed "s/.*3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D38223F3E0A3C21444F435459504520706C697374205055424C494320222D2F2F4170706C652F2F44544420504C49535420312E302F2F454E222022687474703A2F2F7777772E6170706C652E636F6D2F445444732F50726F70657274794C6973742D312E302E647464223E0A3C706C6973742076657273696F6E3D22312E30223E0A3C646963743E0A093C6B65793E63646861736865733C2F6B65793E//g")
    hashval2Temp=$(xxd -s -128 "$1")
    hashvalTemp=$(echo "$hashval1Temp""$hashval2Temp" | shasum -a 512 -b | awk '{ print $1 }')
    binaryHashReturn="$hashvalTemp"
}




##  Subroutine A14: Flow hex editor
function genericHexEditor {
    elevatePrivileges
    (sudo hexdump -ve '1/1 "%.2X"' "$3" | sed "s/$1/$2/g" | xxd -r -p )> "$4"
}




##  Subroutine A15: Inplace hex editor
function inPlaceEditor {
    elevatePrivileges
    mktmpdir
    tempBinaryPath="$dirName""/binFile"
    filePermissionsTemp=$(stat -f "%A" "$3")
    fileOwnershipTemp=$(stat -f "%Su:%Sg" "$3")
    genericHexEditor "$1" "$2" "$3" "$tempBinaryPath"
    sudo rm "$3"
    sudo cp "$tempBinaryPath" "$3"
    sudo chmod "$filePermissionsTemp" "$3"
    sudo chown "$fileOwnershipTemp" "$3"
    sudo rm "$tempBinaryPath"
}

##  Subroutine A16: Echo helpers
lastLength=0
doneLine=`expr $(tput cols)`
function echoing {
    echo -n "$1"
    lastLength=`echo -n "$1" | wc -c | xargs`
}

function echoend {
    lenTemp=`echo -n "$1" | wc -c | xargs`
    for i in `seq 1 $(expr "$doneLine" - $lenTemp - 2 - "$lastLength")`
    do
        echo -n " "
    done
    if [ "$2" != "" ]
    then
        tput setaf "$2"
    fi
    echo "[$1]"
    if [ "$2" != "" ]
    then
        tput sgr0
    fi
}

function createSpace {
    for i in `seq 1 $1`
    do
        echo
    done
}




##  Subroutine A17: binary parser
function binaryParser {
    nbitTemp=`dc -e "$1 2 $2 ^ / 2 % n"`
    if [ "$nbitTemp" != "$3" ]
    then
        if [ "$nbitTemp" == 1 ]
        then
            dc -e "$1 2 $2 ^ - n"
        else
            dc -e "$1 2 $2 ^ + n"
        fi
    else
        echo "$1"
    fi
}




#   Subroutine B: System checks ##############################################################################################################
os=""
build=""
function fetchOSinfo {
    os="$(sw_vers -productVersion)"
    build="$(sw_vers -buildVersion)"
}

#   0: completely disabled, 127: fully enabled, 128: error, 31: --without KEXT
#   Binary of: Apple Internal | Kext Signing | Filesystem Protections | Debugging Restrictions | DTrace Restrictions | NVRAM Protections | BaseSystem Verification
statSIP=128
function fetchSIPstat {
    SIPTemp="$(csrutil status)"
    if [[ "$SIPTemp[@]" =~ "Custom Configuration" ]]
    then
        appleInternalTemp=`echo "$SIPTemp" | sed -n 4p`
        kextSigningTemp=`echo "$SIPTemp" | sed -n 5p`
        fileSystemProtectionsTemp=`echo "$SIPTemp" | sed -n 6p`
        debuggingRestrictionsTemp=`echo "$SIPTemp" | sed -n 7p`
        dTraceRestrictionsTemp=`echo "$SIPTemp" | sed -n 8p`
        nvramProtectionsTemp=`echo "$SIPTemp" | sed -n 9p`
        baseSystemVerificationTemp=`echo "$SIPTemp" | sed -n 10p`
        appleInternalTemp="${appleInternalTemp##*: }"
        kextSigningTemp="${appleInternalTemp##*: }"
        fileSystemProtectionsTemp="${fileSystemProtectionsTemp##*: }"
        debuggingRestrictionsTemp="${debuggingRestrictionsTemp##*: }"
        dTraceRestrictionsTemp="${dTraceRestrictionsTemp##*: }"
        nvramProtectionsTemp="${nvramProtectionsTemp##*: }"
        baseSystemVerificationTemp="${baseSystemVerificationTemp##*: }"
        pTemp=1
        statSIP=0
        for SIPXTemp in "$baseSystemVerificationTemp" "$nvramProtectionsTemp" "$dTraceRestrictionsTemp" "$debuggingRestrictionsTemp" "$fileSystemProtectionsTemp" "$kextSigningTemp" "$appleInternalTemp"
        do
            if [ "$SIPXTemp" == "enabled" ]
            then
                statSIP="$(expr $statSIP + $pTemp)"
            fi
            pTemp="$(expr $pTemp \* 2)"
        done
    else
        keywordTemp="${SIPTemp#*: }"
        if [[ "${keywordTemp%% *}" =~ "enabled" ]]
        then
            statSIP=127
        else
            statSIP=0
        fi
    fi
}

thunderboltInterface=0
function fetchThunderboltInterface {
    thunderboltTemp=`ioreg | grep AppleThunderboltNHIType | sed -n 1p`
    thunderboltTemp="${thunderboltTemp##*+-o AppleThunderboltNHIType}"
    thunderboltInterface="${thunderboltTemp::1}"
    if [ "$thunderboltInterface" == "" ]
    then
        thunderboltInterface=0
    fi
}

nvidiaDGPU=false
function fetchNvidiaDGPU {
    nvidiaDGPU=false
    displayListTemp=$(system_profiler SPDisplaysDataType | grep -v ": " | grep " " | xargs)
    displayListTemp="$displayListTemp"" "
    displayListTemp="${displayListTemp//: /\n}"
    displayListTemp=$(echo -e -n "$displayListTemp")

    pcieListTemp=$(system_profiler SPPCIDataType | grep -v ": " | grep " " | xargs)
    pcieListTemp="$pcieListTemp"" "
    pcieListTemp="${pcieListTemp//: /\n}"
    pcieListTemp=$(echo -e -n "$pcieListTemp")

    listOfPossibleDGPUTemp=""
    while read -r displayTemp
    do
        matchTemp=false
        while read -r pcieTemp
        do
            if [[ "$displayTemp" == "$pcieTemp" ]]
            then
                matchTemp=true
            fi
        done <<< "$pcieListTemp"
        if ! "$matchTemp"
        then
            listOfPossibleDGPUTemp="$listOfPossibleDGPUTemp""$displayTemp""\n"
        fi
    done <<< "$displayListTemp"
    listOfPossibleDGPUTemp=$(echo -e -n "$listOfPossibleDGPUTemp")
    if [[ "$listOfPossibleDGPUTemp[@]" =~ "NVIDIA" ]]
    then
        nvidiaDGPU=true
    fi
}

connectedEGPU=false
connectedEGPUVendor=""
eGPUdriverInstalled=""
function fetchConnectedEGPU {
    ret=0
    connectedEGPU=false
    pciTemp=`system_profiler SPPCIDataType`
    vendorsTemp=`echo "$pciTemp" | grep "Vendor" | grep -v "Subsystem"`
    usedSlotsTemp=`echo "$pciTemp" | grep "Slot"`
    countTemp=`echo "$vendorsTemp" | wc -l | xargs`
    countTemp2=`echo "$usedSlotsTemp" | wc -l | xargs`
    if [ "$countTemp" == "$countTemp2" ]
    then
        for i in `seq 1 "$countTemp"`
        do
            usedSlotTemp=`echo "$usedSlotsTemp" | sed -n "$i"p`
            vendorTemp=`echo "$vendorsTemp" | sed -n "$i"p`
            if [[ "$usedSlotTemp" =~ "Thunderbolt" ]]
            then
                case "$vendorTemp"
                in
                *"0x10de"*)
                    connectedEGPU=true
                    connectedEGPUVendor="NVIDIA"
                    ;;
                *"0x1002"*)
                    connectedEGPU=true
                    connectedEGPUVendor="AMD"
                    ;;
                *)
                    ;;
                esac
            fi
        done
    else
        ret=1
    fi
    return "$ret"
}

appleGPUWranglerVersion=""
function translateAppleGPUWranglerVersionHash {
    appleGPUWranglerVersion=""
    case "$1"
    in
    "6606536cd546fbaf6571e3f6e0a815e4e9b06e135812322c7d2a899cffb42ca3a3fc7ef248cb81ae82c558a761bb75c9d852c38e744686ce1b38ad108d269c51")
        appleGPUWranglerVersion="10.13.2:17C88,17C89,17C205,17C2120,17C2205"
        ;;
    "ea9dc6330ba9be64e0403e1b2d30db5483ff117ea2ceb37d90ce6671768a3d13200ceb29f2336a4a908e7665a461187ee3afc214fea4bc01ae2bbfd1b3dfe231")
        appleGPUWranglerVersion="10.13.3:17D47,17D102"
        ;;
    "c13a0bf6c3215b65430242b588f2039f5943c97ada42b3a176de30417b2ab79f3996401e60cbd956b8de63303c282ded8fa1667c64ec3eb241dcc84d86b33241")
        appleGPUWranglerVersion="10.13.3:17D2047,17D2102,17D2104"
        ;;
    "5cecaea9a06812f195e9c6ce6f755a20c623dc8e12222eaee0118c8f8a0fe42e3167d206eb85d5a55ceeeaa9aa55cd9b13433294a3d5de4f9d24f93e07dd67f6")
        appleGPUWranglerVersion="10.13.4:17E199"
        ;;
    "459cba0c4c96cd751ff5d69857901a550ebcd99929d75860d864ae3950a6a1250e30d88ebae0823dfc1544b05b94c3b9b0c1cdfaeb74735d8c69a9438ddf66b4")
        appleGPUWranglerVersion="10.13.4:17E202"
        ;;
    "88411a9cb7d0949fb2eb688281729edbd06f34e41e051a5fb37bf31bd3dbfe6f3d36bfb8917249a4717409417e761b588e7cabad0944602255836b2c1cce4849")
        appleGPUWranglerVersion="10.13.5:17F77"
        ;;
    "51b5608fc6918f7a3b7edc263e721199109663739be260481ef9b6c14747736407cdfc61290f5ae9030aff35718944777828e5fdd0bb5da2674e998ea534f47c")
        appleGPUWranglerVersion="10.13.6:17G65"
        ;;
    esac
}

appleGraphicsControlPath="/System/Library/Extensions/AppleGraphicsControl.kext"
appleGPUwranglerPath="$appleGraphicsControlPath""/Contents/PlugIns/AppleGPUWrangler.kext"
appleGPUwranglerBinaryPath="$appleGPUwranglerPath""/Contents/MacOS/AppleGPUWrangler"
function fetchAppleGPUWranglerVersion {
    binaryHasher "$appleGPUwranglerBinaryPath"
    translateAppleGPUWranglerVersionHash "$binaryHashReturn"
}

programList=""
function fetchInstalledPrograms {
    appListPathsTemp="$(find /Applications -iname *.app -maxdepth 3)"
    appListTemp=""
    while read -r appTemp
    do
        appTemp="${appTemp##*/}"
        appListTemp="$appListTemp""${appTemp%.*}""\n"
    done <<< "$appListPathsTemp"
    programList="$(echo -e -n $appListTemp)"
}


internet=false
function checkInternetConnection {
    internet=false
    ping 8.8.8.8 -c 1 -t 3 &> /dev/null
    if [ "$?" == 0 ]
    then
        internet=true
    fi
}



#   Subroutine C: NVIDIA drivers ##############################################################################################################
##  Subroutine C1: Global variables
nvidiaDriversInstalled=false
nvidiaDriverVersion=""
nvidiaDriverBuildVersion=""

nvidiaDriverUnInstallPKG="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
nvidiaDriverVersionPath="/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist"

nvidiaDriverNListOnline="https://gfe.nvidia.com/mac-update"
nvidiaDriverListOnline="$gitPath""/Data/nvidiaDriver.plist"

foundMatchNvidiaDriver=false

customNvidiaDriver=false
forceNewest=false
omitNvidiaDriver=false

nvidiaDriverDownloadVersion=""
nvidiaDriverDownloadLink=""
nvidiaDriverDownloadChecksum=""




##  Subroutine C2: Check functions
function checkNvidiaDriverInstallReset {
    nvidiaDriversInstalled=false
    nvidiaDriverVersion=""
    nvidiaDriverBuildVersion=""
}

function checkNvidiaDriverInstall {
    if [ -e "$nvidiaDriverUnInstallPKG" ]
    then
        nvidiaDriversInstalled=true
        nvidiaDriverVersion=$("$pbuddy" -c "Print CFBundleGetInfoString" "$nvidiaDriverVersionPath")
        nvidiaDriverVersion="${nvidiaDriverVersion##* }"
        nvidiaDriverBuildVersion=$("$pbuddy" -c "Print IOKitPersonalities:NVDAStartup:NVDARequiredOS" "$nvidiaDriverVersionPath")
    fi
}




##  Subroutine C3: Uninstaller
function uninstallNvidiaDriver {
    if "$nvidiaDriversInstalled"
    then
        elevatePrivileges
        sudo installer -pkg "$nvidiaDriverUnInstallPKG" -target / &>/dev/null
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine C4: Downloader
function downloadNvidiaDriverInformation {
    mktmpdir
    foundMatchNvidiaDriver=false
    if "$forceNewest"
    then
        nvidiaDriverListTemp="$dirName""/nvidiaDriver.plist"
        curl -s "$nvidiaDriverNListOnline" -m 1024 > "$nvidiaDriverListTemp"
        if [ "$?" == 0 ]
        then
            driversTemp=$("$pbuddy" -c "Print updates:" "$nvidiaDriverListTemp" | grep "OS" | awk '{print $3}')
            driverCountTemp=$(echo "$driversTemp" | wc -l | xargs)
            for index in `seq 0 $(expr $driverCountTemp - 1)`
            do
                buildTemp=$("$pbuddy" -c "Print updates:$index:OS" "$nvidiaDriverListTemp")
                nvidiaDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$nvidiaDriverListTemp")
                nvidiaDriverLinkTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$nvidiaDriverListTemp")
                nvidiaDriverChecksumTemp=$("$pbuddy" -c "Print updates:$index:checksum" "$nvidiaDriverListTemp")

                if [ "$build" == "$buildTemp" ]
                then
                    nvidiaDriverDownloadVersion="$nvidiaDriverVersionTemp"
                    nvidiaDriverDownloadLink="$nvidiaDriverLinkTemp"
                    nvidiaDriverDownloadChecksum="$nvidiaDriverChecksumTemp"
                    foundMatchNvidiaDriver=true
                fi
            done
            rm "$nvidiaDriverListTemp"
        fi
    elif "$customNvidiaDriver"
    then
        nvidiaDriverListTemp="$dirName""/nvidiaDriver.plist"
        curl -s "$nvidiaDriverNListOnline" -m 1024 > "$nvidiaDriverListTemp"
        if [ "$?" == 0 ]
        then
            driversTemp=$("$pbuddy" -c "Print updates:" "$nvidiaDriverListTemp" | grep "OS" | awk '{print $3}')
            driverCountTemp=$(echo "$driversTemp" | wc -l | xargs)
            for index in `seq 0 $(expr $driverCountTemp - 1)`
            do
                buildTemp=$("$pbuddy" -c "Print updates:$index:OS" "$nvidiaDriverListTemp")
                nvidiaDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$nvidiaDriverListTemp")
                nvidiaDriverLinkTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$nvidiaDriverListTemp")
                nvidiaDriverChecksumTemp=$("$pbuddy" -c "Print updates:$index:checksum" "$nvidiaDriverListTemp")

                if [ "$nvidiaDriverDownloadVersion" == "$nvidiaDriverVersionTemp" ]
                then
                    nvidiaDriverDownloadVersion="$nvidiaDriverVersionTemp"
                    nvidiaDriverDownloadLink="$nvidiaDriverLinkTemp"
                    nvidiaDriverDownloadChecksum="$nvidiaDriverChecksumTemp"
                    foundMatchNvidiaDriver=true
                fi
            done
            rm "$nvidiaDriverListTemp"
        fi
    else
        nvidiaDriverListTemp="$dirName""/nvidiaDriver.plist"
        curl -s "$nvidiaDriverListOnline" -m 1024 > "$nvidiaDriverListTemp"
        if [ "$?" == 0 ]
        then
            driversTemp=$("$pbuddy" -c "Print updates:" "$nvidiaDriverListTemp" | grep "OS" | awk '{print $3}')
            driverCountTemp=$(echo "$driversTemp" | wc -l | xargs)
            for index in `seq 0 $(expr $driverCountTemp - 1)`
            do
                buildTemp=$("$pbuddy" -c "Print updates:$index:build" "$nvidiaDriverListTemp")
                nvidiaDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$nvidiaDriverListTemp")
                nvidiaDriverLinkTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$nvidiaDriverListTemp")
                nvidiaDriverChecksumTemp=$("$pbuddy" -c "Print updates:$index:checksum" "$nvidiaDriverListTemp")

                if [ "$build" == "$buildTemp" ]
                then
                    nvidiaDriverDownloadVersion="$nvidiaDriverVersionTemp"
                    nvidiaDriverDownloadLink="$nvidiaDriverLinkTemp"
                    nvidiaDriverDownloadChecksum="$nvidiaDriverChecksumTemp"
                    foundMatchNvidiaDriver=true
                fi
            done
            rm "$nvidiaDriverListTemp"
        fi
    fi
}

function downloadNvidiaDriver {
    if "$foundMatchNvidiaDriver"
    then
        mktmpdir
        sudov curl -o "$dirName""/nvidiaDriver.pkg" "$nvidiaDriverDownloadLink" "-#" -m 1024
        nvidiaDriverChecksumTemp=$(shasum -a 512 -b "$dirName""/nvidiaDriver.pkg" | awk '{ print $1 }')
        if [ "$nvidiaDriverDownloadChecksum" != "$nvidiaDriverChecksumTemp" ]
        then
            omitNvidiaDriver=true
        fi
    else
        omitNvidiaDriver=true
    fi
}




##  Subroutine C5: Installer/Patcher
#   Credit: This code logic is inspired by Benjamin Dobell's nvidia-update.sh
function patchNvidiaDriverNew {
    mktmpdir
    fetchOSinfo
    elevatePrivileges

    expansionTemp="$dirName""/nvidiaDriverExpansion"
    payloadTemp="$dirName""/payloadExpansion"

    sudo pkgutil --expand "$dirName""/nvidiaDriver.pkg" "$expansionTemp"

    if [ `cat "$expansionTemp"/Distribution | grep "var supportedOSBuildVer" | xargs | awk '{ print $4 }' | sed 's/;//g'` != "$build" ]
    then
        mkdir "$payloadTemp"

        driverPathTemp=$(ls "$expansionTemp" | grep "NVWebDrivers.pkg")
        driverPathTemp="$expansionTemp""/""$driverPathTemp"

        sudo cat "$expansionTemp""/Distribution" | sed '/installation-check/d' | sudo tee "$expansionTemp""/PatchDist" &>/dev/null
        sudo mv "$expansionTemp""/PatchDist" "$expansionTemp""/Distribution"

        (cd "$payloadTemp"; sudo cat "$driverPathTemp""/Payload" | gunzip -dc | cpio -i --quiet)
        "$pbuddy" -c "Set IOKitPersonalities:NVDAStartup:NVDARequiredOS ""$build" "$payloadTemp""/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist"
        sudo chown -R root:wheel "$payloadTemp/"

        (cd "$payloadTemp"; sudo find . | sudo cpio -o --quiet | gzip -c | sudo tee "$driverPathTemp""/Payload" &>/dev/null)
        (cd "$payloadTemp"; sudo mkbom . "$driverPathTemp""/Bom")

        sudo rm -rf "$payloadTemp"
        sudo rm -rf "$dirName""/nvidiaDriver.pkg"

        sudo pkgutil --flatten "$expansionTemp" "$dirName""/nvidiaDriver.pkg"
        sudo chown "$(id -un):$(id -gn)" "$dirName""/nvidiaDriver.pkg"
    fi
    sudo rm -rf "$expansionTemp"
}

function patchNvidiaDriverOld {
    elevatePrivileges
    sudo "$pbuddy" -c "Set IOKitPersonalities:NVDAStartup:NVDARequiredOS ""$build" "$nvidiaDriverVersionPath" &>/dev/null
}

function installNvidiaDriver {
    if [ -e "$dirName""/nvidiaDriver.pkg" ]
    then
        elevatePrivileges
        patchNvidiaDriverNew
        sudo installer -pkg "$dirName""/nvidiaDriver.pkg" -target / &>/dev/null
        sudov rm -f "$dirName""/nvidiaDriver.pkg"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine C6: Helper functions




#   Subroutine D: CUDA drivers ##############################################################################################################
##  Subroutine D1: Global variables

cudaLatest=true
toolkitLatest=true

cudaDriverVersion=""
cudaVersionFull=""
cudaVersion=""
cudaVersionsInstalledList=""
cudaVersionsNum=0
cudaVersionInstalled=false
cudaDriverInstalled=false
cudaDeveloperDriverInstalled=false
cudaToolkitInstalled=false
cudaSamplesInstalled=false

cudaToolkitUnInstallDir=""
cudaToolkitUnInstallScriptName=""
cudaToolkitUnInstallScriptPath=""
cudaDeveloperDriverUnInstallScriptPath="/usr/local/bin/uninstall_cuda_drv.pl"

cudaDriverListOnline="$gitPath""/Data/cudaDriver.plist"
cudaToolkitListOnline="$gitPath""/Data/cudaToolkit.plist"
cudaAppListOnline="$gitPath""/Data/cudaApps.plist"
cudaDriverWebsite="http://www.nvidia.com/object/cuda-mac-driver.html"
cudaToolkitWebsite="https://developer.nvidia.com/cuda-downloads?target_os=MacOSX&target_arch=x86_64&target_version=1013&target_type=dmglocal"

cudaDriverDownloadLink=""
cudaDriverDownloadVersion=""

cudaToolkitDownloadLink=""
cudaToolkitDownloadVersion=""

cudaDriverVolPath="/Volumes/CUDADriver/"
cudaDriverPKGName="CUDADriver.pkg"
cudaToolkitVolPath="/Volumes/CUDAMacOSXInstaller/"
cudaToolkitPKGName="CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller"

cudaDriverFrameworkPath="/Library/Frameworks/CUDA.framework"
cudaDriverLaunchAgentPath="/Library/LaunchAgents/com.nvidia.CUDASoftwareUpdate.plist"
cudaDriverPrefPanePath="/Library/PreferencePanes/CUDA Preferences.prefPane"
cudaDriverKextPath="/Library/Extensions/CUDA.kext"
cudaDeveloperDir="/Developer/NVIDIA/"
cudaSamplesDir=""

cudaVersionPath=""
cudaDriverVersionPath="/Library/Frameworks/CUDA.framework/Versions/A/Resources/Info.plist"

#forceNewest=false - defined at Subroutine C: NVIDIA drivers
scheduleCudaDeduction=0
cudaRoutine=0
forceCudaToolkitStable=false
forceCudaDriverStable=false
omitCuda=false
foundMatchCudaDriver=false
foundMatchCudaToolkit=false

attachedDMGVolumes="$attachedDMGVolumes""$cudaDriverVolPath""\n"
attachedDMGVolumes="$attachedDMGVolumes""$cudaToolkitVolPath""\n"





##  Subroutine D2: Check functions
function checkCudaInstallReset {
    cudaVersionFull=""
    cudaVersion=""
    cudaVersionsInstalledList=""
    cudaVersionsNum=0
    cudaVersionInstalled=false
    cudaDriverInstalled=false
    cudaDeveloperDriverInstalled=false
    cudaToolkitInstalled=false
    cudaSamplesInstalled=false
}

function readCudaDeveloperVersion {
    cudaVersionFull="$(cat $cudaVersionPath)"
    cudaVersionFull="${cudaVersionFull##CUDA Version }"
    cudaVersion="${cudaVersionFull%.*}"
}

function readCudaToolkitVersions {
    cudaDirContentTemp="$(ls $cudaDeveloperDir)"
    while read -r folderTemp
    do
        if [ "${folderTemp%%-*}" == "CUDA" ]
        then
            cudaVersionsInstalledList="$cudaVersionsInstalledList""${folderTemp#CUDA-}\n"
        fi
    done <<< "$cudaDirContentTemp"
    cudaVersionsInstalledList="$(echo -e -n $cudaVersionsInstalledList)"
    cudaVersionsNum="$(echo $cudaVersionsInstalledList | wc -l | xargs)"
}

function refineCudaToolkitInstallationStatus {
    if "$cudaVersionInstalled"
    then
        cudaToolkitUnInstallDir="/Developer/NVIDIA/CUDA-""$cudaVersion""/bin/"
        cudaToolkitUnInstallScriptName="uninstall_cuda_""$cudaVersion"".pl"
        cudaToolkitUnInstallScriptPath="$cudaToolkitUnInstallDir""$cudaToolkitUnInstallScriptName"
        cudaSamplesDir="/Developer/NVIDIA/CUDA-""$cudaVersion""/samples/"
        if [ -d "$cudaSamplesDir" ]
        then
            cudaSamplesInstalled=true
        fi
        if [ -e "$cudaToolkitUnInstallScriptPath" ]
        then
            cudaToolkitInstalled=true
        fi
    fi
}

function checkCudaDriverInstall {
    cudaDriverInstalled=false
    cudaDriverVersion=""
    if [ -e "$cudaDriverFrameworkPath" ] || [ -e "$cudaDriverLaunchAgentPath" ] || [ -e "$cudaDriverPrefPanePath" ] || [ -e "$cudaDriverKextPath" ]
    then
        cudaDriverVersion=$("$pbuddy" -c "Print CFBundleVersion" "$cudaDriverVersionPath")
        cudaDriverInstalled=true
    fi
}

function checkCudaInstall {
    checkCudaInstallReset
    if [ -e "$cudaDeveloperDir" ]
    then
        versionPathTemp=`find "$cudaDeveloperDir" -iname "version.txt" -maxdepth 2`
        if [ `echo "$versionPathTemp" | wc -l | xargs` != 0 ]
        then
            cudaVersionPath=`echo "$versionPathTemp" | sed -n 1p`
            cudaVersionInstalled=true
            readCudaDeveloperVersion
        fi
    fi
    if [ -d "$cudaDeveloperDir" ]
    then
        readCudaToolkitVersions
        refineCudaToolkitInstallationStatus
    fi
    if [ -e "$cudaDeveloperDriverUnInstallScriptPath" ]
    then
        cudaDeveloperDriverInstalled=true
    fi
    checkCudaDriverInstall
}




##  Subroutine D3: Uninstaller
function uninstallCudaDriver {
    elevatePrivileges
    fileDumpTemp=`cat <<EOF
/usr/local/bin/.cuda_driver_uninstall_manifest_do_not_delete.txt
/Library/Frameworks/CUDA.framework
/Library/PreferencePanes/CUDA Preferences.prefPane
/Library/LaunchDaemons/com.nvidia.cuda.launcher.plist
/Library/LaunchDaemons/com.nvidia.cudad.plist
/usr/local/bin/uninstall_cuda_drv.pl
/usr/local/cuda/lib/libcuda.dylib
/Library/Extensions/CUDA.kext
/Library/LaunchAgents/com.nvidia.CUDASoftwareUpdate.plist
/usr/local/cuda
EOF
`
    genericUninstaller "$fileDumpTemp"
    if [ "$?" == 0 ]
    then
        doneSomething=true
        scheduleReboot=true
        checkCudaDriverInstall
    fi
}

function uninstallCudaResidue {
    elevatePrivileges
    fileDumpTemp=`cat <<EOF
/Developer/NVIDIA/
/usr/local/cuda
EOF
`
    genericUninstaller "$fileDumpTemp"
    if [ "$?" == 0 ]
    then
        doneSomething=true
        scheduleReboot=true
    fi
}

function uninstallCudaDeveloperDriver {
    if [ -e "$cudaDeveloperDriverUnInstallScriptPath" ]
    then
        elevatePrivileges
        sudo perl "$cudaDeveloperDriverUnInstallScriptPath" --silent &>/dev/null
        doneSomething=true
    fi
}

function uninstallCudaToolkit {
    if [ -e "$cudaToolkitUnInstallScriptPath" ]
    then
        elevatePrivileges
        sudo perl "$cudaToolkitUnInstallScriptPath" --silent &>/dev/null
        doneSomething=true
    fi
}

function uninstallCudaSamples {
    if [ -e "$cudaSamplesDir" ] && [ -e "$cudaToolkitUnInstallScriptPath" ]
    then
        elevatePrivileges
        sudo perl "$cudaToolkitUnInstallScriptPath" --manifest="$cudaToolkitUnInstallDir"".cuda_samples_uninstall_manifest_do_not_delete.txt" --silent &>/dev/null
        doneSomething=true
    fi
}

function uninstallCudaVersions {
    while read -r versionTemp
    do
        cudaVersion="$versionTemp"
        cudaToolkitUnInstallDir="/Developer/NVIDIA/CUDA-""$cudaVersion""/bin/"
        cudaToolkitUnInstallScriptName="uninstall_cuda_""$cudaVersion"".pl"
        cudaToolkitUnInstallScriptPath="$cudaToolkitUnInstallDir""$cudaToolkitUnInstallScriptName"
        uninstallCudaToolkit
    done <<< "$cudaVersionsInstalledList"
    uninstallCudaDeveloperDriver
    uninstallCudaDriver
    uninstallCudaResidue
}

function uninstallCuda {
    elevatePrivileges
    if [[ "$cudaVersions" > 1 ]]
    then
        uninstallCudaVersions
    else
        if [ `dc -e "$cudaRoutine 8192 / 2 % n"` == 1 ]
        then
            uninstallCudaSamples
        fi
        if [ `dc -e "$cudaRoutine 512 / 2 % n"` == 1 ]
        then
            uninstallCudaToolkit
            uninstallCudaResidue
        fi
        if [ `dc -e "$cudaRoutine 2 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 32 / 2 % n"` == 1 ]
        then
            uninstallCudaDeveloperDriver
            uninstallCudaDriver
        fi
    fi
}




##  Subroutine D4: Downloader
function downloadCudaDriverInformation {
    mktmpdir
    foundMatchCudaDriver=false
    if ( "$cudaLatest" && [ "${currentOS::5}" == "${os::5}" ] ) || "$forceNewest" && ( ! "$forceCudaDriverStable" )
    then
        cudaWebsiteLocalTemp="$dirName""/cudaWebsite.html"
        sudov curl -s -L "$cudaDriverWebsite" -m 1024 > "$cudaWebsiteLocalTemp"
        if [ "$?" == 0 ]
        then
            cudaDriverDownloadLink=$(cat "$cudaWebsiteLocalTemp" | grep -e download)
            cudaDriverDownloadLink="${cudaDriverDownloadLink##*http}"
            cudaDriverDownloadLink="${cudaDriverDownloadLink%%.dmg*}"
            cudaDriverDownloadLink="http""$cudaDriverDownloadLink"".dmg"
            cudaDriverDownloadVersion="${cudaDriverDownloadLink%_*}"
            cudaDriverDownloadVersion="${cudaDriverDownloadVersion##*_}"
            rm "$cudaWebsiteLocalTemp"
            foundMatchCudaDriver=true
        fi
    else
        cudaDriverListLocalTemp="$dirName""/cudaDriverList.plist"
        curl -s "$cudaDriverListOnline" -m 1024 > "$cudaDriverListLocalTemp"
        if [ "$?" == 0 ]
        then
            driversTemp=$("$pbuddy" -c "Print updates:" "$cudaDriverListLocalTemp" | grep "OS" | awk '{print $3}')
            driverCountTemp=$(echo "$driversTemp" | wc -l | xargs)
            for index in `seq 0 $(expr $driverCountTemp - 1)`
            do
                osTemp=$("$pbuddy" -c "Print updates:$index:OS" "$cudaDriverListLocalTemp")
                cudaDriverPathTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$cudaDriverListLocalTemp")
                cudaDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$cudaDriverListLocalTemp")

                if [ "${os::5}" == "$osTemp" ]
                then
                    cudaDriverDownloadLink="$cudaDriverPathTemp"
                    cudaDriverDownloadVersion="$cudaDriverVersionTemp"
                    foundMatchCudaDriver=true
                fi
            done
            rm "$cudaDriverListLocalTemp"
        fi
    fi
}

function downloadCudaDriverDownloadFallback {
    forceCudaDriverStable=true
    downloadCudaDriverInformation
    if "$foundMatchCudaDriver"
    then
        mktmpdir
        sudov curl -o "$dirName""/cudaDriver.dmg" "$cudaDriverDownloadLink" "-#" -m 1024
        hdiutil attach "$dirName""/cudaDriver.dmg" -quiet -nobrowse
        if [ "$?" == 1 ]
        then
            omitCuda=true
        fi
    else
        omitCuda=true
    fi
}

function downloadCudaDriver {
    if "$foundMatchCudaDriver"
    then
        mktmpdir
        sudov curl -o "$dirName""/cudaDriver.dmg" "$cudaDriverDownloadLink" "-#" -m 1024
        hdiutil attach "$dirName""/cudaDriver.dmg" -quiet -nobrowse
        if [ "$?" == 1 ]
        then
            echo "Download failed... Falling back to another download list..."
            downloadCudaDriverDownloadFallback
        fi
    else
        echo "macOS version match failed... Falling back to another download list..."
        downloadCudaDriverDownloadFallback
    fi
}

function downloadCudaToolkitInformation {
    mktmpdir
    foundMatchCudaToolkit=false
    if (( "$toolkitLatest" && [ "${currentOS::5}" == "${os::5}" ] ) || "$forceNewest" ) && ( ! "$forceCudaToolkitStable" )
    then
        cudaWebsiteLocalTemp="$dirName""/cudaWebsite.html"
        curl -s "$cudaToolkitWebsite" -m 1024 > "$cudaWebsiteLocalTemp"
        if [ "$?" == 0 ]
        then
            cudaToolkitDownloadLink=$(cat "$cudaWebsiteLocalTemp" | grep -e mac | grep -e local_installers)
            cudaToolkitDownloadLink="${cudaToolkitDownloadLink#*/compute/cuda/}"
            cudaToolkitDownloadLink="${cudaToolkitDownloadLink%%_mac*}"
            cudaToolkitDownloadLink="https://developer.nvidia.com/compute/cuda/""$cudaToolkitDownloadLink""_mac"
            cudaToolkitDownloadVersion="${cudaToolkitDownloadLink%_*}"
            cudaToolkitDownloadVersion="${cudaToolkitDownloadVersion##*_}"
            rm "$cudaWebsiteLocalTemp"
            foundMatchCudaToolkit=true
        fi
    else
        cudaToolkitListTemp="$dirName""/cudaToolkitList.plist"
        curl -s "$cudaToolkitListOnline" -m 1024 > "$cudaToolkitListTemp"
        if [ "$?" == 0 ]
        then
            driversTemp=$("$pbuddy" -c "Print updates:" "$cudaToolkitListTemp" | grep "OS" | awk '{print $3}')
            driverCountTemp=$(echo "$driversTemp" | wc -l | xargs)
            for index in `seq 0 $(expr $driverCountTemp - 1)`
            do
                osTemp=$("$pbuddy" -c "Print updates:$index:OS" "$cudaToolkitListTemp")
                cudaToolkitPathTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$cudaToolkitListTemp")
                cudaToolkitVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$cudaToolkitListTemp")
                cudaToolkitDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:driverVersion" "$cudaToolkitListTemp")
                if [ "${os::5}" == "$osTemp" ]
                then
                    cudaToolkitDownloadLink="$cudaToolkitPathTemp"
                    cudaToolkitDownloadVersion="$cudaToolkitVersionTemp"
                    cudaToolkitDriverDownloadVersion="$cudaToolkitDriverVersionTemp"
                    foundMatchCudaToolkit=true
                fi
            done
            rm "$cudaToolkitListTemp"
        fi
    fi
}

function downloadCudaToolkitDownloadFallback {
    forceCudaToolkitStable=true
    downloadCudaToolkitInformation
    if "$foundMatchCudaToolkit"
    then
        mktmpdir
        sudov curl -o "$dirName""/cudaToolkit.dmg" -L "$cudaToolkitDownloadLink" "-#" -m 2048
        hdiutil attach "$dirName""/cudaToolkit.dmg" -quiet -nobrowse
        if [ "$?" == 1 ]
        then
            omitCuda=true
        fi
    else
        omitCuda=true
    fi
}

function downloadCudaToolkit {
    if "$foundMatchCudaToolkit"
    then
        mktmpdir
        sudov curl -o "$dirName""/cudaToolkit.dmg" -L "$cudaToolkitDownloadLink" "-#" -m 2048
        hdiutil attach "$dirName""/cudaToolkit.dmg" -quiet -nobrowse
        if [ "$?" == 1 ]
        then
            echo "Download failed... Falling back to another download list..."
            downloadCudaToolkitDownloadFallback
        fi
    else
        echo "Download failed... Falling back to another download list..."
        downloadCudaToolkitDownloadFallback
    fi
}




##  Subroutine D5: Installer
function installCudaDriver {
    if [ -e "$cudaDriverVolPath""$cudaDriverPKGName" ]
    then
        elevatePrivileges
        sudo installer -pkg "$cudaDriverVolPath""$cudaDriverPKGName" -target / &>/dev/null
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
        hdiutil detach "$cudaDriverVolPath" -quiet
        sudov rm -rf "$dirName""/cudaDriver.dmg"
    fi
}

function installCudaToolkitBranch {
    if [ -e "$cudaToolkitVolPath""$cudaToolkitPKGName" ]
    then
        elevatePrivileges
        if [ `dc -e "$cudaRoutine 64 / 2 % n"` == 1 ]
        then
            sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-driver" &>/dev/null
            scheduleReboot=true
            doneSomething=true
            scheduleKextTouch=true
        fi
        if [ `dc -e "$cudaRoutine 1024 / 2 % n"` == 1 ]
        then
            sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-toolkit" &>/dev/null
            scheduleReboot=true
            doneSomething=true
            scheduleKextTouch=true
        fi
        if [ `dc -e "$cudaRoutine 16384 / 2 % n"` == 1 ]
        then
            sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-samples" &>/dev/null
            doneSomething=true
        fi
        hdiutil detach "$cudaToolkitVolPath" -quiet
        rm -rf "$dirName""/cudaToolkit.dmg"
    fi
}

function installCuda {
    if [ `dc -e "$cudaRoutine 64 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 1024 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 16384 / 2 % n"` == 1 ]
    then
        installCudaToolkitBranch
    fi
    checkCudaDriverInstall
    if [ `dc -e "$cudaRoutine 4 / 2 % n"` == 1 ] && [ "$cudaDriverVersion" != "$cudaDriverDownloadVersion" ]
    then
        installCudaDriver
    fi
}




##  Subroutine C6: Helper functions






#   Subroutine E: eGPU enabler NVIDIA macOS 10.13.X ##############################################################################################################
##  Subroutine E1: Global variables
nvidiaEGPUenabler1013Installed=false
nvidiaEGPUenabler1013BuildVersion=""

nvidiaEGPUenabler1013BuildVersionPath="/Library/Extensions/NVDAEGPUSupport.kext/Contents/Info.plist"

nvidiaEGPUenabler1013="/Library/Extensions/NVDAEGPUSupport.kext"

nvidiaEGPUenabler1013ListOnline="$gitPath""/Data/nvidiaEGPUenabler1013.plist"

nvidiaEGPUenabler1013DownloadPKGName=""
nvidiaEGPUenabler1013DownloadLink=""
nvidiaEGPUenabler1013DownloadChecksum=""

foundMatchNvidiaEGPUenabler1013=false

omitNvidiaEGPUenabler1013=false


##  Subroutine E2: Check functions
function checkNvidiaEGPUenabler1013InstallReset {
    nvidiaEGPUenabler1013Installed=false
    nvidiaEGPUenabler1013BuildVersion=""
}

function checkNvidiaEGPUenabler1013Install {
    checkNvidiaEGPUenabler1013InstallReset
    if [ -e "$nvidiaEGPUenabler1013" ]
    then
        nvidiaEGPUenabler1013Installed=true
        nvidiaEGPUenabler1013BuildVersion=$("$pbuddy" -c "Print IOKitPersonalities:NVDAStartup:NVDARequiredOS" "$nvidiaEGPUenabler1013BuildVersionPath")
    fi
}




##  Subroutine E3: Uninstaller
function uninstallNvidiaEGPUenabler1013 {
    if "$nvidiaEGPUenabler1013Installed"
    then
        elevatePrivileges
        sudo rm -rf "$nvidiaEGPUenabler1013"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine E4: Downloader
function downloadNvidiaEGPUenabler1013Information {
    mktmpdir
    nvidiaEGPUenabler1013ListTemp="$dirName""/eGPUenabler.plist"
    curl -s "$nvidiaEGPUenabler1013ListOnline" -m 1024 > "$nvidiaEGPUenabler1013ListTemp"
    if [ "$?" == 0 ]
    then
        enablersTemp=$("$pbuddy" -c "Print updates:" "$nvidiaEGPUenabler1013ListTemp" | grep "build" | awk '{print $3}')
        enablerCountTemp=$(echo "$enablersTemp" | wc -l | xargs)
        foundMatchNvidiaEGPUenabler1013=false
        for index in `seq 0 $(expr $enablerCountTemp - 1)`
        do
            buildTemp=$("$pbuddy" -c "Print updates:$index:build" "$nvidiaEGPUenabler1013ListTemp")
            nvidiaEGPUenabler1013ChecksumTemp=$("$pbuddy" -c "Print updates:$index:checksum" "$nvidiaEGPUenabler1013ListTemp")
            nvidiaEGPUenabler1013PKGNameTemp=$("$pbuddy" -c "Print updates:$index:packageName" "$nvidiaEGPUenabler1013ListTemp")
            nvidiaEGPUenabler1013DownloadLinkTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$nvidiaEGPUenabler1013ListTemp")
            if [ "$build" == "$buildTemp" ]
            then
                nvidiaEGPUenabler1013DownloadPKGName="$nvidiaEGPUenabler1013PKGNameTemp"
                nvidiaEGPUenabler1013DownloadLink="$nvidiaEGPUenabler1013DownloadLinkTemp"
                nvidiaEGPUenabler1013DownloadChecksum="$nvidiaEGPUenabler1013ChecksumTemp"
                foundMatchNvidiaEGPUenabler1013=true
            fi
        done
        rm "$nvidiaEGPUenabler1013ListTemp"
    fi
}

function downloadNvidiaEGPUenabler1013 {
    downloadNvidiaEGPUenabler1013Information
    if "$foundMatchNvidiaEGPUenabler1013"
    then
        mktmpdir
        curl -o "$dirName""/enabler.zip" "$nvidiaEGPUenabler1013DownloadLink" "-#" -m 1024
        nvidiaEGPUenabler1013ChecksumTemp=$(shasum -a 512 -b "$dirName""/enabler.zip" | awk '{ print $1 }')
        if [ "$nvidiaEGPUenabler1013DownloadChecksum" != "$nvidiaEGPUenabler1013ChecksumTemp" ]
        then
            omitNvidiaEGPUenabler1013=true
        else
            unzip -qq "$dirName""/enabler.zip" -d "$dirName""/"
        fi
        rm -rf "$dirName""/enabler.zip"
    else
        omitNvidiaEGPUenabler1013=true
    fi
}




##  Subroutine E5: Installer
function installNvidiaEGPUenabler1013 {
    if [ -e "$dirName""/""$nvidiaEGPUenabler1013DownloadPKGName" ]
    then
        elevatePrivileges
        sudo installer -pkg "$dirName""/""$nvidiaEGPUenabler1013DownloadPKGName" -target / &>/dev/null
        rm -f "$dirName""/""$nvidiaEGPUenabler1013DownloadPKGName"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine E6: Helper functions




#   Subroutine F: Thunderbolt 1/2 support - credit mayankk2308 @ GitHub / mac_editor @ eGPU.io; Please visit the GitHub repository to see all contributors. ##############################################################################################################
#   The subroutine F has been copied and adapted from "https://github.com/mayankk2308/purge-wrangler/raw/master/purge-wrangler.sh".
##  Subroutine F1: Global variables
#appleGraphicsControlPath="/System/Library/Extensions/AppleGraphicsControl.kext" - defined at Subroutine B: System checks
#appleGPUwranglerPath="$appleGraphicsControlPath""/Contents/PlugIns/AppleGPUWrangler.kext" - defined at Subroutine B: System checks
#appleGPUwranglerBinaryPath="$appleGPUwranglerPath""/Contents/MacOS/AppleGPUWrangler" - defined at Subroutine B: System checks

thunderbolt12UnlockSupportPath="/Library/Application Support/Purge-Wrangler"
thunderbolt12UnlockKextBackupPath="$thunderbolt12UnlockSupportPath""/Kexts"

thunderbolt12UnlockHexBookmark="494F5468756E646572626F6C74537769746368547970653"

thunderbolt12UnlockInstalled=false
thunderbolt12UnlockInstallStatus=0


##  Subroutine F2: Check functions
function checkThunderbolt12UnlockInstall {
    if [ -e "$appleGPUwranglerBinaryPath" ]
    then
        thunderbolt12UnlockInstallStatusTemp=`hexdump -ve '1/1 "%.2X"' "$appleGPUwranglerBinaryPath" | sed "s/.*""$thunderbolt12UnlockHexBookmark""//g"`
        thunderbolt12UnlockInstallStatus="${thunderbolt12UnlockInstallStatusTemp::1}"
        if [ "$thunderbolt12UnlockInstallStatus" != 3 ]
        then
            thunderbolt12UnlockInstalled=true
        fi
    fi
}




##  Subroutine F3: Uninstaller
function uninstallThunderbolt12Unlock {
    elevatePrivileges
    fetchThunderboltInterface
    checkThunderbolt12UnlockInstall
    inPlaceEditor "$thunderbolt12UnlockHexBookmark""$thunderbolt12UnlockInstallStatus" "$thunderbolt12UnlockHexBookmark""3" "$appleGPUwranglerBinaryPath"
    scheduleReboot=true
    doneSomething=true
    scheduleKextTouch=true
}




##  Subroutine F4: Downloader




##  Subroutine F5: Installer
function installThunderbolt12Unlock {
    elevatePrivileges
    fetchThunderboltInterface
    checkThunderbolt12UnlockInstall
    inPlaceEditor "$thunderbolt12UnlockHexBookmark""$thunderbolt12UnlockInstallStatus" "$thunderbolt12UnlockHexBookmark""$thunderboltInterface" "$appleGPUwranglerBinaryPath"
    scheduleReboot=true
    doneSomething=true
    scheduleKextTouch=true
}




##  Subroutine F6: Helper functions
function backupAppleGraphicsControl {
    if ! [ -d "$thunderbolt12UnlockSupportPath" ]
    then
        mkdir "$thunderbolt12UnlockSupportPath"
    fi
    sudo cp -R "$appleGraphicsControlPath"
}




#   Subroutine G: AMD Legacy Driver ##############################################################################################################
##  Subroutine G1: Global variables
amdLegacyDriversInstalled=false

amdLegacyDriverDownloadLink="https://egpu.io/wp-content/uploads/2018/04/automate-eGPU.kext_-1.zip"
amdLegacyDriverChecksum="2c93ef2e99423e0a1223d356772bd67d6083da69489fb3cf61dfbb69237eba1aaf453b7dc571cfe729e8b8bc1f92fcf29f675f60cd7dba9ec9b2723bac8f6bb7"

amdLegacyDriverKextPath="/Library/Extensions/automate-eGPU.kext"

omitAMDLegacyDriver=false




##  Subroutine G2: Check functions
function checkAMDLegacyDriverInstall {
    amdLegacyDriversInstalled=false
    if [ -e "$amdLegacyDriverKextPath" ]
    then
        amdLegacyDriversInstalled=true
    fi
}




##  Subroutine G3: Uninstaller
function uninstallAMDLegacyDriver {
    if [ -e "$amdLegacyDriverKextPath" ]
    then
        elevatePrivileges
        sudo rm -rf "$amdLegacyDriverKextPath"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine G4: Downloader
function downloadAMDLegacyDriver {
    mktmpdir
    curl -o "$dirName""/AMDLegacy.zip" "$amdLegacyDriverDownloadLink" "-#" -m 1024
    amdLegacyDriverChecksumTemp=$(shasum -a 512 -b "$dirName""/AMDLegacy.zip" | awk '{ print $1 }')
    if [ "$amdLegacyDriverChecksum" != "$amdLegacyDriverChecksumTemp" ]
    then
        omitAMDLegacyDriver=true
    else
        unzip -qq "$dirName""/AMDLegacy.zip" -d "$dirName""/"
    fi
    rm -rf "$dirName""/AMDLegacy.zip"
}




##  Subroutine G5: Installer
function installAMDLegacyDriver {
    if [ -e "$dirName""/automate-eGPU.kext" ]
    then
        elevatePrivileges
        sudo cp -r "$dirName""/automate-eGPU.kext" "$amdLegacyDriverKextPath"
        rm -rf "$dirName""/automate-eGPU.kext"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine G6: Helper functions




#   Subroutine H: T82 unblock ##############################################################################################################
##  Subroutine H1: Global variables
t82UnblockerDownloadLink="https://github.com/rgov/Thunderbolt3Unblocker/releases/download/v0.0.2/Thunderbolt3Unblocker.zip"
t82UnblockerChecksum="ce6b38f6c641f1a7866a57853a877126881f5f4b79d678a2952de585e48a23f6b20cae3fd4c177cedc17968c8042ca1f562953b6bf35360428799e3184c525b9"

t82UnblockerInstalled=false

t82UnblockerKextPath="/Library/Extensions/Thunderbolt3Unblocker.kext"

omitT82Unblocker=false




##  Subroutine H2: Check functions
function checkT82Unblocker {
    t82UnblockerInstalled=false
    if [ -e "$t82UnblockerKextPath" ]
    then
        t82UnblockerInstalled=true
    fi
}




##  Subroutine H3: Uninstaller
function uninstallT82Unblocker {
    if [ -e "$t82UnblockerKextPath" ]
    then
        elevatePrivileges
        sudo rm -R "$t82UnblockerKextPath"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine H4: Downloader
function downloadT82Unblocker {
    mktmpdir
    curl -o "$dirName""/tb82Unblock.zip" -L "$t82UnblockerDownloadLink" "-#" -m 1024
    t82UnblockerChecksumTemp=$(shasum -a 512 -b "$dirName""/tb82Unblock.zip" | awk '{ print $1 }')
    if [ "$t82UnblockerChecksumTemp" != "$t82UnblockerChecksum" ]
    then
        omitT82Unblocker=true
    else
        unzip -qq "$dirName""/tb82Unblock.zip" -d "$dirName""/"
    fi
    rm -rf "$dirName""/tb82Unblock.zip"
}




##  Subroutine H5: Installer
function installT82Unblocker {
    if [ -e "$dirName""/Thunderbolt3Unblocker.kext" ]
    then
        elevatePrivileges
        sudo cp -R "$dirName""/Thunderbolt3Unblocker.kext" "$t82UnblockerKextPath"
        rm -R "$dirName""/Thunderbolt3Unblocker.kext"
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine H6: Helper functions




#   Subroutine I: NVIDIA dGPU deactivator ##############################################################################################################
##  Subroutine I1: Global variables
nvidiaDGPUdeactivatorBackupPath="/Library/Application Support/Purge-NVDA"

nvidiaDGPUdeactivatorInstalled=false

omitNvidiaDGPUdeactivator=false




##  Subroutine I2: Check functions
function checkNvidiaDGPUdeactivator {
    nvidiaDGPUdeactivatorInstalled=false
    if [ -d "$nvidiaDGPUdeactivatorBackupPath" ]
    then
        nvidiaDGPUdeactivatorInstalled=true
    fi
}




##  Subroutine I3: Uninstaller
function uninstallNvidiaDGPUdeactivator {
    elevatePrivileges
    sudo nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs
    sudo nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active
    sudo nvram boot-args=""
}




##  Subroutine I4: Downloader




##  Subroutine I5: Installer
function installNvidiaDGPUdeactivator {
    elevatePrivileges
    sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs=%01%00%00%00
    sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active=%01%00%00%00
    sudo nvram boot-args="nv_disable=1"
}




##  Subroutine I6: Helper functions




#   Subroutine J: macOS 10.13.4/.5 wrangler patch ##############################################################################################################
##  Subroutine J1: Global variables
nvidiaUnlockWranglerPatchHexBookmark="4989C7498B3C24E81DBDFFFF41F7C50000000"

nvidiaUnlockWranglerPatchInstalled=false
nvidiaUnlockWranglerPatchInstallStatus=0




##  Subroutine J2: Check functions
function checkNvidiaUnlockWranglerPatchInstall {
    fetchAppleGPUWranglerVersion
if [ -e "$appleGPUwranglerBinaryPath" ] && ( [[ "$appleGPUWranglerVersion" =~ "10.13.4" ]] || [[ "$appleGPUWranglerVersion" =~ "10.13.5" ]] )
    then
        nvidiaUnlockWranglerPatchInstallStatusTemp=`hexdump -ve '1/1 "%.2X"' "$appleGPUwranglerBinaryPath" | sed "s/.*""$nvidiaUnlockWranglerPatchHexBookmark""//g"`
        nvidiaUnlockWranglerPatchInstallStatus="${nvidiaUnlockWranglerPatchInstallStatusTemp::1}"
        if [ "$nvidiaUnlockWranglerPatchInstallStatus" != 1 ]
        then
            nvidiaUnlockWranglerPatchInstalled=true
        fi
    fi
}




##  Subroutine J3: Uninstaller
function uninstallNvidiaUnlockWranglerPatch {
    checkNvidiaUnlockWranglerPatchInstall
    elevatePrivileges
    inPlaceEditor "$nvidiaUnlockWranglerPatchHexBookmark""$nvidiaUnlockWranglerPatchInstallStatus" "$nvidiaUnlockWranglerPatchHexBookmark""1" "$appleGPUwranglerBinaryPath"
    scheduleReboot=true
    doneSomething=true
    scheduleKextTouch=true
}




##  Subroutine J4: Downloader




##  Subroutine J5: Installer
function installNvidiaUnlockWranglerPatch {
    checkNvidiaUnlockWranglerPatchInstall
    elevatePrivileges
    inPlaceEditor "$nvidiaUnlockWranglerPatchHexBookmark""$nvidiaUnlockWranglerPatchInstallStatus" "$nvidiaUnlockWranglerPatchHexBookmark""0" "$appleGPUwranglerBinaryPath"
    scheduleReboot=true
    doneSomething=true
    scheduleKextTouch=true
}




##  Subroutine J6: Helper functions




#   Subroutine K: Thunderbolt daemon ##############################################################################################################
##  Subroutine K1: Global variables
thunderboltDaemonInstalled=false
macOSeGPUdaemonPlistPath="/Library/LaunchDaemons/scp.learex.daemon-macOS-eGPU.plist"
macOSeGPUDaemonPath="/usr/local/bin/daemon-macOS-eGPU"




##  Subroutine K2: Check functions
function checkThunderboltDaemonInstall {
    thunderboltDaemonInstalled=false
    if [ -e "$macOSeGPUdaemonPlistPath" ]
    then
        thunderboltDaemonInstalled=true
    fi
}




##  Subroutine K3: Uninstaller
function uninstallThunderboltDaemon {
    if [ -e "$macOSeGPUdaemonPlistPath" ]
    then
        elevatePrivileges
        sudo rm "$macOSeGPUdaemonPlistPath"
    fi
    if [ -e "$macOSeGPUDaemonPath" ]
    then
        elevatePrivileges
        sudo rm "$macOSeGPUDaemonPath"
    fi
}

##  Subroutine K5: Installer
function installThunderboltDaemon {
    elevatePrivileges
    plistGenerateTemp=`cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>daemon-macOS-eGPU</string>
    <key>KeepAlive</key>
    <false/>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>$macOSeGPUDaemonPath</string>
        <string>--launchDaemon</string>
    </array>
</dict>
</plist>
EOF
`
    launchDaemonGenerateTemp=`cat <<"EOF"
#!/bin/bash
#   macOS eGPU launch deamon

args="$@"

function daemon {
    if [ "$args" == "--launchDaemon" ]
    then
        sudo nvram tbt-options="<00>"
    fi
}

daemon
EOF
`

    echo "$launchDaemonGenerateTemp" | sudo tee "$macOSeGPUDaemonPath" &>/dev/null
    sudo chown "$SUDO_USER" "$macOSeGPUDaemonPath"
    sudo chmod 755 "$macOSeGPUDaemonPath"
    echo "$plistGenerateTemp" | sudo tee "$macOSeGPUdaemonPlistPath" &>/dev/null
    sudo chown root:wheel "$macOSeGPUdaemonPlistPath"
    sudo launchctl load -F "$macOSeGPUdaemonPlistPath" &>/dev/null
}




#   Subroutine L: New IOPCITunnelled Patch 10.13.6+ ##############################################################################################################
##  Subroutine L1: Global variables
ioGraphicsFamilyBinaryPath="/System/Library/Extensions/IOGraphicsFamily.kext/IOGraphicsFamily"
iondrvPlistPath="/System/Library/Extensions/IONDRVSupport.kext/Info.plist"
nvidiaDriverPlistPath="$nvidiaDriverVersionPath"


iopciTunnelledPatchHexBookmark="494F50434954756E6E656C6C65"
iopciTunnelledPatchHexBookmarkOld="494F50434954756E6E656C6C6564"
iopciTunnelledPatchHexBookmarkNew="494F50434954756E6E656C6C6571"

iopciTunnelledPatchInstalled=false
iopciTunnelledPatchInstallStatus1=0
iopciTunnelledPatchInstallStatus2=0

##  Subroutine L2: Check functions
function checkIopciTunnelledPatchInstall {
    fetchAppleGPUWranglerVersion
    if [ -e "$appleGPUwranglerBinaryPath" ] && [ -e "$ioGraphicsFamilyBinaryPath" ]  && ( [[ "$appleGPUWranglerVersion" =~ "10.13.6" ]] || ( [ "$appleGPUWranglerVersion" == "" ] && "$beta" ) )
    then
        iopciTunnelledPatchInstallStatusTemp=`hexdump -ve '1/1 "%.2X"' "$appleGPUwranglerBinaryPath" | sed "s/.*""$iopciTunnelledPatchHexBookmark""//g"`
        iopciTunnelledPatchInstallStatus1="${iopciTunnelledPatchInstallStatusTemp::2}"
        iopciTunnelledPatchInstallStatusTemp=`hexdump -ve '1/1 "%.2X"' "$ioGraphicsFamilyBinaryPath" | sed "s/.*""$iopciTunnelledPatchHexBookmark""//g"`
        iopciTunnelledPatchInstallStatus2="${iopciTunnelledPatchInstallStatusTemp::2}"
        if [ "$iopciTunnelledPatchInstallStatus1" != "64" ] && [ "$iopciTunnelledPatchInstallStatus2" != "64" ]
        then
            iopciTunnelledPatchInstalled=true
        elif ( [ "$iopciTunnelledPatchInstallStatus1" == "64" ] && [ "$iopciTunnelledPatchInstallStatus2" != "64" ] ) || ( [ "$iopciTunnelledPatchInstallStatus1" != "64" ] && [ "$iopciTunnelledPatchInstallStatus2" == "64" ] )
        then
            echo
            echo
            uninstallIopciTunnelledPatch
            iopciTunnelledPatchInstalled=false
        else
            iopciTunnelledPatchInstalled=false
        fi
    fi
}




##  Subroutine L3: Uninstaller
function uninstallIopciTunnelledPatch {
    checkIopciTunnelledPatchInstall
    elevatePrivileges
    if [ -e "$appleGPUwranglerBinaryPath" ]
    then
        inPlaceEditor "$iopciTunnelledPatchHexBookmark""$iopciTunnelledPatchInstallStatus1" "$iopciTunnelledPatchHexBookmarkOld" "$appleGPUwranglerBinaryPath"
    fi
    if [ -e "$ioGraphicsFamilyBinaryPath" ]
    then
        inPlaceEditor "$iopciTunnelledPatchHexBookmark""$iopciTunnelledPatchInstallStatus2" "$iopciTunnelledPatchHexBookmarkOld" "$ioGraphicsFamilyBinaryPath"
    fi
    if [ -e "$iondrvPlistPath" ]
    then
        sudo "$pbuddy" -c "Set :IOKitPersonalities:3:IOPCITunnelCompatible false" "$iondrvPlistPath" &>/dev/null
        if [ "$?" == 1 ]
        then
            sudo "$pbuddy" -c "Add :IOKitPersonalities:3:IOPCITunnelCompatible bool false" "$iondrvPlistPath" &>/dev/null
        fi
    fi
    if [ -e "$nvidiaDriverPlistPath" ]
    then
        sudo "$pbuddy" -c "Set :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible false" "$nvidiaDriverPlistPath" &>/dev/null
        if [ "$?" == 1 ]
        then
            sudo "$pbuddy" -c "Add :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool false" "$nvidiaDriverPlistPath" &>/dev/null
        fi
    fi
    scheduleReboot=true
    doneSomething=true
    scheduleKextTouch=true
}




##  Subroutine L4: Downloader




##  Subroutine L5: Installer
function installIopciTunnelledPatch {
    checkIopciTunnelledPatchInstall
    elevatePrivileges
    if "$debug"
    then
        echo
        if [ -e "$appleGPUwranglerBinaryPath" ]
        then
            echo "yes"
        else
            echo "no"
        fi
        if [ -e "$ioGraphicsFamilyBinaryPath" ]
        then
            echo "yes"
        else
            echo "no"
        fi
        if [ -e "$iondrvPlistPath" ]
        then
            echo "yes"
        else
            echo "no"
        fi
        if [ -e "$nvidiaDriverPlistPath" ]
        then
            echo "yes"
        else
            echo "no"
        fi
        echo "$appleGPUWranglerVersion"
    fi
    if [ -e "$appleGPUwranglerBinaryPath" ] && [ -e "$ioGraphicsFamilyBinaryPath" ] && [ -e "$iondrvPlistPath" ] && [ -e "$nvidiaDriverPlistPath" ] && ( [[ "$appleGPUWranglerVersion" =~ "10.13.6" ]] || ( [ "$appleGPUWranglerVersion" == "" ] && "$beta" ) )
    then
        trapLock
        inPlaceEditor "$iopciTunnelledPatchHexBookmark""$iopciTunnelledPatchInstallStatus1" "$iopciTunnelledPatchHexBookmarkNew" "$appleGPUwranglerBinaryPath"
        inPlaceEditor "$iopciTunnelledPatchHexBookmark""$iopciTunnelledPatchInstallStatus2" "$iopciTunnelledPatchHexBookmarkNew" "$ioGraphicsFamilyBinaryPath"
        sudo "$pbuddy" -c "Set :IOKitPersonalities:3:IOPCITunnelCompatible true" "$iondrvPlistPath" &>/dev/null
        if [ "$?" == 1 ]
        then
            sudo "$pbuddy" -c "Add :IOKitPersonalities:3:IOPCITunnelCompatible bool true" "$iondrvPlistPath" &>/dev/null
        fi
        sudo "$pbuddy" -c "Set :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible true" "$nvidiaDriverPlistPath" &>/dev/null
        if [ "$?" == 1 ]
        then
            sudo "$pbuddy" -c "Add :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool true" "$nvidiaDriverPlistPath" &>/dev/null
        fi
        trapWithWarning
        scheduleReboot=true
        doneSomething=true
        scheduleKextTouch=true
    fi
}




##  Subroutine L6: Helper functions



##fn
#   Subroutine M: CUDA drivers ##############################################################################################################
##  Subroutine M1: Global variables
##  Subroutine M2: Check functions
##  Subroutine M3: Uninstaller
##  Subroutine M4: Downloader
##  Subroutine M5: Installer
##  Subroutine M6: Helper functions


#   Subroutine X: Option parsing ##############################################################################################################
##fn
install=false
uninstall=false
check=false
nvidiaDriver=false
amdLegacyDriver=false
reinstall=false
#forceNewest=false - defined at Subroutine C: NVIDIA drivers
nvidiaEnabler=false
thunderbolt12Unlock=false
thunderboltDaemon=false
t82Unblocker=false
unlockNvidia=false
iopcieTunnelPatch=false
deactivateNvidiaDGPU=false
fullInstall=false
#noReboot=false - defined at Subroutine A: Basic functions
#customNvidiaDriver=false - defined at Subroutine C: NVIDIA drivers
help=false
acceptLicense=false
skipWarnings=false
fullCheck=false
forceCacheRebuild=false
beta=false

argumentsGiven=false

##fn
scriptParameterList=""
lastParam=""
for options in "$@"
do
    scriptParameterList="$scriptParameterList"" ""$options"
    case "$options"
    in
    "--install" | "-i")
        if "$uninstall" || "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        install=true
        ;;
    "--uninstall" | "-U")
        if "$install" || "$check" || "$forceNewest" || "$reinstall" || "$fullInstall" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        uninstall=true
        ;;
    "--checkSystem" | "-C")
        if "$install" || "$uninstall" || "$nvidiaDriver" || "$amdLegacyDriver" || "$reinstall" || "$forceNewest" || "$nvidiaEnabler" || "$thunderbolt12Unlock" || "$t82Unblocker" || "$unlockNvidia" || [ "$scheduleCudaDeduction" != 0 ] || "$fullInstall" || "$fullCheck" || "$thunderboltDaemon" || "$forceCacheRebuild" || "$iopcieTunnelPatch"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        check=true
        ;;
    "--checkSystemFull")
        if "$install" || "$uninstall" || "$nvidiaDriver" || "$amdLegacyDriver" || "$reinstall" || "$forceNewest" || "$nvidiaEnabler" || "$thunderbolt12Unlock" || "$t82Unblocker" || "$unlockNvidia" || [ "$scheduleCudaDeduction" != 0 ] || "$fullInstall" || "$check" || "$thunderboltDaemon" || "$forceCacheRebuild" || "$iopcieTunnelPatch"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        fullCheck=true
        check=true
        ;;
    "--nvidiaDriver" | "-n")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        nvidiaDriver=true
        ;;
    "--amdLegacyDriver" | "-a")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        amdLegacyDriver=true
        ;;
    "--forceReinstall" | "-R")
        if "$uninstall" || "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        reinstall=true
        ;;
    "--forceNewest" | "-f")
        if "$uninstall" || "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        forceNewest=true
        ;;
    "--nvidiaEGPUsupport" | "-e")
        if "$check" || "$forceCacheRebuild" || "$iopcieTunnelPatch"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        nvidiaEnabler=true
        ;;
    "--deactivateNvidiaDGPU" | "-d")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        deactivateNvidiaDGPU=true
        ;;
    "--unlockThunderboltV12" | "-V")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        thunderbolt12Unlock=true
        ;;
    "--unlockT82" | "-T")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        t82Unblocker=true
        ;;
    "--unlockNvidia" | "-N")
        if "$check" || "$forceCacheRebuild" || "$iopcieTunnelPatch"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        unlockNvidia=true
        ;;
    "-iopcieTunneledPatch" | "-l")
        if "$check" || "$forceCacheRebuild" || "$nvidiaEnabler" || "$unlockNvidia"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        iopcieTunnelPatch=true
        ;;
   "--thunderboltDaemon" | "-E")
        if "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        thunderboltDaemon=true
        ;;
    "--cudaDriver" | "-c")
        if [ "$scheduleCudaDeduction" != 0 ] || "$check" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
        ;;
    "--cudaDeveloperDriver" | "-D")
        if [ "$scheduleCudaDeduction" != 0 ] || "$check"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
        ;;
    "--cudaToolkit" | "-t")
        if [ "$scheduleCudaDeduction" != 0 ] || "$check"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
        ;;
    "--cudaSamples" | "-s")
        if [ "$scheduleCudaDeduction" != 0 ] || "$check"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
        ;;
    "--full" | "-F")
        if "$check" || "$uninstall" || "$forceCacheRebuild"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        fullInstall=true
        ;;
    "--noReboot" | "-r")
        noReboot=true
        ;;
    "--acceptLicenseTerms" | "--acceptLicense")
        acceptLicense=true
        ;;
    "--skipWarnings" | "-k")
        skipWarnings=true
        ;;
    "--beta")
        beta=true
        ;;
    "--forceCacheRebuild" | "-h")
        if "$install" || "$uninstall" || "$nvidiaDriver" || "$amdLegacyDriver" || "$reinstall" || "$forceNewest" || "$nvidiaEnabler" || "$thunderbolt12Unlock" || "$t82Unblocker" || "$unlockNvidia" || [ "$scheduleCudaDeduction" != 0 ] || "$fullInstall" || "$check" || "$thunderboltDaemon" || "$forceCacheRebuild" || "$iopcieTunnelPatch"
        then
            echo "ERROR: Conflicting arguments with ""$options"
            irupt
        fi
        forceCacheRebuild=true
        ;;
    "--help" | "-h" | "-?" | "?" | "help")
        help=true
        ;;
    *)
        case "$lastParam"
        in
        "--nvidiaDriver" | "-n")
            if "$forceNewest"
            then
                echo "ERROR: Conflicting arguments with ""$options"" [revision]"
                irupt
            fi
            customNvidiaDriver=true
            nvidiaDriverDownloadVersion="$options"
            ;;
        *)
            echo "unrecognized parameter: ""$options"
            printShortHelp
            irupt
            ;;
        esac
    esac
    argumentsGiven=true
    lastParam="$options"
done

if [ -e "/usr/local/bin/macos-egpu" ]
then
    skipWarnings=true
    acceptLicense=true
fi

if "$debug"
then
    echo "Parameters:"
    echo "$scriptParameterList"
fi


#   Subroutine Y: Script execution algorithm ##############################################################################################################
##  Subroutine Y1: Global variables
attachedDMGVolumes="$(echo -e -n $attachedDMGVolumes)"

#scheduleReboot=false - defined at Subroutine A: Basic functions
#doneSomething=false - defined at Subroutine A: Basic functions
scheduleKextTouch=false

determine=false
setStandard=false

scheduleSecureEGPUfetch=false

sipRequirement=127

##fn
nvidiaDriverRoutine=0
nvidiaEnablerRoutine=0
unlockNvidiaRoutine=0
amdLegacyDriverRoutine=0
t82UnblockerRoutine=0
deactivateNVIDIAdGPURoutine=0
thunderbolt12UnlockRoutine=0
thunderboltDaemonRoutine=0
iopcieTunnelPatchRoutine=0



##  Subroutine Y2: Print functions
function printHeader {
    echo "macOS-eGPU.sh (""$scriptVersion"")"
    echo
}

function askLicenseQuestion {
    if ! "$acceptLicense" && ! "$debug"
    then
        printLicense
        echo
        echo "Do you agree with the license terms of the script and wish to continue?"
        read -p "[y]es [n]o : " -r -n 1
        echo
        if  [ "$REPLY" != "y" ]
        then
            echo
            echo "Continuation requires acceptance of the license terms."
            createSpace 4
            irupt
        fi
    fi
}

function printWarnings {
    if ! "$skipWarnings" && ! "$debug"
    then
        echo "The script will now close (kill) all programs."
        echo "Please abort the script now should you wish to do it manually and save your work."
        echo "Please do not, under any circumstances abort the script later during the execution."
        echo "This might break your system."
        echo ""
        if ! "$noReboot"
        then
            echo "The script might automatically reboot the system after successful execution."
        fi
        fetchOSinfo
        if [ "$os" == "$warningOS" ]
        then
            echo "This script is not designed to work with your current version of macOS."
            echo "Continuation might result in failure and/or system crash."
        fi
        echo "To safely abort the script now, press ^C."
        echo "Continuing in"
        trapWithoutWarning
        if ! "$debug"
        then
            waiter 15
        fi
        trapWithWarning
    fi
}




##  Subroutine Y3: System properties enforcer
function enforceEGPUdisconnect {
    fetchConnectedEGPU
    if ! "$debug"
    then
        if [ "$?" == 1 ]
        then
            echo
            echo "Please disconnect all thunderbolt devices. Should this problem persist, please file an issue."
            irupt
        fi
        if "$connectedEGPU"
        then
            echo
            echo "Please disconnect your eGPU. The script does not allow installations with a connected eGPU."
            irupt
        fi
    fi
}




##  Subroutine Y4: Preparations
function preparations {
    trapWithoutWarning
    if ! "$acceptLicense"
    then
        createSpace 3
        printHeader
        askLicenseQuestion
    fi
    if ! "$skipWarnings"
    then
        createSpace 3
        printWarnings
    fi

    createSpace 5
    printHeader
    echoing "Accept license terms..."
    echoend "done"
    echoing "Killing all other running programs..."
    quitAllApps
    if [ "$?" != 0 ]
    then
        echoend "FAILURE" 1
        irupt
    fi
    echoend "OK" 2
    echoing "Internet connection established..."
    checkInternetConnection
    if "$internet"
    then
        echoend "YES" 2
    else
        echoend "NO" 1
    fi
}




##  Subroutine Y5: Get system info
##fn
function gatherSystemInfo {
    echoing "   macOS info"
    fetchOSinfo
    echoend "done"

    echoing "   system integrity protection"
    fetchSIPstat
    echoend "done"

    echoing "   thunderbolt version"
    fetchThunderboltInterface
    echoend "done"

    echoing "   GPU information"
    fetchConnectedEGPU
    fetchNvidiaDGPU
    fetchAppleGPUWranglerVersion
    echoend "done"

    echoing "   installed eGPU software"
    checkNvidiaDriverInstall
    checkCudaInstall
    checkNvidiaEGPUenabler1013Install
    echoend "done"

    echoing "   installed patches"
    checkThunderbolt12UnlockInstall
    checkAMDLegacyDriverInstall
    checkT82Unblocker
    checkNvidiaDGPUdeactivator
    checkNvidiaUnlockWranglerPatchInstall
    checkThunderboltDaemonInstall
    checkIopciTunnelledPatchInstall
    echoend "done"

    echoing "   installed programs"
    fetchInstalledPrograms
    echoend "done"
}




##  Subroutine Y6: Deductions and Parsing
###  Subroutine Y6'1: Automated eGPU information fetching
function moveDriversToBackup {
    mktmpdir
    geforceKextTemp="/Library/Extensions/GeForceWeb.kext"
    nvdaStartupKextTemp="/Library/Extensions/NVDAStartupWeb.kext"
    nvdaEGPUKextTemp="/Library/Extensions/NVDAEGPUSupport.kext"
    geforceKextBackupTemp="$dirName""/GeForceWeb.kext"
    nvdaStartupKextBackupTemp="$dirName""/NVDAStartupWeb.kext"
    nvdaEGPUKextBackupTemp="$dirName""/NVDAEGPUSupport.kext"
    if [ -e "$geforceKextTemp" ]
    then
        sudo cp -R "$geforceKextTemp" "$geforceKextBackupTemp"
        sudo rm -R "$geforceKextTemp"
    fi
    if [ -e "$nvdaStartupKextTemp" ]
    then
        sudo cp -R "$nvdaStartupKextTemp" "$nvdaStartupKextBackupTemp"
        sudo rm -R "$nvdaStartupKextTemp"
    fi
    if [ -e "$nvdaEGPUKextTemp" ]
    then
        sudo cp -R "$nvdaEGPUKextTemp" "$nvdaEGPUKextBackupTemp"
        sudo rm -R "$nvdaEGPUKextTemp"
    fi
}

function moveDriverFromBackup {
    mktmpdir
    geforceKextTemp="/Library/Extensions/GeForceWeb.kext"
    nvdaStartupKextTemp="/Library/Extensions/NVDAStartupWeb.kext"
    nvdaEGPUKextTemp="/Library/Extensions/NVDAEGPUSupport.kext"
    geforceKextBackupTemp="$dirName""/GeForceWeb.kext"
    nvdaStartupKextBackupTemp="$dirName""/NVDAStartupWeb.kext"
    nvdaEGPUKextBackupTemp="$dirName""/NVDAEGPUSupport.kext"
    if [ -e "$geforceKextBackupTemp" ]
    then
        sudo cp -R "$geforceKextBackupTemp" "$geforceKextTemp"
        sudo rm -R "$geforceKextBackupTemp"
    fi
    if [ -e "$nvdaStartupKextBackupTemp" ]
    then
        sudo cp -R "$nvdaStartupKextBackupTemp" "$nvdaStartupKextTemp"
        sudo rm -R "$nvdaStartupKextBackupTemp"
    fi
    if [ -e "$nvdaEGPUKextBackupTemp" ]
    then
        sudo cp -R "$nvdaEGPUKextBackupTemp" "$nvdaEGPUKextTemp"
        sudo rm -R "$nvdaEGPUKextBackupTemp"
    fi
}

function manualGetEGPUInformation {
        echo "   please select your eGPU brand:"
        echo "    [1]: NVIDIA"
        echo "    [2]: AMD"
        read -p "Number: " -r -n 1
        echo
        case "$REPLY"
        in
        "1")
            nvidiaEnabler=true
            nvidiaDriver=true
            unlockNvidia=true
            iopcieTunnelPatch=true
            ;;
        "2")
            amdLegacyDriver=true
            deactivateNvidiaDGPU=true
            ;;
        *)
            echo
            echo "ERROR: Unrecoginzed answer"
            irupt
            ;;
        esac
        echo "Do you use an 'unsupported' eGPU enclosure (T82 chip)"
        echo "Most eGPU enclosures are supported. If you don't know the answer"
        echo "abort and read the documentation for more information."
        echo "   please select your answer:"
        echo "    [1]: YES"
        echo "    [2]: no"
        read -p "Number: " -r -n 1
        echo
        case "$REPLY"
        in
        "1")
            t82Unblocker=true
            ;;
        "2")
            t82Unblocker=false
            ;;
        *)
            echo
            echo "ERROR: Unrecoginzed answer"
            irupt
            ;;
        esac
}

function secureGetEGPUInformation {
    echoing "   locking script execution"
    trapLock
    echoend "done"
    enforceEGPUdisconnect

    elevatePrivileges
    echoing "   preparing secure eGPU connection"
    moveDriversToBackup
    sudo touch /System/Library/Extensions &>/dev/null
    sudo kextcache -q -update-volume / &>/dev/null
    sudo touch /System/Library/Extensions &>/dev/null
    sudo kextcache -system-caches &>/dev/null
    echoend "done"
    echo "   waiting 20 seconds for user to connect eGPU"
    echo -n "   "
    waiter 20
    sudo -v
    echoing "   fetching eGPU information"
    unsupportedCheckTemp=`system_profiler SPThunderboltDataType`
    pciTemp=`system_profiler SPPCIDataType`
    if [[ "$unsupportedCheckTemp[@]" =~ "Unsupported" ]]
    then
        t82Unblocker=true
        echoend "done"
        return 0
    else
        fetchConnectedEGPU
    fi
    echoend "done"
    if ! "$connectedEGPU"
    then
        echo
        moveDriverFromBackup
        echo "--- Automatic eGPU information fetching has failed ---"
        echo "Proceeding with manual eGPU information fetching..."
        manualGetEGPUInformation
    else
        echoing "   preparing secure eGPU disconnection"
        SafeEjectGPU Eject &>/dev/null
        echoend "done"
        echo "   waiting 20 seconds for user to disconnect eGPU"
        echo -n "   "
        waiter 20
        sudo -v
        connectedEGPUTemp="$connectedEGPU"
        connectedEGPUVendorTemp="$connectedEGPUVendor"
        fetchConnectedEGPU
        moveDriverFromBackup
        if "$connectedEGPU"
        then
            echo
            echo "--- eGPU has not been disconnected ---"
            echo "Do not diconnect now!"
            echo "The script enters panic mode..."
            echo "Trying to halt in order to avoid a fatal kernel panic..."
            echo "Only disconnect the eGPU once the Mac has shut down."
            echo "Re-run the script afterwards."
            systemClean
            echo "The script has failed."
            sudo halt & &>/dev/null
            exit
        fi
        echoing "   stetting switches"
        connectedEGPU="$connectedEGPUTemp"
        connectedEGPUVendor="$connectedEGPUVendorTemp"
        if [ "$connectedEGPUVendor" == "NVIDIA" ]
        then
            nvidiaEnabler=true
            nvidiaDriver=true
            unlockNvidia=true
            iopcieTunnelPatch=true
        elif [ "$connectedEGPUVendor" == "AMD" ]
        then
            typesTemp=`echo "$pciTemp" | grep "Type"`
            usedSlotsTemp=`echo "$pciTemp" | grep "Slot"`
            countTemp=`echo "$typeTemp" | wc -l | xargs`
            countTemp2=`echo "$usedSlotsTemp" | wc -l | xargs`
            if [ "$countTemp" == "$countTemp2" ]
            then
                for i in `seq 1 "$countTemp"`
                do
                    typeTemp=`echo "$typesTemp" | sed -n "$i"p`
                    usedSlotTemp=`echo "$usedSlotsTemp" | sed -n "$i"p`
                    if [[ "$typeTemp" =~ "VGA" ]] || [[ "$typeTemp" =~ "Display" ]] || [[ "$typeTemp" =~ "gpu" ]] && [[ "$typeTemp" != *"Type: Display Controller" ]] && [[ "$usedSlotTemp" =~ "Thunderbolt" ]]
                    then
                        amdLegacyDriver=true
                        deactivateNvidiaDGPU=true
                    fi
                done
            else
                amdLegacyDriver=true
                deactivateNvidiaDGPU=true
            fi
        else
            echoend "FAILURE" 1
            irupt
        fi
        echoend "done"
    fi
    scheduleKextTouch=true
    echoing "   opening script execution lock"
    trapWithoutWarning
    echoend "done"
}




###  Subroutine Y6'2: CUDA requirements
function getCudaNeeds {
    if "$nvidiaDriversInstalled" || "$nvidiaDriver"
    then
        mktmpdir
        echoing "   fetching CUDA requiring apps list"
        cudaAppListTemp="$dirName""/cudaApp.plist"
        curl -s "$cudaAppListOnline" -m 1024 > "$cudaAppListTemp"
        echoend "done"
        echoing "   preparing matching"
        appsTemp=$("$pbuddy" -c "Print apps:" "$cudaAppListTemp" | grep "name" | awk '{print $3}')
        appCountTemp=$(echo "$appsTemp" | wc -l | xargs)
        echoend "done"
        echoing "   matching"
        for index in `seq 0 $(expr $appCountTemp - 1)`
        do
            appNameTemp=$("$pbuddy" -c "Print apps:$index:name" "$cudaAppListTemp")
            driverNeedsTemp=$("$pbuddy" -c "Print apps:$index:requirement" "$cudaAppListTemp")
            if [[ "$programList[@]" =~ $appNameTemp ]]
            then
                fullProgramNameTemp=$( echo "$programList" | grep "$appNameTemp" )
                case "$driverNeedsTemp"
                in
                "driver")
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                    ;;
                "developerDriver")
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    ;;
                "toolkit")
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                    ;;
                "samples")
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
                    ;;
                *)
                    ;;
                esac
            fi
        done
        sudov rm "$cudaAppListTemp"
        echoend "done"
    fi
}




###  Subroutine Y6'3: Basic requirement handler/scheduler
##fn
function setStandards {
    if ( ! "$install" ) && ( ! "$uninstall" ) && ( ! "$check" )
    then
        setStandard=true
        install=true
    fi
    if ( ! "$nvidiaDriver" ) && ( ! "$amdLegacyDriver" ) && ( ! "$nvidiaEnabler" ) && ( ! "$thunderbolt12Unlock" ) && ( ! "$t82Unblocker" ) && ( ! "$unlockNvidia" ) && ( ! "$deactivateNvidiaDGPU" ) && [ "$scheduleCudaDeduction" == 0 ] && ( ! "$thunderboltDaemon" ) && ( ! "$iopcieTunnelPatch" )
    then
        determine=true
    fi
    if "$determine"
    then
        if "$fullInstall"
        then
            if "$install"
            then
                nvidiaDriver=true
                amdLegacyDriver=true
                nvidiaEnabler=true
                thunderbolt12Unlock=true
                t82Unblocker=true
                unlockNvidia=true
                deactivateNvidiaDGPU=true
                scheduleCudaDeduction=15
                thunderboltDaemon=true
                iopcieTunnelPatch=true
            else
                irupt
            fi
        else
            if "$install"
            then
                if "$nvidiaDriversInstalled"
                then
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$nvidiaEGPUenabler1013Installed"
                then
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$amdLegacyDriversInstalled"
                then
                    deactivateNvidiaDGPU=true
                    amdLegacyDriver=true
                fi
                if "$t82UnblockerInstalled"
                then
                    t82Unblocker=true
                fi
                if "$nvidiaDGPUdeactivatorInstalled"
                then
                    deactivateNvidiaDGPU=true
                fi
                if "$nvidiaUnlockWranglerPatchInstalled"
                then
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$iopciTunnelledPatchInstalled"
                then
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$cudaDriverInstalled"
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$cudaDeveloperDriverInstalled"
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$cudaToolkitInstalled"
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if "$cudaSamplesInstalled"
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
                    nvidiaEnabler=true
                    nvidiaDriver=true
                    unlockNvidia=true
                    iopcieTunnelPatch=true
                fi
                if ( ! "$nvidiaDriver" ) && ( ! "$amdLegacyDriver" )
                then
                    scheduleSecureEGPUfetch=true
                fi
                if [[ "$scheduleCudaDeduction" < 15 ]]
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 4 1`
                fi
                thunderbolt12Unlock=true
            elif "$uninstall"
            then
                nvidiaDriver=true
                nvidiaEnabler=true
                amdLegacyDriver=true
                t82Unblocker=true
                deactivateNvidiaDGPU=true
                unlockNvidia=true
                thunderbolt12Unlock=true
                scheduleCudaDeduction=15
                thunderboltDaemon=true
                iopcieTunnelPatch=true
            else
                irupt
            fi
        fi
    fi
}




###  Subroutine Y6'4: Compatibility checks
function nvidiaDriverDeduction {
    echoing "   NVIDIA drivers"
    nvidiaDriverRoutine=0
    if "$nvidiaDriver"
    then
        if "$install"
        then
            downloadNvidiaDriverInformation
            if ! "$foundMatchNvidiaDriver"
            then
                if "$beta"
                then
                    echoend "FAILURE, no match was found" 1
                    echo "you must manually specify the version, automated matching failed, due to unknown build"
                    irupt
                else
                    echoend "FAILURE, no match was found" 1
                    irupt
                fi
            fi
            if "$reinstall" && "$nvidiaDriversInstalled"
            then
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 0 1`
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 1 1`
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 2 1`
                echoend "reinstall scheduled" 3
            elif ! "$nvidiaDriversInstalled"
            then
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 0 1`
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 2 1`
                echoend "install scheduled" 4
            elif [ "$nvidiaDriverDownloadVersion" != "$nvidiaDriverVersion" ]
            then
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 0 1`
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 1 1`
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 2 1`
                echoend "update scheduled" 4
            elif [ "$nvidiaDriverBuildVersion" != "$build" ]
            then
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 3 1`
                echoend "patch scheduled" 4        
            else
                echoend "skip, up to date" 5
                nvidiaDriver=false
            fi
        elif "$uninstall"
        then
            if "$nvidiaDriversInstalled"
            then
                nvidiaDriverRoutine=`binaryParser "$nvidiaDriverRoutine" 1 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                nvidiaDriver=false
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function nvidiaEnablerDeduction {
    echoing "   NVIDIA eGPU enabler"
    nvidiaEnablerRoutine=0
    if "$nvidiaEnabler"
    then
        if "$nvidiaDriver" || "$nvidiaDriversInstalled"
        then
            if ( [ "$os" == "10.13.0" ] && [ "$os" == "10.13.1" ] && [ "$os" == "10.13.2" ] && [ "$os" == "10.13.3" ] && [ "$os" == "10.13.4" ] && [ "$os" == "10.13.5" ] ) || ( "$beta" && ( ! "$determine" ) )
            then
                if "$install"
                then
                    downloadNvidiaEGPUenabler1013Information
                    if ! "$foundMatchNvidiaEGPUenabler1013"
                    then
                        if "$beta"
                        then
                            nvidiaEGPUenabler1013DownloadPKGName="NVDAEGPUSupport.pkg"
                            nvidiaEGPUenabler1013DownloadLink="https://egpu.io/wp-content/uploads/wpforo/attachments/6469/5130-NVDAEGPUSupportUniversal.zip"
                            nvidiaEGPUenabler1013DownloadChecksum="ed1dbef44a918d034b4c47ce996c62365871488de652fdd14104e79820daa54ecb63977bef6fbe5c6337918635224b32b607cb543cb1d5209080640ea2d6d377"
                            foundMatchNvidiaEGPUenabler1013=true
                        else
                            echoend "FAILURE, no match was found" 1
                            irupt
                        fi
                    fi
                    if "$reinstall" && "$nvidiaEGPUenabler1013Installed"
                    then
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 0 1`
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 1 1`
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 2 1`
                        echoend "reinstall scheduled" 3
                    elif ! "$nvidiaEGPUenabler1013Installed"
                    then
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 0 1`
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 2 1`
                        echoend "install scheduled" 4
                    elif [ "$nvidiaEGPUenabler1013BuildVersion" != "$build" ]
                    then
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 0 1`
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 1 1`
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 2 1`
                        echoend "update scheduled" 4
                    else
                        echoend "skip, up to date" 5
                        nvidiaEnabler=false
                    fi
                elif "$uninstall"
                then
                    if "$nvidiaEGPUenabler1013Installed"
                    then
                        nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 1 1`
                        echoend "uninstall scheduled" 3
                    else
                        echoend "skip, not installed" 5
                        nvidiaEnabler=false
                    fi
                else
                    irupt
                fi
            else
                if "$nvidiaEGPUenabler1013Installed"
                then
                    nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 1 1`
                    echoend "uninstall scheduled" 3
                else
                    echoend "skip, incompatible" 5
                    nvidiaEnabler=false
                fi
            fi
        else
            echoend "skip, dependencies" 5
            nvidiaEnabler=false
        fi
    else
        if [ "$os" != "10.13.0" ] && [ "$os" != "10.13.1" ] && [ "$os" != "10.13.2" ] && [ "$os" != "10.13.3" ] && [ "$os" != "10.13.4" ] && [ "$os" != "10.13.5" ] && "$nvidiaEGPUenabler1013Installed" && ( ! "$beta" ) && "$determine"
        then
            nvidiaEnabler=true
            nvidiaEnablerRoutine=`binaryParser "$nvidiaEnablerRoutine" 1 1`
            echoend  "uninstall scheduled" 3
        else
            echoend "skip" 5
        fi
    fi
    if [ "$nvidiaEnablerRoutine" != 0 ]
    then
        sipRequirement=`binaryParser "$sipRequirement" 6 0`
        sipRequirement=`binaryParser "$sipRequirement" 5 0`
    fi
}

function iopcieTunnelPatchDeduction {
    echoing "   IO PCIE Tunnelled patch"
    iopcieTunnelPatchRoutine=0
    if "$iopcieTunnelPatch"
    then
        if "$nvidiaDriver" || "$nvidiaDriversInstalled"
        then
            if ( [ "$os" != "10.13.0" ] && [ "$os" != "10.13.1" ] && [ "$os" != "10.13.2" ] && [ "$os" != "10.13.3" ] && [ "$os" != "10.13.4" ] && [ "$os" != "10.13.5" ] ) || ( "$beta" && ( ! "$determine" ) )
            then
                if "$install"
                then
                    if "$reinstall" && "$iopciTunnelledPatchInstalled"
                    then
                        iopcieTunnelPatchRoutine=`binaryParser "$iopcieTunnelPatchRoutine" 1 1`
                        iopcieTunnelPatchRoutine=`binaryParser "$iopcieTunnelPatchRoutine" 2 1`
                        echoend "reinstall scheduled" 3
                    elif ! "$iopciTunnelledPatchInstalled"
                    then
                        iopcieTunnelPatchRoutine=`binaryParser "$iopcieTunnelPatchRoutine" 2 1`
                        echoend "install scheduled" 4
                    else
                        echoend "skip, already installed" 5
                        iopcieTunnelPatch=false
                    fi
                elif "$uninstall"
                then
                    if "$iopciTunnelledPatchInstalled"
                    then
                        iopcieTunnelPatchRoutine=`binaryParser "$iopcieTunnelPatchRoutine" 1 1`
                        echoend "uninstall scheduled" 3
                    else
                        echoend "skip, not installed" 5
                        iopcieTunnelPatch=false
                    fi
                else
                    irupt
                fi
            else
                iopcieTunnelPatch=false
                echoend "skip, incompatible" 5
            fi
        else
            iopcieTunnelPatch=false
            echoend "skip, dependencies" 5
        fi
    else
        if [ "$os" == "10.13.0" ] && [ "$os" == "10.13.1" ] && [ "$os" == "10.13.2" ] && [ "$os" == "10.13.3" ] && [ "$os" == "10.13.4" ] && [ "$os" == "10.13.5" ] && "$iopciTunnelledPatchInstalled" && ( ! "$beta" ) && "$determine"
        then
            iopcieTunnelPatch=true
            iopcieTunnelPatch=`binaryParser "$iopcieTunnelPatch" 1 1`
            echoend  "uninstall scheduled" 3
        else
            echoend "skip" 5
        fi
    fi
    if [ "$iopcieTunnelPatchRoutine" != 0 ]
    then
        sipRequirement=0
    fi
}

function amdLegacyDriversDeduction {
    echoing "   AMD legacy drivers"
    amdLegacyDriverRoutine=0
    if "$amdLegacyDriver"
    then
        if "$install"
        then
            if "$reinstall" && "$amdLegacyDriversInstalled"
            then
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 0 1`
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 1 1`
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 2 1`
                echoend "reinstall scheduled" 3
            elif ! "$amdLegacyDriversInstalled"
            then
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 0 1`
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 2 1`
                echoend "install scheduled" 4
            else
                echoend "skip, already installed" 5
                amdLegacyDriver=false
            fi
        elif "$uninstall"
        then
            if "$amdLegacyDriversInstalled"
            then
                amdLegacyDriverRoutine=`binaryParser "$amdLegacyDriverRoutine" 1 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                amdLegacyDriver=false
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
    if [ "$amdLegacyDriverRoutine" != 0 ]
    then
        sipRequirement=`binaryParser "$sipRequirement" 6 0`
        sipRequirement=`binaryParser "$sipRequirement" 5 0`
    fi
}

function t82UnblockerDeduction {
    echoing "   T82 unblocker"
    t82UnblockerRoutine=0
    if "$t82Unblocker"
    then
        if "$install"
        then
            if "$reinstall" && "$t82UnblockerInstalled"
            then
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 0 1`
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 1 1`
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 2 1`
                echoend "reinstall scheduled" 3
            elif ! "$t82UnblockerInstalled"
            then
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 0 1`
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 2 1`
                echoend "install scheduled" 4
            else
                echoend "skip, already installed" 5
                t82Unblocker=false
            fi
        elif "$uninstall"
        then
            if "$t82UnblockerInstalled"
            then
                t82UnblockerRoutine=`binaryParser "$t82UnblockerRoutine" 1 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                t82Unblocker=false
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
    if [ "$t82UnblockerRoutine" != 0 ]
    then
        sipRequirement=`binaryParser "$sipRequirement" 6 0`
        sipRequirement=`binaryParser "$sipRequirement" 5 0`
    fi
}

function deactivateNvidiaDGPUDeduction {
    echoing "   NVIDIA dGPU deactivator"
    deactivateNVIDIAdGPURoutine=0
    if "$deactivateNvidiaDGPU"
    then
        if "$install"
        then
            if "$nvidiaDGPU"
            then
                if "$reinstall" && "$nvidiaDGPUdeactivatorInstalled"
                then
                    deactivateNVIDIAdGPURoutine=`binaryParser "$deactivateNVIDIAdGPURoutine" 1 1`
                    deactivateNVIDIAdGPURoutine=`binaryParser "$deactivateNVIDIAdGPURoutine" 2 1`
                    echoend "reinstall scheduled" 3
                elif ! "$nvidiaDGPUdeactivatorInstalled"
                then
                    deactivateNVIDIAdGPURoutine=`binaryParser "$deactivateNVIDIAdGPURoutine" 2 1`
                    echoend "install scheduled" 4
                else
                    echoend "skip, dGPU already deactivated" 5
                    deactivateNvidiaDGPU=false
                fi
            else
                echoend "skip, no NVIDIA dGPU" 5
                deactivateNvidiaDGPU=false
            fi
        elif "$uninstall"
        then
            if "$nvidiaDGPUdeactivatorInstalled"
            then
                deactivateNVIDIAdGPURoutine=`binaryParser "$deactivateNVIDIAdGPURoutine" 1 1`
                echoend "uninstall scheduled" 3
            else
                if "$nvidiaDGPU"
                then
                    echoend "skip, dGPU already activated" 5
                else
                    echoend "skip, no NVIDIA dGPU" 5
                fi
                deactivateNvidiaDGPU=false
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
    if [ "$deactivateNVIDIAdGPURoutine" != 0 ]
    then
        sipRequirement=0
    fi
}

function unlockNvidiaDeduction {
    echoing "   macOS 10.13.4/.5 NVIDIA patch"
    unlockNvidiaRoutine=0
    if "$unlockNvidia"
    then
        if ( [ "$os" == "10.13.4" ] || [ "$os" == "10.13.5" ] ) || ( "$beta" && ( ! "$determine" ) )
        then
            if "$install"
            then
                if "$reinstall" && "$nvidiaUnlockWranglerPatchInstalled"
                then
                    unlockNvidiaRoutine=`binaryParser "$unlockNvidiaRoutine" 1 1`
                    unlockNvidiaRoutine=`binaryParser "$unlockNvidiaRoutine" 2 1`
                    echoend "reinstall scheduled" 3
                elif ! "$nvidiaUnlockWranglerPatchInstalled"
                then
                    unlockNvidiaRoutine=`binaryParser "$unlockNvidiaRoutine" 2 1`
                    echoend "install scheduled" 4
                else
                    echoend "skip, already installed" 5
                    unlockNvidia=false
                fi
            elif "$uninstall"
            then
                if "$nvidiaUnlockWranglerPatchInstalled"
                then
                    unlockNvidiaRoutine=`binaryParser "$unlockNvidiaRoutine" 1 1`
                    echoend "uninstall scheduled" 3
                else
                    echoend "skip, not installed" 5
                    unlockNvidia=false
                fi
            else
                irupt
            fi
        else
            echoend "skip, incompatible" 5
            unlockNvidia=false
        fi
    else
        echoend "skip" 5
    fi
    if [ "$unlockNvidiaRoutine" != 0 ]
    then
        sipRequirement=0
    fi
}

function thunderbolt12UnlockDeduction {
    echoing "   macOS 10.13.4+ thunderbolt 1/2 unlock"
    thunderbolt12UnlockRoutine=0
    if "$thunderbolt12Unlock"
    then
        if [ "$os" != "10.13.0" ] && [ "$os" != "10.13.1" ] && [ "$os" != "10.13.2" ] && [ "$os" != "10.13.3" ] && ( [ "$thunderboltInterface" == 1 ] || [ "$thunderboltInterface" == 2 ] )
        then
            if "$install"
            then
                if "$reinstall" && "$thunderbolt12UnlockInstalled"
                then
                    thunderbolt12UnlockRoutine=`binaryParser "$thunderbolt12UnlockRoutine" 1 1`
                    thunderbolt12UnlockRoutine=`binaryParser "$thunderbolt12UnlockRoutine" 2 1`
                    echoend "reinstall scheduled" 3
                elif ! "$thunderbolt12UnlockInstalled"
                then
                    thunderbolt12UnlockRoutine=`binaryParser "$thunderbolt12UnlockRoutine" 2 1`
                    echoend "install scheduled" 4
                else
                    echoend "skip, tb""$thunderboltInterface"" already unlocked" 5
                    thunderbolt12Unlock=false
                fi
            elif "$uninstall"
            then
                if "$thunderbolt12UnlockInstalled"
                then
                    thunderbolt12UnlockRoutine=`binaryParser "$thunderbolt12UnlockRoutine" 1 1`
                    echoend "uninstall scheduled" 3
                else
                    echoend "skip, tb$thunderboltInterface already locked" 5
                    thunderbolt12Unlock=false
                fi
            else
                irupt
            fi
        else
            echoend "skip, incompatible" 5
            thunderbolt12Unlock=false
        fi
    else
        echoend "skip" 5
    fi
    if [ "$thunderbolt12UnlockRoutine" != 0 ]
    then
        sipRequirement=0
    fi
}

function thunderboltDaemonDeduction {
    echoing "   thunderbolt daemon"
    thunderboltDaemonRoutine=0
    if "$thunderboltDaemon"
    then
        if "$install"
        then
            if "$reinstall" && "$thunderboltDaemonInstalled"
            then
                thunderboltDaemonRoutine=`binaryParser "$thunderboltDaemonRoutine" 1 1`
                thunderboltDaemonRoutine=`binaryParser "$thunderboltDaemonRoutine" 2 1`
                echoend "reinstall scheduled" 3
            elif ! "$thunderboltDaemonInstalled"
            then
                thunderboltDaemonRoutine=`binaryParser "$thunderboltDaemonRoutine" 2 1`
                echoend "install scheduled" 4
            else
                echoend "skip, already installed" 5
                thunderboltDaemon=false
            fi
        elif "$uninstall"
        then
            if "$thunderboltDaemonInstalled"
            then
                thunderboltDaemonRoutine=`binaryParser "$thunderboltDaemonRoutine" 1 1`
                echoend "uninstall scheduled" 4
            else
                echoend "skip, already uninstalled" 5
                thunderboltDaemon=false
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function cudaDriverDeduction {
    echoing "      CUDA drivers"
    if [ `dc -e "$scheduleCudaDeduction 2 % n"` == 1 ]
    then
        if "$install"
        then
            if "$reinstall" && "$cudaDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 0 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 1 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 2 1`
                echoend "reinstall scheduled" 3
            elif ! "$cudaDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 0 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 2 1`
                echoend "install scheduled" 4
            else
                if [ "$cudaDriverVersion" == "$cudaDriverDownloadVersion" ]
                then
                    echoend "skip, up to date" 5
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 0`
                else
                    cudaRoutine=`binaryParser "$cudaRoutine" 0 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 1 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 2 1`
                    echoend "update scheduled" 4
                fi
            fi
        elif "$uninstall"
        then
            if "$cudaDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 1 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 0`
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function cudaDeveloperDriverDeduction {
    echoing "      CUDA developer driver"
    if [ `dc -e "$scheduleCudaDeduction 2 / 2 % n"` == 1 ]
    then
        if "$install"
        then
            if "$reinstall" && "$cudaDeveloperDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 4 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 5 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 6 1`
                echoend "reinstall scheduled" 3
            elif ! "$cudaDeveloperDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 0 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 2 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 4 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 6 1`
                echoend "install scheduled" 4
            else
                if [ "$cudaDriverVersion" == "$cudaDriverDownloadVersion" ]
                then
                    echoend "skip, up to date" 5
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 0`
                else
                    cudaRoutine=`binaryParser "$cudaRoutine" 0 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 1 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 2 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 4 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 5 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 6 1`
                    echoend "update scheduled" 4
                fi
            fi
        elif "$uninstall"
        then
            if "$cudaDeveloperDriverInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 5 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 0`
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function cudaToolkitDeduction {
    echoing "      CUDA toolkit"
    if [ `dc -e "$scheduleCudaDeduction 4 / 2 % n"` == 1 ]
    then
        if "$install"
        then
            if "$reinstall" && "$cudaToolkitInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 8 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 9 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 10 1`
                echoend "reinstall scheduled" 3
            elif ! "$cudaToolkitInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 8 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 10 1`
                echoend "install scheduled" 4
            else
                if [ "$cudaVersionFull" == "$cudaToolkitDownloadVersion" ]
                then
                    echoend "skip, up to date" 5
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 0`
                else
                    cudaRoutine=`binaryParser "$cudaRoutine" 8 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 9 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 10 1`
                    echoend "update scheduled" 4
                fi
            fi
        elif "$uninstall"
        then
            if "$cudaToolkitInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 9 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 0`
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function cudaSamplesDeduction {
    echoing "      CUDA samples"
    if [ `dc -e "$scheduleCudaDeduction 8 / 2 % n"` == 1 ]
    then
        if "$install"
        then
            if "$reinstall" && "$cudaSamplesInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 12 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 13 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 14 1`
                echoend "reinstall scheduled" 3
            elif ! "$cudaSamplesInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 12 1`
                cudaRoutine=`binaryParser "$cudaRoutine" 14 1`
                echoend "install scheduled" 4
            else
                if [ "$cudaVersionFull" == "$cudaToolkitDownloadVersion" ]
                then
                    echoend "skip, up to date" 5
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 0`
                else
                    cudaRoutine=`binaryParser "$cudaRoutine" 12 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 13 1`
                    cudaRoutine=`binaryParser "$cudaRoutine" 14 1`
                    echoend "update scheduled" 4
                fi
            fi
        elif "$uninstall"
        then
            if "$cudaSamplesInstalled"
            then
                cudaRoutine=`binaryParser "$cudaRoutine" 13 1`
                echoend "uninstall scheduled" 3
            else
                echoend "skip, not installed" 5
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 0`
            fi
        else
            irupt
        fi
    else
        echoend "skip" 5
    fi
}

function cudaDeduction {
    cudaRoutine=0
    if [ "$scheduleCudaDeduction" != 0 ]
    then
        if "$install"
        then
            if "$nvidiaDriver" || "$nvidiaDriversInstalled"
            then
                echo "   CUDA software"
                downloadCudaDriverInformation
                downloadCudaToolkitInformation
                if [ `dc -e "$scheduleCudaDeduction 8 / 2 % n"` == 1 ]
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                elif [ `dc -e "$scheduleCudaDeduction 4 / 2 % n"` == 1 ]
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                elif [ `dc -e "$scheduleCudaDeduction 2 / 2 % n"` == 1 ]
                then
                    scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                fi
            else
                echoing "   CUDA software"
                echoend "skip, dependecies" 5
                scheduleCudaDeduction=0
            fi
        elif "$uninstall"
        then
            if [ `dc -e "$scheduleCudaDeduction 2 % n"` == 1 ]
            then
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 1 1`
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
            elif [ `dc -e "$scheduleCudaDeduction 2 / 2 % n"` == 1 ]
            then
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 0 1`
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 2 1`
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
            elif [ `dc -e "$scheduleCudaDeduction 4 / 2 % n"` == 1 ]
            then
                scheduleCudaDeduction=`binaryParser "$scheduleCudaDeduction" 3 1`
            fi
        fi
        cudaDriverDeduction
        cudaDeveloperDriverDeduction
        cudaToolkitDeduction
        cudaSamplesDeduction
    else
        echoing "   CUDA software"
        echoend "skip" 5
    fi
}


###  Subroutine Y6'5: sufficent disabled SIP
function checkSIPRequirement {
    appleInternalTemp=`dc -e "$sipRequirement 64 / 2 % n"`
    kextSigningTemp=`dc -e "$sipRequirement 32 / 2 % n"`
    fileSystemProtectionsTemp=`dc -e "$sipRequirement 16 / 2 % n"`
    debuggingRestrictionsTemp=`dc -e "$sipRequirement 8 / 2 % n"`
    dTraceRestrictionsTemp=`dc -e "$sipRequirement 4 / 2 % n"`
    nvramProtectionsTemp=`dc -e "$sipRequirement 2 / 2 % n"`
    baseSystemVerificationTemp=`dc -e "$sipRequirement 2 % n"`
    for i in `seq 0 6`
    do
        if [[ `dc -e "$sipRequirement 2 $i ^ / 2 % n"` < `dc -e "$statSIP 2 $i ^ / 2 % n"` ]]
        then
            echoend "ERROR" 1
            echo "   SIP setting too high."
            echo "Execute in recovery mode:"
            if [ "$sipRequirement" == 0 ] || [ "$baseSystemVerificationTemp" == 0 ]
            then
                echo "csrutil disable"
            else
                echo -n "csrutil"
                if [ "$appleInternalTemp" == 0 ]
                then
                    echo -n " --no-internal"
                fi
                if [ "$kextSigningTemp" == 0 ]
                then
                    echo -n " --without kext"
                fi
                if [ "$fileSystemProtectionsTemp" == 0 ]
                then
                    echo -n " --without fs"
                fi
                if [ "$debuggingRestrictionsTemp" == 0 ]
                then
                    echo -n " --without debug"
                fi
                if [ "$dTraceRestrictionsTemp" == 0 ]
                then
                    echo -n " --without dtrace"
                fi
                if [ "$nvramProtectionsTemp" == 0 ]
                then
                    echo -n " --without nvram"
                fi
                echo ""
            fi
            irupt
        fi
    done
    echoend "OK" 2
    if "$debug"
    then
        echo
        echo "$sipRequirement"
        echo "$statSIP"
    fi
}




###  Subroutine Y6'6: Fetch eGPU and deduce
##fn
function softwareDeduction {
    if "$scheduleSecureEGPUfetch"
    then
        if [ "$os" != "10.13.0" ] && [ "$os" != "10.13.1" ] && [ "$os" != "10.13.2" ] && [ "$os" != "10.13.3" ]
        then
            echo "Automatic eGPU information fetching..."
            secureGetEGPUInformation
            if "$t82Unblocker"
            then
                echo "   After the script has finshed and the Mac has been rebooted"
                echo "   you will need to execute the script again."
            fi
        else
            echo "Manual eGPU information fetching..."
            manualGetEGPUInformation
        fi
    fi

    if [[ "$scheduleCudaDeduction" > 15 ]] && "$install"
    then
        echo "Fetching CUDA needs..."
        getCudaNeeds
    fi

    echo "Checking for incompatibilies and up to date software..."
    nvidiaDriverDeduction
    nvidiaEnablerDeduction
    amdLegacyDriversDeduction
    t82UnblockerDeduction
    deactivateNvidiaDGPUDeduction
    unlockNvidiaDeduction
    thunderbolt12UnlockDeduction
    cudaDeduction
    thunderboltDaemonDeduction
    iopcieTunnelPatchDeduction

    echoing "Checking if SIP is sufficently disabled..."
    checkSIPRequirement
}




###  Subroutine Y6'7: Combine fetching, switching and deducution
function determination {
    echo "Fetching system information..."
    gatherSystemInfo

    echo "Setting internal switches..."
    setStandards

    softwareDeduction
}



###  Subroutine Y7: Check script requirement basics
function checkScriptRequirement {
    fetchOSinfo
    if [ "${os::5}" != "10.13" ]
    then
        echo
        echo "This script is only for macOS 10.13.X"
        if "$beta"
        then
            echo "Continuation might result in failure and/or system crash. (seriously!)"
            echo "continuing due to beta flag..."
            waiter 4
        else
            irupt
        fi
    elif [ "$os" == "$warningOS" ] && ( ! "$beta" )
    then
        echo
        echo "This script is not designed to work with your current version of macOS."
        echo "Continuation might result in failure and/or system crash. (seriously!)"
        waiter 10
    fi
    fetchAppleGPUWranglerVersion
    if "$debug"
    then
        echo
        echo "$os"
        echo "$build"
        echo "$binaryHashReturn"
        echo
    fi
    if ! [[ "$appleGPUWranglerVersion" =~ "$build" ]] && [ "$appleGPUWranglerVersion" != "" ]
    then
        echo "A system file (wrangler), has been replaced and does not fit to the system. You must revert those changes in order to continue. You can also upgrade to the latest supported release or reinstall macOS."
        if "$beta"
        then
            echo "Continuation might result in failure and/or system crash. (seriously!)"
            echo "continuing due to beta flag..."
            waiter 4
        else
            irupt
        fi
    elif [ "$appleGPUWranglerVersion" == "" ]
    then
        echo "Your system hasn't yet been approved. The system may be unbootable or unstable."
        if "$beta"
        then
            echo "Continuation might result in failure and/or system crash. (seriously!)"
            echo "continuing due to beta flag..."
            waiter 4
        else
            irupt
        fi
    fi
}




###  Subroutine Y8: Execution
###  Subroutine Y8'1: Download
##fn
function download {
    createSpace 2
    trapWithoutWarning
    echo "Download external content..."
    if [ `dc -e "$nvidiaDriverRoutine 2 % n"` == 1 ]
    then
        echo "--- NVIDIA drivers ---"
        downloadNvidiaDriver
        if "$omitNvidiaDriver"
        then
            echo
            echo "NVIDIA driver download failed. Checksums do not match."
            irupt
        fi
    fi
    if [ `dc -e "$nvidiaEnablerRoutine 2 % n"` == 1 ]
    then
        echo "--- NVIDIA eGPU enabler ---"
        downloadNvidiaEGPUenabler1013
        if "$omitNvidiaEGPUenabler1013"
        then
            echo
            echo "NVIDIA eGPU enabler download failed. Checksums do not match."
            irupt
        fi
    fi
    if [ `dc -e "$amdLegacyDriverRoutine 2 % n"` == 1 ]
    then
        echo "--- AMD legacy drivers ---"
        downloadAMDLegacyDriver
        if "$omitAMDLegacyDriver"
        then
            echo
            echo "AMD legacy driver download failed. Checksums do not match."
            irupt
        fi
    fi
    if [ `dc -e "$t82UnblockerRoutine 2 % n"` == 1 ]
    then
        echo "--- T82 unblock ---"
        downloadT82Unblocker
        if "$omitT82Unblocker"
        then
            echo
            echo "T82 unblocker download failed. Checksums do not match."
            irupt
        fi
    fi
    if [ `dc -e "$cudaRoutine 2 % n"` == 1 ]
    then
        echo "--- CUDA driver ---"
        downloadCudaDriver
        if "$omitCuda"
        then
            echo
            echo "CUDA driver download failed. Checksums do not match."
            irupt
        fi
    fi
    if [ `dc -e "$cudaRoutine 16 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 256 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 4096 / 2 % n"` == 1 ]
    then
        echo "--- CUDA developer driver / CUDA toolkit / CUDA samples ---"
        downloadCudaToolkit
        if "$omitCuda"
        then
            echo
            echo "CUDA developer driver / CUDA tooolkit / CUDA samples download failed. Checksums do not match."
            irupt
        fi
    fi
    
}




###  Subroutine Y8'2: Uninstall
##fn
function uninstall {
    createSpace 2
    echo "Uninstalling..."
    trapWithWarning
    if [ `dc -e "$nvidiaDriverRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA driver"
        uninstallNvidiaDriver
        echoend "done"
    fi
    if [ `dc -e "$nvidiaEnablerRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA eGPU support"
        uninstallNvidiaEGPUenabler1013
        echoend "done"
    fi
    if [ `dc -e "$unlockNvidiaRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA macOS 10.13.4/.5 unlock"
        trapLock
        uninstallNvidiaUnlockWranglerPatch
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$iopcieTunnelPatchRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   IO PCIE Tunnelled patch"
        trapLock
        uninstallIopciTunnelledPatch
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$amdLegacyDriverRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   AMD legacy drivers"
        uninstallAMDLegacyDriver
        echoend "done"
    fi
    if [ `dc -e "$t82UnblockerRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   T82 Unblocker"
        uninstallT82Unblocker
        echoend "done"
    fi
    if [ `dc -e "$deactivateNVIDIAdGPURoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA dGPU deactivator"
        uninstallNvidiaDGPUdeactivator
        echoend "done"
    fi
    if [ `dc -e "$thunderbolt12UnlockRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   Thunderbolt 1/2 unlock"
        trapLock
        uninstallThunderbolt12Unlock
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$cudaRoutine 2 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 32 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 512 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 8192 / 2 % n"` == 1 ]
    then
        echoing "   CUDA"
        uninstallCuda
        echoend "done"
    fi
    if [ `dc -e "$thunderboltDaemonRoutine 2 / 2 % n"` == 1 ]
    then
        echoing "   thunderbolt daemon"
        uninstallThunderboltDaemon
        echoend "done"
    fi
}




###  Subroutine Y8'3: Install
function install {
    echo "Installing..."
    if [ `dc -e "$nvidiaDriverRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA driver"
        installNvidiaDriver
        echoend "done"
    fi
    if [ `dc -e "$nvidiaEnablerRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA eGPU support"
        installNvidiaEGPUenabler1013
        echoend "done"
    fi
    if [ `dc -e "$unlockNvidiaRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA macOS 10.13.4/.5 unlock"
        trapLock
        installNvidiaUnlockWranglerPatch
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$iopcieTunnelPatchRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   IO PCIE Tunnelled patch"
        trapLock
        installIopciTunnelledPatch
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$amdLegacyDriverRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   AMD legacy drivers"
        installAMDLegacyDriver
        echoend "done"
    fi
    if [ `dc -e "$t82UnblockerRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   T82 Unblocker"
        installT82Unblocker
        echoend "done"
    fi
    if [ `dc -e "$deactivateNVIDIAdGPURoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   NVIDIA dGPU deactivator"
        installNvidiaDGPUdeactivator
        echoend "done"
    fi
    if [ `dc -e "$thunderbolt12UnlockRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   Thunderbolt 1/2 unlock"
        trapLock
        installThunderbolt12Unlock
        trapWithWarning
        echoend "done"
    fi
    if [ `dc -e "$cudaRoutine 4 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 64 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 1024 / 2 % n"` == 1 ] || [ `dc -e "$cudaRoutine 16384 / 2 % n"` == 1 ]
    then
        echoing "   CUDA"
        installCuda
        echoend "done"
    fi
    if [ `dc -e "$thunderboltDaemonRoutine 4 / 2 % n"` == 1 ]
    then
        echoing "   thunderbolt daemon"
        installThunderboltDaemon
        echoend "done"
    fi
}




###  Subroutine Y8'4: Patch
function patch {
    echo "Patching..."
    if [ `dc -e "$nvidiaDriverRoutine 8 / 2 % n"` == 1 ]
    then
        trapLock
        patchNvidiaDriverOld
        trapWithWarning
        echoend "done"
    fi
}



###  Subroutine Y8'5: Deactivate auto updaters
cudaUpdateDaemonPath="/Library/LaunchAgents/com.nvidia.CUDASoftwareUpdate.plist"
function deactivateCUDAupdater {
    if [ -e "$cudaUpdateDaemonPath" ]
    then
        elevatePrivileges
        echoing "   CUDA"
        sudo rm -f "$cudaUpdateDaemonPath"
        echoend "done"
        doneSomething=true
    fi
}


nvidiaDriverUpdateLibPath="$HOME""/Library/Preferences/ByHost"
nvidiaDriverUpdatePlistPath=""
function deactivateNvidiaDriverUpdater {
    nvidiaDriverUpdatePlistPath=`find "$nvidiaDriverUpdateLibPath" -iname com.nvidia.nvagent*`
    if [ `echo "$nvidiaDriverUpdatePlistPath" | grep "nvagent" | wc -l | xargs` == 1 ]
    then
        updatePlistTemp=`"$pbuddy" -c "Print" "$nvidiaDriverUpdatePlistPath"`
        toDoListTemp=0
        if [[ "$updatePlistTemp[@]" =~ "autoCheck" ]]
        then
            if [ `"$pbuddy" -c "Print autoCheck" "$nvidiaDriverUpdatePlistPath"` != 0 ]
            then
                toDoListTemp=`binaryParser "$toDoListTemp" 0 1`
            fi
        else
            toDoListTemp=`binaryParser "$toDoListTemp" 1 1`
        fi
        if [[ "$updatePlistTemp[@]" =~ "downloadInBackground" ]]
        then
            toDoListTemp=`binaryParser "$toDoListTemp" 2 1`
        fi
        if [ "$toDoListTemp" != 0 ]
        then
            elevatePrivileges
            echoing "   NVIDIA"
            if [ `dc -e "$toDoListTemp 2 % n"` == 1 ]
            then
                sudo "$pbuddy" -c "Set autoCheck 0" "$nvidiaDriverUpdatePlistPath"
            fi
            if [ `dc -e "$toDoListTemp 2 / 2 % n"` == 1 ]
            then
                sudo "$pbuddy" -c "Add autoCheck integer 0" "$nvidiaDriverUpdatePlistPath"
            fi
            if [ `dc -e "$toDoListTemp 4 / 2 % n"` == 1 ]
            then
                sudo "$pbuddy" -c "Remove downloadInBackground" "$nvidiaDriverUpdatePlistPath"
            fi
            echoend "done"
            doneSomething=true
        fi
    fi
}

function deactivateAutoUpdaters {
    echo "deactivating auto-updates..."
    deactivateCUDAupdater
    deactivateNvidiaDriverUpdater
}


##  Subroutine Y9: Pre branch functions
function printHelp {
    if "$help"
    then
        createSpace 3
        printHeader
        printUsage
        createSpace 3
        exit
    fi
}

function forceCacheRebuildPreBranch {
    if "$forceCacheRebuild"
    then
        if ! "$acceptLicense"
        then
            createSpace 3
            printHeader
            askLicenseQuestion
        else
            createSpace 3
            printHeader
        fi
        createSpace 3
        scheduleKextTouch=true
        rebuildKextCache
        exit
    fi
}

##fn
function checkSystem {
    if "$check"
    then
        if ! "$acceptLicense"
        then
            createSpace 3
            printHeader
            askLicenseQuestion
        else
            createSpace 3
            printHeader
        fi
        createSpace 3
        echo "Fetching system information..."
        gatherSystemInfo
        systemProfilerTemp=""
        if "$fullCheck"
        then
            echoing "   creating detailed system report"
            systemProfilerTemp=`system_profiler -detailLevel mini 2>/dev/null`
            echoend "done"
        else
            echoing "   fetching GPU related system information"
            systemProfilerTemp=`system_profiler -detailLevel mini SPDisplaysDataType SPHardwareDataType SPThunderboltDataType SPPCIDataType 2>/dev/null`
            echoend "done"
        fi
        createSpace 3
        printHeader
        echo "Listing installation status of packages..."
        echoing "   NVIDIA driver"
        if "$nvidiaDriversInstalled"
        then
            echoend "$nvidiaDriverVersion"
        else
            echoend "not installed"
        fi
        echoing "   NVIDIA eGPU enabler"
        if "$nvidiaEGPUenabler1013Installed"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echoing "   AMD legacy drivers"
        if "$amdLegacyDriversInstalled"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echoing "   T82 unblocker"
        if "$t82UnblockerInstalled"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echoing "   NVIDIA dGPU"
        if "$nvidiaDGPUdeactivatorInstalled"
        then
            echoend "deactivated"
        else
            if "$nvidiaDGPU"
            then
                echoend "activated"
            else
                echoend "not available"
            fi
        fi
        echoing "   NVIDIA macOS 10.13.4/.5 patch"
        if "$nvidiaUnlockWranglerPatchInstalled"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echoing "   IO PCIE Tunnelled patch"
        if "$iopciTunnelledPatchInstalled"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echoing "   unlocked thunderbolt version"
        echoend "$thunderbolt12UnlockInstallStatus"
        echoing "   thunderbolt daemon"
        if "$thunderboltDaemonInstalled"
        then
            echoend "installed"
        else
            echoend "not installed"
        fi
        echo "   CUDA"
        echoing "      CUDA drivers"
        if "$cudaDriverInstalled"
        then
            echoend "$cudaDriverVersion"
        else
            echoend "not installed"
        fi
        echoing "      CUDA developer drivers"
        if "$cudaDeveloperDriverInstalled"
        then
            echoend "$cudaDriverVersion"
        else
            echoend "not installed"
        fi
        echoing "      CUDA toolkit"
        if "$cudaToolkitInstalled"
        then
            echoend "$cudaVersionFull"
        else
            echoend "not installed"
        fi
        echoing "      CUDA samples"
        if "$cudaSamplesInstalled"
        then
            echoend "$cudaVersionFull"
        else
            echoend "not installed"
        fi
        echo "Listing system information..."
        echoing "   macOS version"
        echoend "$os"
        echoing "   macOS build"
        echoend "$build"
        echoing "   SIP status"
        echoend "$statSIP"
        echoing "   thunderbolt interface version"
        echoend "$thunderboltInterface"
        echo "   eGPU information"
        echoing "      connected eGPU"
        echoend "$connectedEGPU"
        if "$connectedEGPU"
        then
            echoing "      eGPU vendor"
            echoend "$connectedEGPUVendor"
        fi
        echoing "   NVIDIA dGPU"
        echoend "$nvidiaDGPU"
        echoing "   AGW version"
        echoend "$appleGPUWranglerVersion"
        echo "$systemProfilerTemp"
        exit
    fi
}

function installShortCommand {
    commandShortPathTemp="/usr/local/bin/macos-egpu"
    installShortCommandTemp=false
    checkInternetConnection
    if "$internet"
    then
        if ! [ -e "$commandShortPathTemp" ]
        then
            echo
            echo "--- installing short command ---"
            installShortCommandTemp=true
        elif [ `shasum -a 512 -b "$commandShortPathTemp" | awk '{ print $1 }'` != `curl -s "$gitPath""/Data/checksum.txt"` ]
        then
            echo
            echo "--- updating short command ---"
            installShortCommandTemp=true
        else
            installShortCommandTemp=false
        fi
        if "$debug"
        then
            echo `shasum -a 512 -b "$commandShortPathTemp" | awk '{ print $1 }'`
            echo `curl -s "$gitPath""/Data/checksum.txt"`
        fi
        if "$installShortCommandTemp"
        then
            elevatePrivileges
            sudo mkdir -p /usr/local/bin
            scriptGenerateTemp=`curl -s "$gitPath""/macOS-eGPU.sh"`
            echo "$scriptGenerateTemp" | sudo tee "$commandShortPathTemp" &>/dev/null
            sudo chown "$SUDO_USER" "$commandShortPathTemp"
            sudo chmod 755 "$commandShortPathTemp"
            echo "now the script can be used like this (internet may be required):"
            echo "macos-egpu [parameters]"
            if "$debug"
            then
                echo "Parameters:"
                echo "$scriptParameterList"
            fi
            waiter 7
            echo "--- short command end ---"
            echo
            echo "--- restarting ---"
            echo
            echo
            sudo macos-egpu$scriptParameterList
            exit 0
        fi
    fi
}

###  Subroutine Y10: Base function
function macOSeGPU {
    checkScriptRequirement
    printHelp
    forceCacheRebuildPreBranch
    checkSystem

    enforceEGPUdisconnect
    preparations

    installShortCommand
    if ( ! "$uninstall" ) && ( "$nvidiaDriver" || "$amdLegacyDriver" || "$nvidiaEnabler" || "$t82Unblocker" || [ "$scheduleCudaDeduction" != 0 ] )
    then
        checkInternetConnection
        if ! "$internet"
        then
            echo
            echo "--- internet connection required ---"
            echo
            irupt
        fi
    fi

    determination
    download
    deactivateNVIDIAdGPURoutine=0
    deactivateNVIDIAdGPU=false

    if [ "$nvidiaDriverRoutine" != 0 ] || [ "$nvidiaEnablerRoutine" != 0 ] || [ "$unlockNvidiaRoutine" != 0 ] || [ "$amdLegacyDriverRoutine" != 0 ] || [ "$t82UnblockerRoutine" != 0 ] || [ "$deactivateNVIDIAdGPURoutine" != 0 ] || [ "$thunderbolt12UnlockRoutine" != 0 ] || [ "$cudaRoutine" != 0 ] || [ "$thunderboltDaemonRoutine" != 0 ] || [ "$iopcieTunnelPatchRoutine" != 0 ]
    then
        echo
        echo
        echo "Checking for elevated privileges..."
        elevatePrivileges
    fi

    uninstall
    install
    patch

    deactivateAutoUpdaters

    finish
}


#   Subroutine Z: Script execution call ##############################################################################################################
macOSeGPU




#   end of script

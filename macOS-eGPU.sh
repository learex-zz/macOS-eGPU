#!/bin/bash
#
# Authors: learex
# Homepage: https://github.com/learex/macOS-eGPU
# License: https://github.com/learex/macOS-eGPU/License.text
#
# USAGE TERMS of macOS-eGPU.sh
# 1. You may use this script for personal use.
# 2. You may continue development of this script at it's GitHub homepage.
# 3. You may not redistribute this script from outside of it's GitHub homepage.
# 4. You may not use this script, or portions thereof, for any commercial purposes.
# 5. You accept the license terms of all downloaded and/or executed content, even content that has not been downloaded and/or executed by macOS-eGPU.sh directly.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


#create blank screen
clear


#define all paths and URLs
#directory handling
dirName="$(uuidgen)"
dirName="$TMPDIR""macOSeGPU""$dirName"

#tempdir creator
function mktmpdir {
    if ! [ -d "$dirName" ]
    then
        mkdir "$dirName"
    fi
}

function cleantmpdir {
    if [ -d "$dirName" ]
    then
        rm -rf "$dirName"
    fi
}

pbuddy="/usr/libexec/PlistBuddy"

####
branch="newFunctionality"

#download
automateeGPUScriptDPath="https://raw.githubusercontent.com/goalque/automate-eGPU/master/automate-eGPU.sh"
nvidiaUpdateScriptDPath="https://raw.githubusercontent.com/Benjamin-Dobell/nvidia-update/master/nvidia-update.sh"
nvidiaDriverListOnline="https://gfe.nvidia.com/mac-update"
cudaDriverListOnline="https://raw.githubusercontent.com/learex/macOS-eGPU/""$branch""/cudaDriver.plist"
cudaToolkitListOnline="https://raw.githubusercontent.com/learex/macOS-eGPU/""$branch""/cudaToolkit.plist"
eGPUEnablerListOnline="https://raw.githubusercontent.com/learex/macOS-eGPU/""$branch""/eGPUenabler.plist"
CUDAAppListOnline="https://raw.githubusercontent.com/learex/macOS-eGPU/""$branch""/CUDAApps.plist"
eGPUEnablerDPath=""
eGPUEnablerAuthor=""
eGPUEnablerPKGName=""
cudaDriverDPath=""
cudaToolkitDPath=""
cudaDownloadVersion=""
nvidiaDriverDownloadVersion=""

#install
eGPUEnablerPKGName=""
eGPUEnablerAuthor=""
cudaDriverVolPath="/Volumes/CUDADriver/"
cudaDriverPKGName="CUDADriver.pkg"
cudaToolkitVolPath="/Volumes/CUDAMacOSXInstaller/"
cudaToolkitPKGName="CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller"
programmList=""

#uninstall
nvidiaDriverUnInstallPath="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
cudaVersionPath="/usr/local/cuda/version.txt"
cudaDriverUnInstallScriptPath="/usr/local/bin/uninstall_cuda_drv.pl"
cudaToolkitUnInstallDir=""
cudaToolkitUnInstallScript=""
cudaDeveloperDirPath="/Developer/NVIDIA/"
enablerKextPath="/Library/Extensions/NVDAEGPUSupport.kext"
automateeGPUPath="/Library/Application Support/Automate-eGPU/"
automateeGPUScriptPath="/usr/local/bin/automate-eGPU.sh"

#info
nvidiaDriverVersionPath="/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist"
eGPUBuildVersionPath="/Library/Extensions/NVDAEGPUSupport.kext/Contents/Info.plist"

#define all settings and info variables
scheduleReboot=0

install=0
uninstall=0
update=0
enabler=0
driver=0
cuda=0
determine=0

noReboot=0
silent=0
license=0
errorCont=0
minimal=0
forceNew="stable"

os=0
build=0
statSIP=128

eGPUenablerBuildVersion=""
nvidiaDriverVersion=""
nvidiaDriverBuildVersion=""
cudaVersion=0
cudaVersionFull=0
cudaVersionsInstalled=""
cudaVersions=0


#already installed
cudaVersionInstalled=0
cudaDriverInstalled=0
cudaToolkitInstalled=0
cudaSamplesInstalled=0
nvidiaDriversInstalled=0
eGPUenablerInstalled=0
automateeGPUInstalled=0

#freshly installed
doneSomething=0
installedNvidiaDrivers=0
installedEnabler=0
installedCudaDriver=0
installedCudaToolkit=0
installedCudaSamples=0

waitTime=7
priorWaitTime=5

#define error functions and messages and end functions
function printChanges {
    case "$installedNvidiaDrivers"
    in
    "1")
        echo "Nvidia drivers have been installed."
        ;;
    "0")
        echo "Nvidia drivers have not been changed."
        ;;
    "-1")
        echo "Nvidia drivers have been uninstalled."
        ;;
    *)
        ;;
    esac
    case "$installedEnabler"
    in
    "1")
        echo "The eGPU enabler has been installed."
        ;;
    "0")
        echo "The eGPU enabler has not been changed."
        ;;
    "-1")
        echo "The eGPU enabler has been uninstalled."
        ;;
    *)
        ;;
    esac
    case "$installedCudaDriver"
    in
    "1")
        echo "CUDA drivers have been installed."
        ;;
    "0")
        echo "CUDA drivers have not been changed."
        ;;
    "-1")
        echo "CUDA drivers have been uninstalled."
        ;;
    *)
        ;;
    esac
    case "$installedCudaToolkit"
    in
    "1")
        echo "The CUDA toolkit has been installed."
        ;;
    "0")
        echo "The CUDA toolkit has not been changed."
        ;;
    "-1")
        echo "The CUDA toolkit has been uninstalled."
        ;;
    *)
        ;;
    esac
    case "$installedCudaSamples"
    in
    "1")
        echo "The CUDA samples have been installed."
        ;;
    "0")
        echo "The CUDA samples have not been changed."
        ;;
    "-1")
        echo "The CUDA samples have been uninstalled."
        ;;
    *)
        ;;
esac
}

function rebootSystem {
    cleantmpdir
    if [ "$scheduleReboot" == 0 ]
    then
        exit
    elif [ "$noReboot" == 1 ]
    then
        echo "A reboot of the system is recommended."
    else
        if [ "$waitTime" == 1 ]
        then
            echo "The system will reboot in 1 second ..."
        elif [ "$waitTime" == 0 ]
        then
            echo "The system will reboot now ..."
        else
            echo "The system will reboot in $waitTime seconds ..."
        fi
        sleep "$waitTime"
###            sudo reboot
    fi
    exit
}

function irupt {
    cleantmpdir
    echo
    echo "The script has failed."
    if [ "$doneSomething" == 1 ]
    then
        printChanges
    else
        echo "Nothing has been changed."
    fi
    exit
}

function finish {
    cleantmpdir
    echo
    echo "The script has finished successfully."
    if [ "$doneSomething" == 1 ]
    then
        printChanges
        rebootSystem
    else
        echo "Nothing has been changed."
    fi
    exit
}


function iruptError {
    echo
    echo
    case "$1"
    in
    "param")
        echo "This parameter configuration is currently unsupported."
        ;;
    "unsupBuild")
        echo "You have an unsupported build of macOS."
        echo "This may change in the future, so try again in a few hours."
        ;;
    "unex")
        echo "An unexpected error has occured."
        ;;
    "unsupOS")
        echo "Your OS is not supported by this script."
        ;;
    "toNewOS")
        echo "Your OS is to new. Compatibility may change in the future, though."
        ;;
    "conflicArg")
        echo "Conflicting arguments."
        ;;
    "unknwnArg")
        echo "unkown argument given"
        ;;
    "SIP")
        echo "The script has failed. Nothing has been changed."
        echo "System Integrity Protection (SIP) is not set correctly."
        echo "Please boot into recovery mode and execute:"
        echo "csrutil enable --without kext; reboot;"
        ;;
    "SIPerror")
        echo "An error whithin SIP detection as occured."
        echo "To protect your system the script has stopped."
        echo "Please check your System Integrity Protection (SIP) status by executing:"
        echo "csrutil status"
        echo "You might want to try booting into recovery mode and executing:"
        echo "csrutil enable --without kext; reboot;"
        ;;
    *)
        echo "An unknown error as occured."
        ;;
    esac
    irupt
}

function cont {
    case "$1"
    in
    "error")
        case "$errorCont"
        in
        "0")
            echo "Continuation might result in failure!"
            echo "$3"
            ;;
        "1")
            echo "The script will try to execute the rest of the queue due to --errorContinue ..."
            echo "Expect the script to fail."
            ;;
        "2")
            echo "Breaking silence ..."
            silent=0
            echo "$3"
            ;;
        "3")
            finish
            ;;
        *)
            iruptError "unex"
            ;;
        esac
        ;;
    "ask")
        echo "$3"
        ;;
    *)
        iruptError "unex"
        ;;
    esac
    if [ "$silent" == 0 ]
    then
        read -p "$2"" [y]es [n]o : " -n 1 -r
        echo
        if [ "$REPLY" != "y" ]
        then
            finish
        fi
    else
        echo "$2"" [y]es [n]o : y"
    fi
}

function contError {
    echo
    echo
    fail=0
    case "$1"
    in
    "unCudaVers")
        echo "No CUDA installation was detected."
        ;;
    "unCudaDriver")
        echo "No CUDA driver was detected."
        ;;
    "unCudaToolkit")
        echo "No CUDA toolkit was detected."
        ;;
    "unCudaSamples")
        echo "No CUDA samples were detected."
        ;;
    "unNvidiaDriver")
        echo "No CUDA driver was found."
        ;;
    "unEnabler")
        echo "No nvidia eGPU enabler was found."
        ;;
    "cudaVersion")
        echo "Multiple CUDA versions were detected."
        echo "Trying to uninstall them all..."
        ;;
    "cudaDriver")
        echo "The best CUDA driver is already installed."
        ;;
    "cudaToolkit")
        echo "The best CUDA toolkit is already installed."
        ;;
    "enabler")
        echo "The matching eGPU enabler is already installed."
        ;;
    "noCUDAdriver")
        echo "No CUDA driver was found for your version of macOS."
        ;;
    "noNvidiaDriver")
        echo "No nvidia driver was found for your version of macOS."
        echo "Falling back to latest release."
        ;;
    *)
        echo "An unknown error as occured."
        fail=1
        ;;
    esac
    if [ "$fail" == 1 ]
    then
        cont "error" "Continue?" "The script will try to execute the rest of the queue ..."
        echo "The script will still try to continue executing ..."
    fi
}

#extract parameters
for options in "$@"
do
    case "$options"
    in
    "--install" | "-i")
        if [ "$uninstall" != 0 ] || [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        install=1
        ;;
    "--uninstall" | "-u")
        if [ "$install" != 0 ] || [ "$update" != 0 ] || [ "$forceNew" != "stable" ]
        then
            iruptError "conflicArg"
        fi
        uninstall=1
        ;;
    "--update" | "-r")
        if [ "$install" != 0 ] || [ "$uninstall" != 0 ]
        then
            iruptError "conflicArg"
        fi
        update=1
        ;;
    "--driver" | "-d")
        if  [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        driver=1
        ;;
    "--forceNewest" | "-f")
        if [ "$uninstall" != 0 ]
        then
            iruptError "conflicArg"
        fi
        forceNew="newest"
        ;;
    "--enabler" | "-e")
        if  [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        enabler=1
        ;;
    "--cuda" | "-c")
        if [ "$cuda" != 0 ] || [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        cuda=1
        ;;
    "--cudaDriver" | "-v")
        if [ "$cuda" != 0 ] || [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        cuda=2
        ;;
    "--cudaToolkit" | "-t")
        if [ "$cuda" != 0 ] || [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        cuda=3
        ;;
    "--cudaSamples" | "-a")
        if [ "$cuda" != 0 ] || [ "$update" != 0 ]
        then
            iruptError "conflicArg"
        fi
        cuda=4
        ;;
    "--mininmal" | "-m")
        minimal=1
        ;;
    "--noReboot" | "-n")
        noReboot=1
        ;;
    "--silent" | "-s")
        silent=1
        ;;
    "--acceptLicenseTerms")
        license=1
        ;;
    "--errorContinue")
        if [ "$errorCont" != 0 ]
        then
            iruptError "conflicArg"
        fi
        errorCont=1
        ;;
    "--errorBreakSilence")
        if [ "$errorCont" != 0 ]
        then
            iruptError "conflicArg"
        fi
        errorCont=2
        ;;
    "--errorStop")
        if [ "$errorCont" != 0 ]
        then
            iruptError "conflicArg"
        fi
        errorCont=3
        ;;
    *)
        iruptError "unknwnArg"
        ;;
    esac
done

if [ "$silent" == 1 ] && [ "$license" == 0 ]
then
    echo "Silent execution requires explicit acceptance of the licensing terms."
    echo "To accept them and run the script in silent mode add the parameter --acceptLicenseTerms"
    finish
fi

if [ "$silent" == 0 ] && [ "$errorCont" != 0 ]
then
    echo "Error handling options can only be used in conjunction with --silent."
    finish
fi

#display warning
if [ "$noReboot" == 0 ]
then
    echo "The system will reboot after successfull completion."
    if [ "$priorWaitTime" == 1 ]
    then
        echo "You have 1 second to abort the script (^C) ..."
    elif [ "$priorWaitTime" == 0 ]
    then
        echo "The script will continue now ..."
    else
        echo "You have $priorWaitTime seconds to abort the script (^C) ..."
    fi
    sleep "$priorWaitTime"
fi

#ask license question
if [ "$silent" == 0 ] && [ "$license" == 0 ]
then
    cont "ask" "Do you agree with the license terms?" "Any further execution requires acceptance of the licensing terms ..."
fi

#set standards
if [ "$install" == 0 ] && [ "$uninstall" == 0 ] && [ "$update" == 0 ]
then
    install=1
fi

if [ "$enabler" == 0 ] && [ "$driver" == 0 ] && [ "$cuda" == 0 ]
then
    determine=1
fi

#define system info functions
function fetchOSinfo {
    os="$(sw_vers -productVersion)"
    build="$(sw_vers -buildVersion)"
}

function fetchSIPstat {
    SIP="$(csrutil status)"
    if [ "${SIP: -2}" == "d." ]
    then
        SIP="${SIP::37}"
        SIP="${SIP: -1}"
        case "$SIP"
        in
        "e")
            statSIP=127
            ;;
        "d")
            statSIP=0
            ;;
        *)
            statSIP=128
            ;;
        esac
    else
        SIP1="${SIP::102}"
        SIP1="${SIP1: -1}"
        SIP2="${SIP::126}"
        SIP2="${SIP2: -1}"
        SIP3="${SIP::160}"
        SIP3="${SIP3: -1}"
        SIP4="${SIP::193}"
        SIP4="${SIP4: -1}"
        SIP5="${SIP::223}"
        SIP5="${SIP5: -1}"
        SIP6="${SIP::251}"
        SIP6="${SIP6: -1}"
        SIP7="${SIP::285}"
        SIP7="${SIP7: -1}"
        p=1
        statSIP=0
        for SIPX in "$SIP7" "$SIP6" "$SIP5" "$SIP4" "$SIP3" "$SIP2" "$SIP1"
        do
            if [ "$SIPX" == "e" ]
            then
                statSIP="$(expr $statSIP + $p)"
            fi
            p="$(expr $p \* 2)"
        done
    fi
}

#execute and check if script is compatible with os
fetchOSinfo
case "${os::5}"
in
    "10.12")
        ;;
    "10.13")
        ;;
    "10.14")
        iruptError "toNewOS"
        ;;
    *)
        iruptError "unsupOS"
        ;;
esac

fetchSIPstat
if [ "$statSIP" != 31 ] && [ "$statSIP" != 128 ]
then
    iruptError "SIP"
elif [ "$statSIP" == 128 ]
then
    iruptError "SIPerror"
fi


#define software check function
function checkCudaInstall {
    if [ -f "$cudaVersionPath" ]
    then
        cudaVersionInstalled=1
        cudaVersionFull="$(cat $cudaVersionPath)"
        cudaVersionFull="${cudaVersionFull##CUDA Version }"
        cudaVersion="${cudaVersionFull%.*}"
    fi
    if [ -d "$cudaDeveloperDirPath" ]
    then
        cudaDirContent="$(ls $cudaDeveloperDirPath)"
        while read -r folder
        do
            if [ "${folder%%-*}" == "CUDA" ]
            then
                cudaVersionsInstalled=$(echo -e "$cudaVersionsInstalled""${folder#CUDA-};")
            fi
        done <<< "$cudaDirContent"
        cudaVersionsInstalled="${cudaVersionsInstalled%;}"
        cudaVersionsInstalled="${cudaVersionsInstalled//;/\n}"
        cudaVersionsInstalled="$(echo -e $cudaVersionsInstalled)"
        cudaVersions="$(echo $cudaVersionsInstalled | wc -l | xargs)"
        if [ "$cudaVersionInstalled" == 1 ]
        then
            cudaToolkitUnInstallDir="/Developer/NVIDIA/CUDA-""$cudaVersion""/bin/"
            cudaToolkitUnInstallScript="uninstall_cuda_""$cudaVersion"".pl"
            cudaToolkitUnInstallScriptPath="$cudaToolkitUnInstallDir""$cudaToolkitUnInstallScript"
            cudaSamplesDirPath="/Developer/NVIDIA/CUDA-""$cudaVersion""/samples/"
            if [ -d "$cudaSamplesDirPath" ]
            then
                cudaSamplesInstalled=1
            fi
            if [ -f "$cudaToolkitUnInstallScriptPath" ]
            then
                cudaToolkitInstalled=1
            fi
        fi
    fi
    if [ -f "$cudaDriverUnInstallScriptPath" ]
    then
        cudaDriverInstalled=1
    fi
}

function checkNvidiaDriverInstall {
    if [ -f "$nvidiaDriverUnInstallPath" ]
    then
        nvidiaDriversInstalled=1
        nvidiaDriverVersion=$("$pbuddy" -c "Print CFBundleGetInfoString" "$nvidiaDriverVersionPath")
        nvidiaDriverVersion="${nvidiaDriverVersion##* }"
        nvidiaDriverBuildVersion=$("$pbuddy" -c "Print IOKitPersonalities:NVDAStartup:NVDARequiredOS" "$nvidiaDriverVersionPath")
    fi
}

function checkAutomateeGPUInstall {
    if [ -d "$automateeGPUPath" ] || [ -f "$automateeGPUScriptPath" ]
    then
        automateeGPUInstalled=1
    fi
}

function checkeGPUEnablerInstall {
    if [ -f "$enablerKextPath" ]
    then
        eGPUenablerInstalled=1
        eGPUenablerBuildVersion=$("$pbuddy" -c "Print IOKitPersonalities:NVDAStartup:NVDARequiredOS" "$eGPUBuildVersionPath")
    fi
}

function fetchInstalledSoftware {
    checkCudaInstall
    checkNvidiaDriverInstall
    checkAutomateeGPUInstall
    checkeGPUEnablerInstall
}


#define uninstallers
function uninstallAutomateeGPU {
    checkAutomateeGPUInstall
    if [ "$automateeGPUInstalled" == 1 ]
    then
        echo
        echo "Downloading and preparing goalque's automate-eGPU script ..."
        mktmpdir
        curl -o "$dirName"/automate-eGPU.sh "$automateeGPUScriptPath"
        cd "$dirName"/
        chmod +x automate-eGPU.sh
        echo "Executing goalque's automate-eGPU script with elevated privileges and uninstall parameter..."
###        sudo ./automate-eGPU.sh -uninstall
        rm automate-eGPU.sh
        scheduleReboot=1
        doneSomething=1
        installedEnabler=-1
    else
        contError "noEnabler"
    fi
}

function uninstallCuda {
    checkCudaInstall
    if [[ "$cudaVersions" > 1 ]]
    then
        contError "cudaVersion"
        if [ -f "$cudaDriverUnInstallScriptPath" ]
        then
            echo "Uninstalling CUDA Drivers (elevated privileges needed)"
###            sudo perl "$cudaDriverUnInstallScriptPath"
            installedCudaDriver=-1
            doneSomething=1
        else
            contError "unCudaDriver"
        fi
        checkCudaInstall
        while read -r version
        do
            cudaVersion="$version"
            cudaToolkitUnInstallDir="/Developer/NVIDIA/CUDA-""$cudaVersion""/bin/"
            cudaToolkitUnInstallScript="uninstall_cuda_""$cudaVersion"".pl"
            cudaToolkitUnInstallScriptPath="$cudaToolkitUnInstallDir""$cudaToolkitUnInstallScript"
            if [ -f "$cudaToolkitUnInstallScriptPath" ]
            then
                echo "Uninstalling CUDA $version toolkit and samples (elevated privileges needed)"
###                sudo perl "$cudaToolkitUnInstallScriptPath"
                installedCudaToolkit=-1
                doneSomething=1
            else
                echo "Unable to uninstall CUDA $version."
            fi
        done <<< "$cudaVersionsInstalled"
    else
        if [ "$cuda" == 1 ] || [ "$cuda" == 2 ]
        then
            if [ "$cudaToolkitInstalled" == 1 ]
            then
                echo "Uninstalling CUDA toolkit and samples (elevated privileges needed)"
###                sudo perl "$cudaToolkitUnInstallScriptPath"
                installedCudaToolkit=-1
                doneSomething=1
            else
                contError "unCudaSamples"
                contError "unCudaToolkit"
            fi
            if [ -f "$cudaDriverUnInstallScriptPath" ]
            then
                echo "Uninstalling CUDA Drivers (elevated privileges needed)"
###                sudo perl "$cudaDriverUnInstallScriptPath"
                installedCudaDriver=-1
                doneSomething=1
            else
                contError "unCudaDriver"
            fi
        fi
        if [ "$cuda" == 3 ]
        then
            if [ "$cudaToolkitInstalled" == 1 ]
            then
                echo "Uninstalling CUDA toolkit and samples (elevated privileges needed)"
###                sudo perl "$cudaToolkitUnInstallScriptPath"
                installedCudaToolkit=-1
                doneSomething=1
            else
                contError "unCudaSamples"
                contError "unCudaToolkit"
            fi
        fi
        if [ "$cuda" == 4 ]
        then
            if [ "$cudaToolkitInstalled" == 1 ] && [ "$cudaSamplesInstalled" == 1 ]
            then
                echo "Uninstalling CUDA samples (elevated privileges needed)"
                cd "$cudaToolkitUnInstallDir"
###                sudo perl "$cudaToolkitUnInstallScriptPath" --manifest=.cuda_samples_uninstall_manifest_do_not_delete.txt
                installedCudaSamples=-1
                doneSomething=1
            else
                contError "unCudaSamples"
            fi
        fi
    fi
}

function uninstallEnabler {
    checkeGPUEnablerInstall
    if [ "$eGPUenablerInstalled" == 1 ]
    then
        echo
        echo "Removing enabler (elevated privileges needed) ..."
###        sudo rm "$enablerKextPath"
        installedEnabler=-1
        scheduleReboot=1
        doneSomething=1
    else
        contError "unEnabler"
    fi
}

function uninstallNvidiaDriver {
    checkNvidiaDriverInstall
    if [ "$nvidiaDriversInstalled" == 1 ]
    then
        echo
        echo "Executing NVIDIA Driver uninstaller with elevated privileges ..."
###        sudo installer -pkg "$nvidiaDriverUnInstallPath" -target /
        installedNvidiaDrivers=-1
        scheduleReboot=1
        doneSomething=1
    else
        contError "unNvidiaDriver"
    fi
}

function unInstalleGPUSupport {
    checkeGPUEnablerInstall
    checkAutomateeGPUInstall
    if [ "$eGPUenablerInstalled" == 1 ]
    then
        uninstallEnabler
    elif [ "$automateeGPUInstalled" == 1 ]
    then
        uninstallAutomateeGPU
    else
        contError "unEnabler"
    fi
}

#define installers
function installAutomateeGPU {
    checkAutomateeGPUInstall
    checkeGPUEnablerInstall
    if [ "$eGPUenablerInstalled" == 1 ]
    then
        uninstallEnabler
    fi
    if [ "$automateeGPUInstalled" == 1 ]
    then
        echo "eGPU is already enabled."
        echo "If it does not work, try uninstalling first."
    else
        echo
        echo "Downloading and preparing goalque's automate-eGPU script ..."
        mktmpdir
        curl -o "$dirName"/automate-eGPU.sh "$automateeGPUScriptPath"
        cd "$dirName"
        chmod +x automate-eGPU.sh
        echo "Executing goalque's automate-eGPU script with elevated privileges ..."
        if [ "$minimal" == 1 ]
        then
###            sudo ./automate-eGPU.sh -a -skip-web-driver
        else
###            sudo ./automate-eGPU.sh -skip-web-driver
        fi
        rm automate-eGPU.sh
        scheduleReboot=1
        doneSomething=1
        installedEnabler=1
    fi
}

function installCudaDriver {
    checkCudaInstall
    if [[ "$cudaVersions" > 1 ]]
    then
        uninstallCuda
    fi
    checkCudaInstall
    mktmpdir
    curl -o "$dirName""/cudaDriverList.plist" "$cudaDriverListOnline"
    cudaDriverList="$dirName""/cudaDriverList.plist"
    drivers=$("$pbuddy" -c "Print $forceNew:" "$cudaDriverList" | grep "OS" | awk '{print $3}')
    driverCount=$(echo "$drivers" | wc -l | xargs)
    foundMatch=false
    for index in `seq 0 $(expr $driverCount - 1)`
    do
        osTemp=$("$pbuddy" -c "Print $forceNew:$index:OS" "$cudaDriverList")
        cudaDriverPathTemp=$("$pbuddy" -c "Print $forceNew:$index:downloadURL" "$cudaDriverList")
        cudaDriverVersionTemp=$("$pbuddy" -c "Print $forceNew:$index:version" "$cudaDriverList")

        if [ "${os::5}" == "$osTemp" ]
        then
            cudaDriverDPath="$cudaDriverPathTemp"
            cudaDownloadVersion="$cudaDriverVersionTemp"
            foundMatch=true
        fi
    done
    rm "$cudaDriverList"
    if "$foundMatch"
    then
        if [ "$cudaDownloadVersion" == "$cudaVersionFull" ]
        then
            echo "CUDA drivers are up to date."
        else
            echo
            echo "Downloading and preparing cuda installer ..."
            curl -o "$dirName"/cudaDriver.dmg "$cudaDriverDPath"
            hdiutil attach "$dirName"/cudaDriver.dmg
            echo "Executing cuda installer with elevated privileges ..."
###            sudo installer -pkg "$cudaDriverVolPath""$cudaDriverPKGName" -target /
            hdiutil detach "$cudaDriverVolPath"
            rm "$dirName"/cudaDriver.dmg
            scheduleReboot=1
            doneSomething=1
            installedCudaDriver=1
        fi
    else
        errorCont "noCUDAdriver"
    fi
}

function installCudaToolkit {
    checkCudaInstall
    if [[ "$cudaVersions" > 1 ]]
    then
        uninstallCuda
    fi
    checkCudaInstall
    mktmpdir
    curl -o "$dirName""/cudaDriverList.plist" "$cudaToolkitListOnline"
    cudaToolkitList="$dirName""/cudaDriverList.plist"
    drivers=$("$pbuddy" -c "Print $forceNew:" "$cudaToolkitList" | grep "OS" | awk '{print $3}')
    driverCount=$(echo "$drivers" | wc -l | xargs)
    foundMatch=false
    for index in `seq 0 $(expr $driverCount - 1)`
    do
        osTemp=$("$pbuddy" -c "Print $forceNew:$index:OS" "$cudaToolkitList")
        cudaToolkitPathTemp=$("$pbuddy" -c "Print $forceNew:$index:downloadURL" "$cudaToolkitList")
        cudaToolkitVersionTemp=$("$pbuddy" -c "Print $forceNew:$index:version" "$cudaToolkitList")

        if [ "${os::5}" == "$osTemp" ]
        then
            cudaToolkitDPath="$cudaDriverPathTemp"
            cudaDownloadVersion="$cudaDriverVersionTemp"
            foundMatch=true
        fi
    done
    rm "$cudaDriverList"
    if "$foundMatch"
    then
        if [ "$cudaDownloadVersion" == "$cudaVersionFull" ]
        then
            echo "CUDA drivers are up to date."
        else
            echo
            echo "Downloading and preparing cuda installer ..."
            curl -o "$dirName"/cudaToolkit.dmg "$cudaToolkitDPath"
            hdiutil attach "$dirName"/cudaToolkit.dmg
            echo "Executing cuda toolkit installer with elevated privileges ..."
            if [ "$cuda" == 2 ]
            then
###                sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-driver"
            fi
            if [ "$cuda" == 3 ]
            then
###                sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-driver" --install-package="cuda-toolkit"
            fi
            if [ "$cuda" == 4 ]
            then
###                sudo "$cudaToolkitVolPath""$cudaToolkitPKGName" --accept-eula --silent --no-window --install-package="cuda-driver" --install-package="cuda-toolkit" --install-package="cuda-samples"
            fi
            hdiutil detach "$cudaToolkitVolPath"
            rm "$dirName"/cudaToolkit.dmg
            scheduleReboot=1
            doneSomething=1
            installedCudaToolkit=1
        fi
    else
        errorCont "noCUDAdriver"
    fi
}

function installCuda {
    if [ "$cuda" == 1 ]
    then
        installCudaDriver
    fi
    if [[ "$cuda" > 1 ]]
    then
        installCudaToolkit
    fi
}

function installNvidiaDriver {
    checkNvidiaDriverInstall
    if [ "$forceNew" == "newest" ]
    then
        echo "Fetching newest driver information ..."
        mktmpdir
        curl -o "$dirName""/nvidiaDriver.plist" "$nvidiaDriverListOnline"
        nvidiaDriverList="$dirName""/nvidiaDriver.plist"
        drivers=$("$pbuddy" -c "Print updates:" "$nvidiaDriverList" | grep "OS" | awk '{print $3}')
        driverCount=$(echo "$drivers" | wc -l | xargs)
        for index in `seq 0 $(expr $driverCount - 1)`
        do
            buildTemp=$("$pbuddy" -c "Print updates:$index:OS" "$nvidiaDriverList")
            nvidiaDriverVersionTemp=$("$pbuddy" -c "Print updates:$index:version" "$nvidiaDriverList")

            if [ "$build" == "$buildTemp" ]
            then
                nvidiaDriverDownloadVersion="$nvidiaDriverVersionTemp"
                foundMatch=true
            fi
        done
        rm "$nvidiaDriverList"
        if "$foundMatch"
        then
            if [ "$nvidiaDriversInstalled" == 1 ]
            then
                if [ "$nvidiaDriverBuildVersion" == "$build" ] && [ "$nvidiaDriverDownloadVersion" == "$nvidiaDriverVersion" ]
                then
                    echo "The best nvidia driver is already installed."
                else
###                    bash <(curl -s "$nvidiaUpdateScriptDPath") --force "$nvidiaDriverDownloadVersion"
                    doneSomething=1
                    installedNvidiaDrivers=1
                    scheduleReboot=1
                fi
            else
###                bash <(curl -s "$nvidiaUpdateScriptDPath") --force "$nvidiaDriverDownloadVersion"
                doneSomething=1
                installedNvidiaDrivers=1
                scheduleReboot=1
            fi
        else
            contError "noNvidiaDriver"
###            bash <(curl -s "$nvidiaUpdateScriptDPath")
            doneSomething=1
            installedNvidiaDrivers=1
            scheduleReboot=1
        fi
    else
        if [ "$nvidiaDriversInstalled" == 1 ]
        then
            nvidiaDriverVersionTemp="$nvidiaDriverVersion"
###            bash <(curl -s "$nvidiaUpdateScriptDPath")
            checkNvidiaDriverInstall
            if [ "$nvidiaDriverVersionTemp" != "$nvidiaDriverVersion" ]
            then
                doneSomething=1
                installedNvidiaDrivers=1
                scheduleReboot=1
            fi
        else
###            bash <(curl -s "$nvidiaUpdateScriptDPath")
            doneSomething=1
            installedNvidiaDrivers=1
            scheduleReboot=1
        fi
    fi
}

function enablerInstaller {
    echo "Fetching newest enabler information ..."
    mktmpdir
    curl -o "$dirName""/eGPUenabler.plist" "$eGPUEnablerListOnline"
    eGPUEnablerList="$dirName""/eGPUenabler.plist"
    enablers=$("$pbuddy" -c "Print updates:" "$eGPUEnablerList" | grep "OS" | awk '{print $3}')
    enablerCount=$(echo "$enablers" | wc -l | xargs)
    for index in `seq 0 $(expr $enablerCount - 1)`
    do
        buildTemp=$("$pbuddy" -c "Print updates:$index:build" "$eGPUEnablerList")
        authorTemp=$("$pbuddy" -c "Print updates:$index:author" "$eGPUEnablerList")
        pkgNameTemp=$("$pbuddy" -c "Print updates:$index:packageName" "$eGPUEnablerList")
        eGPUEnablerDPathTemp=$("$pbuddy" -c "Print updates:$index:downloadURL" "$eGPUEnablerList")
        if [ "$build" == "$buildTemp" ]
        then
            eGPUEnablerDPath="$eGPUEnablerDPathTemp"
            eGPUEnablerAuthor="$authorTemp"
            eGPUEnablerPKGName="$pkgNameTemp"
            foundMatch=true
        fi
    done
    rm "$eGPUEnablerList"
    if "$foundMatch"
    then
        echo "Downloading and installing ""$eGPUEnablerAuthor""'s eGPU-enabler ..."
        curl -o "$dirName""/NVDAEGPU.zip" "$eGPUEnablerDPath"
        unzip "$dirName""/NVDAEGPU.zip" -d "$dirName""/"
        rm "$dirName""/NVDAEGPU.zip"
###        sudo installer -pkg "$dirName""/""$eGPUEnablerPKGName" -target /
        rm "$dirName""/""$eGPUEnablerPKGName"
        scheduleReboot=1
        doneSomething=1
        installedEnabler=1
    fi
}

function installEnabler {
    checkAutomateeGPUInstall
    checkeGPUEnablerInstall
    if [ "$automateeGPUInstalled" == 1 ]
    then
        echo "Removing previous eGPU enablers ..."
        uninstallAutomateeGPU
    fi
    if [ "$eGPUenablerInstalled" == 1 ]
    then
        if [ "$eGPUenablerBuildVersion" == "$build" ]
        then
            echo "The matching eGPU enabler is already installed."
        else
            enablerInstaller
        fi
    else
        enablerInstaller
    fi
}

function installeGPUSupport {
    case "${os::5}"
    in
    "10.12")
        installAutomateeGPU
        ;;
    "10.13")
        installEnabler
        ;;
    *)
        ;;
    esac
}


function fetchInstalledProgramms {
    echo "Fetching installed apps. This might take a few moments ..."
    appListPaths="$(find /Applications/ -iname *.app)"
    appList=""
    while read -r app
    do
        appTemp="${app##*/}"
        appList="$appList""${appTemp%.*}"";"
    done <<< "$appListPaths"
    appList="${appList%;}"
    appList="${appList//;/\n}"
    programmList="$(echo -e $appList)"
}

function deduceCudaNeedsInstall {
    fetchInstalledProgramms
    echo "Fetching CUDA requiring apps ..."
    mktmpdir
    curl -o "$dirName""/CUDAApp.plist" "$CUDAAppListOnline"
    CUDAAppList="$dirName""/CUDAApp.plist"
    apps=$("$pbuddy" -c "Print updates:" "$CUDAAppList" | grep "OS" | awk '{print $3}')
    appCount=$(echo "$apps" | wc -l | xargs)
    for index in `seq 0 $(expr $appCount - 1)`
    do
        appNameTemp=$("$pbuddy" -c "Print apps:$index:name" "$CUDAAppList")
        driverNeedsTemp=$("$pbuddy" -c "Print apps:$index:requirement" "$CUDAAppList")
        if [ "$programmList[@]" =~ "$appNameTemp" ]
        then
            case "$driverNeedsTemp"
            in
            "driver")
                if [ "$cuda" == 0 ]
                then
                    cuda=1
                fi
                ;;
            "toolkit")
                if [[ "$cuda" < 3 ]]
                then
                    cuda=3
                fi
                ;;
            *)
                ;;
            esac
        fi
    done
}

function deduceUserWish {
    fetchInstalledSoftware
    if [ "$determine" == 1 ]
    then
        if [ "$install" == 1 ]
        then
            enabler=1
            driver=1
            if [ "$minimal" == 0 ]
            then
                deduceCudaNeedsInstall
            fi
        elif [ "$update" == 1 ]
        then
            if [ "$eGPUenablerInstalled" == 1 ]
            then
                enabler=1
            fi
            if [ "$nvidiaDriversInstalled" == 1 ]
            then
                driver=1
            fi
            if [ "$cudaDriverInstalled" == 1 ]
            then
                cuda=1
            fi
            if [ "$cudaToolkitInstalled" == 1 ]
            then
            cuda=3
            fi
            if [ "$cudaSamplesInstalled" == 1 ]
            then
                cuda=4
            fi
        elif [ "$uninstall" == 1 ]
            if [ "$eGPUenablerInstalled" == 1 ]
            then
                enabler=1
            fi
            if [ "$nvidiaDriversInstalled" == 1 ]
            then
                driver=1
            fi
            if [ "$cudaDriverInstalled" == 1 ]
            then
                cuda=1
            fi
            if [ "$cudaToolkitInstalled" == 1 ]
            then
                cuda=3
            fi
            if [ "$cudaSamplesInstalled" == 1 ]
            then
                cuda=4
            fi
        else
            iruptError "unex"
        fi
    fi
}

deduceUserWish

if [ "$enabler" == 1 ]
then
    if [ "$install" == 1 ] || [ "$uninstall" == 1 ]
    then
        installeGPUSupport
    elif [ "$uninstall" == 1 ]
    then
        unInstalleGPUSupport
    else
        iruptError "unex"
    fi
fi

if [ "$driver" == 1 ]
then
    if [ "$install" == 1 ] || [ "$uninstall" == 1 ]
    then
        installNvidiaDriver
    elif [ "$uninstall" == 1 ]
    then
        uninstallNvidiaDriver
    else
        iruptError "unex"
    fi
fi

if [ "$cuda" != 0 ]
then
    if [ "$install" == 1 ] || [ "$uninstall" == 1 ]
    then
        installCuda
    elif [ "$uninstall" == 1 ]
    then
        uninstallCuda
    else
        iruptError "unex"
    fi
fi








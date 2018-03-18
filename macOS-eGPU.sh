#!/bin/bash
#
#Authors: learex
#Homepage: https://github.com/learex/macOS-eGPU
#License: https://github.com/learex/macOS-eGPU/License.text
#
#USAGE TERMS of macOS-eGPU.sh
#1. You may use this script for personal use.
#2. You may continue development of this script at it's GitHub homepage.
#3. You may not redistribute this script from outside of it's GitHub homepage.
#4. You may not use this script, or portions thereof, for any commercial purposes.
#5. You accept the license terms of all downloaded and/or executed content, even content that has not been downloaded and/or executed by macOS-eGPU.sh directly.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

clear

#display warning
echo "The system will reboot after completion."
read -p "Do you agree with the license terms and do you know that your system will automatically reboot? [y]es [n]o "  -n 1 -r
echo
if [ "$REPLY" != "y" ]
then
    echo
    echo "The script has stopped. Nothing has been changed."
    exit
fi

echo
echo

#set all given input parameters
install=0
uninstall=0
enabler=0
driver=0
cuda=0
for options in "$@"
do
    case "$options"
    in
    "-install")
        if [ "$uninstall" == 1 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit
        fi
        install=1
        ;;
    "-uninstall")
        if [ "$install" == 1 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit
        fi
        uninstall=1
        ;;
    "-driver")
        driver=1
        ;;
    "-enabler")
        enabler=1
        ;;
    "-cuda")
        if [ "$cuda" != 0 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit          
        fi
        cuda=1
        ;;
    "-cudaD")
        if [ "$cuda" != 0 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit          
        fi
        cuda=2
        ;;
    "-cudaT")
        if [ "$cuda" != 0 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit          
        fi
        cuda=3
        ;;
    "-cudaS")
        if [ "$cuda" != 0 ]
        then
            echo "Conflicting arguments."
            echo "The script has failed. Nothing has been changed."
            exit          
        fi
        cuda=4
        ;;
    *)
        echo
        echo "unkown argument given"
        echo "The script has failed. Nothing has been changed."
        exit
        ;;
    esac
done

#set standards
if [ "$install" == 0 ] && [ "$uninstall" == 0 ]
then
    install=1
fi

if [ "$enabler" == 0 ] && [ "$driver" == 0 ] && [ "$cuda" == 0 ]
then
    enabler=1
    driver=1
fi

echo
echo

echo "Fetching system information ..."
#fetch system information
os="$(sw_vers -productVersion)"
build="$(sw_vers -buildVersion)"

#fetch SIP status
#SIP config:
#Apple Internal | Kext Signing | Filesystem Protections | Debugging Restrictions | DTrace Restrictions | NVRAM Protections | BaseSystem Verification
#So to encode as between a decimal 0-127
#0:   fully disabled
#127: fully enabled
#128: error
statSIP="$(csrutil status)"
if [ "${statSIP: -2}" == "d." ]
then
    statSIP="${statSIP::37}"
    statSIP="${statSIP: -1}"
    case "$statSIP"
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
    SIP1="${statSIP::102}"
    SIP1="${SIP1: -1}"
    SIP2="${statSIP::126}"
    SIP2="${SIP2: -1}"
    SIP3="${statSIP::160}"
    SIP3="${SIP3: -1}"
    SIP4="${statSIP::193}"
    SIP4="${SIP4: -1}"
    SIP5="${statSIP::223}"
    SIP5="${SIP5: -1}"
    SIP6="${statSIP::251}"
    SIP6="${SIP6: -1}"
    SIP7="${statSIP::285}"
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

#check SIP
if [ "$statSIP" != 31 ]
then
    echo
    echo
    echo "The script has failed. Nothing has been changed."
    echo "System Integrity Protection (SIP) is not set correctly."
    echo "Please boot into recovery mode and execute:"
    echo "csrutil enable --without kext; reboot;"
    exit
fi

scheduleReboot=0
#define functions
function unsupportedError {
    echo
    echo
    if [ "$1" == "param" ]
    then
        echo "This parameter configuration is currently unsupported."
    fi
    if [ "$1" == "HSUpdate" ]
    then
        echo "You have an unsupported build of macOS High Sierra."
        echo "This may change in the future, so try again in a few days."
    fi
    if [ "$1" == "unex" ]
    then
        echo "An unexpected error has occured."
    fi
    if [ "$1" == "unsupOS" ]
    then
        echo "Your OS is not supported by this script."
    fi
    echo "The script has failed."
    if [ "$scheduleReboot" == 1 ]
    then
        echo "Some configurations have been changed."
    else
        echo "Nothing has been changed."
    fi
    exit
}

function installAutomateeGPU {
    echo
    echo "Downloading and preparing goalque's automate-eGPU script ..."
    curl -o ~/Desktop/automate-eGPU.sh https://raw.githubusercontent.com/goalque/automate-eGPU/master/automate-eGPU.sh
    cd ~/Desktop/
    chmod +x automate-eGPU.sh
    echo "Executing goalque's automate-eGPU script with elevated privileges ..."
    sudo ./automate-eGPU.sh
    rm automate-eGPU.sh
    scheduleReboot=1
}

function installNvidiaDriver {
    echo
    echo "Downloading and executing Benjamin Dobell's nvidia-driver script ..."
    bash <(curl -s https://raw.githubusercontent.com/Benjamin-Dobell/nvidia-update/master/nvidia-update.sh)
    scheduleReboot=1
}

function downloadCudaDriver {
    case "${os::5}"
    in
    "10.12")
        curl -o ~/Desktop/cudaDriver.dmg http://us.download.nvidia.com/Mac/cuda_387/cudadriver_387.99_macos.dmg
        ;;
    "10.13")
        curl -o ~/Desktop/cudaDriver.dmg http://us.download.nvidia.com/Mac/cuda_387/cudadriver_387.128_macos.dmg
        ;;
    *)
        unsupportedError "unsupOS"
        ;;
    esac
}

function installCudaDriver {
    echo
    echo "Downloading and preparing cuda installer ..."
    downloadCudaDriver
    hdiutil attach ~/Desktop/cudaDriver.dmg
    echo "Executing cuda installer with elevated privileges ..."
    sudo installer -pkg /Volumes/CUDADriver/CUDADriver.pkg -target /
    hdiutil detach /Volumes/CUDADriver/
    rm ~/Desktop/cudaDriver.dmg
    scheduleReboot=1
}

function downloadCudaToolkit {
    case "${os::5}"
    in
    "10.12")
        curl -o ~/Desktop/cudaToolkit.dmg -L https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_mac-dmg
        ;;
    "10.13")
        curl -o ~/Desktop/cudaToolkit.dmg -L https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.128_mac
        ;;
    *)
        unsupportedError "unsupOS"
        ;;
    esac
}

function installCudaToolkit {
    echo
    echo "Downloading and preparing cuda toolkit installer ... (~1.5GB)"
    downloadCudaToolkit
    hdiutil attach ~/Desktop/cudaToolkit.dmg
    echo "Executing cuda toolkit installer with elevated privileges ..."
    sudo installer -pkg /Volumes/CUDADriver/CUDADriver.pkg -target /
    if [ "$cuda" == 2 ]
    then
    sudo /Volumes/CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller --accept-eula --silent --no-window --install-package="cuda-driver"
    fi
    if [ "$cuda" == 3 ]
    then
        sudo /Volumes/CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller --accept-eula --silent --no-window --install-package="cuda-driver" --install-package="cuda-toolkit"
    fi
    if [ "$cuda" == 4 ]
    then
        sudo /Volumes/CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller --accept-eula --silent --no-window --install-package="cuda-driver" --install-package="cuda-toolkit" --install-package="cuda-samples"
    fi
    hdiutil detach /Volumes/CUDAMacOSXInstaller/
    rm ~/Desktop/cudaToolkit.dmg
    scheduleReboot=1
}

function installCuda {
    if [ "$cuda" == 1 ]
    then
        installCudaDriver
    fi
    if [ "$cuda" > 1 ]
    then
        installCudaToolkit
    fi
}

function installEnabler {
    case "$build"
    in
    "17D102")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4587-NVDAEGPUSupport-v7.zip"
        appName="NVDAEGPUSupport-v7.pkg"
        author="devild"
        ;;
    "17D47")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/71/4376-NVDAEGPUSupport-v6.zip"
        appName="NVDAEGPUSupport-v6.pkg"
        author="devild"
        ;;
    "17C205")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/71/4316-NVDAEGPUSupport-v4-SU.zip"
        appName="NVDAEGPUSupport-v4-SU.pkg"
        author="devild"
        ;;
    "17C89")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/71/4089-nvidia-egpu-v4-cu.zip"
        appName="NVDAEGPUSupport-v4-CU.pkg"
        author="devild"
        ;;
    "17C88")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/71/4035-nvidia-egpu-v4.zip"
        appName="NVDAEGPUSupport-v4.pkg"
        author="devild"
        ;;
    "17B1003")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/5991/4015-3858-nvidia-egpu-v3-1013-1.zip"
        appName="NVDAEGPUSupport.pkg"
        author="ricosuave0922"
        ;;
    "17B48")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/3/3858-nvidia-egpu-v2-1013-1.zip"
        appName="NVDAEGPUSupport-v2.pkg"
        author="devild"
        ;;
    "17A405")
        downPath="https://cdn.egpu.io/wp-content/uploads/wpforo/attachments/3/3857-nvidia-egpu-v1-1013.zip"
        appName="NVDAEGPUSupport-v1.pkg"
        author="devild"
        ;;
    "17D2104")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4687-NVDAEGPUSupport-iMacPro-2104pkg.zip"
        appName="NVDAEGPUSupport-iMacPro-2104.pkg"
        author="devild"
        ;;
    "17D2102")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4588-NVDAEGPUSupport-iMacPro-2102.zip"
        appName="NVDAEGPUSupport-iMacPro-2102.pkg"
        author="devild"
        ;;
    "17D2047")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4377-NVDAEGPUSupport-iMacPro-2047.zip"
        appName="NVDAEGPUSupport-iMacPro-2047.pkg"
        author="devild"
        ;;
    "17C2205")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4361-NVDAEGPUSupport-iMacPro-2205.zip"
        appName="NVDAEGPUSupport-iMacPro-2205.pkg"
        author="devild"
        ;;
    "17C2120")
        downPath="https://egpu.io/wp-content/uploads/wpforo/attachments/71/4174-NVDAEGPUSupport-iMacPro-2120.zip"
        appName="NVDAEGPUSupport-iMacPro-2120.pkg"
        author="devild"
        ;;
    *)
        unsupportedError "HSUpdate"
        ;;
    esac
    echo
    echo "Downloading and installing ""$author""'s eGPU-enabler ..."
    curl -o ~/Desktop/NVDAEGPU.zip "$downPath"
    unzip ~/Desktop/NVDAEGPU.zip -d ~/Desktop/
    rm ~/Desktop/NVDAEGPU.zip
    sudo installer -pkg ~/Desktop/$appName -target /
    rm ~/Desktop/$appName
    scheduleReboot=1
}

function uninstallAutomateeGPU {
    echo
    echo "Downloading and preparing goalque's automate-eGPU script ..."
    curl -o ~/Desktop/automate-eGPU.sh https://raw.githubusercontent.com/goalque/automate-eGPU/master/automate-eGPU.sh
    cd ~/Desktop/
    chmod +x automate-eGPU.sh
    echo "Executing goalque's automate-eGPU script with elevated privileges and uninstall parameter..."
    sudo ./automate-eGPU.sh -uninstall
    rm automate-eGPU.sh
    scheduleReboot=1
}

function uninstallNvidiaDriver {
    echo
    echo "Executing NVIDIA Driver uninstaller with elevated privileges ..."
    sudo installer -pkg /Library/PreferencePanes/NVIDIA\ Driver\ Manager.prefPane/Contents/MacOS/NVIDIA\ Web\ Driver\ Uninstaller.app/Contents/Resources/NVUninstall.pkg -target /
    scheduleReboot=1
}

fuction uninstallCudaDriver {
    echo
    echo "Executing cuda driver uninstall script with elevated privileges ..."
    sudo perl /usr/local/bin/uninstall_cuda_drv.pl
    scheduleReboot=1
}

fuction uninstallCudaToolkit {
    cudaVersion="$(cat /usr/local/cuda/version.txt)"
    cudaVersion="${cudaVersion::16}"
    cudaVersion="${cudaVersion: -3}"
    if [ "$cuda" > 3 ]
    then
        echo "Executing cuda samples uninstall script with elevated privileges ..."
        cd /Developer/NVIDIA/CUDA-$cudaVersion/bin/
        sudo perl uninstall_cuda_$cudaVersion.pl --manifest=.cuda_samples_uninstall_manifest_do_not_delete.txt
    else
        if [ "$cuda" > 2 ]
        then
            echo "Executing cuda toolkit uninstall script with elevated privileges (samples will be uninstalled as well) ..."
            sudo perl /Developer/NVIDIA/CUDA-$cudaVersion/bin/uninstall_cuda_$cudaVersion.pl
        else
            if [ "$cuda" > 1 ]
            then
                echo "Executing all cuda uninstall scripts with elevated privileges (samples & toolkit & driver) ..."
                sudo perl /usr/local/bin/uninstall_cuda_drv.pl
                sudo perl /Developer/NVIDIA/CUDA-$cudaVersion/bin/uninstall_cuda_$cudaVersion.pl
            else
                unsupportedError "unex"
            fi
        fi
    fi
}

function uninstallCuda {
    if [ "$cuda" == 1 ]
    then
        uninstallCudaDriver
    fi
    if [ "$cuda" > 1 ]
    then
        uninstallCudaToolkit
    fi
}

function uninstallEnabler {
    echo
    echo "Removing enabler (elevated privileges needed) ..."
    sudo rm /Library/Extensions/NVDAEGPUSupport.kext
    scheduleReboot=1
}

#check if system is compatible with script and execute commands
case "${os::5}"
in
"10.12")
    echo "macOS 10.12 Sierra (build: $build) has been detected"
    if [ "$install" == 1 ]
    then
        if [ "$driver" == 1 ] && [ "$enabler" == 1 ]
        then
            installAutomateeGPU
        else
            if [ "$driver" == 1 ]
            then
                installNvidiaDriver
            else
                if [ "$enabler" == 1 ]
                then
                    unsupportedError "param"
                fi
            fi
        fi
        if [ "$cuda" != 0 ]
        then
            installCuda
        fi
    else
        if [ "$uninstall" == 1 ]
        then
            if [ "$enabler" == 1 ]
            then
                uninstallAutomateeGPU
            fi
            if [ "$driver" == 1 ]
            then
                uninstallNvidiaDriver
            fi
            if [ "$cuda" != 0 ]
            then
                uninstallCuda
            fi
        else
            unsupportedError "unex"
        fi
    fi
    ;;
"10.13")
    echo "macOS 10.13 High Sierra (build: $build) has been detected"
    if [ "$install" == 1 ]
    then
        if [ "$driver" == 1 ]
        then
            installNvidiaDriver
        fi
        if [ "$enabler" == 1 ]
        then
            installEnabler
        fi
        if [ "$cuda" != 0 ]
        then
            installCuda
        fi
    else
        if [ "$uninstall" == 1 ]
        then
            if [ "$enabler" == 1 ]
            then
                uninstallEnabler
            fi
            if [ "$driver" == 1 ]
            then
                uninstallNvidiaDriver
            fi
            if [ "$cuda" != 0 ]
            then
                uninstallCuda
            fi
        else
            unsupportedError "unex"
        fi
    fi
    ;;
"10.14")
    echo "Your OS is to new. Compatibility may change in the future, though."
    unsupportedError "unsupOS"
    ;;
*)
    unsupportedError "unsupOS"
    ;;
esac

if [ "$scheduleReboot" == 1 ]
then
    sudo reboot
fi
#end

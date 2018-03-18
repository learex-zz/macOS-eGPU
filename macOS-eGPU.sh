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
    "-cuda")
        cuda=1
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
#check if system is compatible with script and execute commands
case "${os::5}"
in
"10.12")
    echo "macOS 10.12 Sierra (build: $build) has been detected"
    if [ "$install" == 1 ]
    then
        if [ "$driver" == 1 ] && [ "&enabler" == 1 ]
        then
            echo
            echo "Downloading and preparing goalque's automate-eGPU script ..."
            curl -o ~/Desktop/automate-eGPU.sh https://raw.githubusercontent.com/goalque/automate-eGPU/master/automate-eGPU.sh
            cd ~/Desktop/
            chmod +x automate-eGPU.sh
            echo "Executing goalque's automate-eGPU script with root privileges ..."
            sudo ./automate-eGPU.sh
            rm automate-eGPU.sh
            scheduleReboot=1
        else
            if [ "$driver" == 1 ]
            then
                echo
                echo "Downloading and executing Benjamin Dobell's nvidia-driver script ..."
                bash <(curl -s https://raw.githubusercontent.com/Benjamin-Dobell/nvidia-update/master/nvidia-update.sh)
                scheduleReboot=1
            else
                if [ "$enabler" == 1 ]
                then
                    echo
                    echo
                    echo "This parameter configuration is currently unsupported."
                    echo "The script has failed."
                    if [ "$scheduleReboot" == 1 ]
                    then
                        echo "Some configurations have been changed."
                    else
                        echo "Nothing has been changed."
                    fi
                    exit
                fi
            fi
        fi
        if [ "$cuda" == 1 ]
        then
            echo
            echo "Downloading and preparing cuda installer ..."
            curl -o ~/Desktop/cudaDriver.dmg http://us.download.nvidia.com/Mac/cuda_387/cudadriver_387.99_macos.dmg
            hdiutil attach ~/Desktop/cudaDriver.dmg
            cp /Volumes/CUDADriver/CUDADriver.pkg ~/Desktop/CUDADriver.pkg
            hdiutil detach /Volumes/CUDADriver/
            rm ~/Desktop/cudaDriver.dmg
            echo "Executing cuda installer with root privileges ..."
            sudo installer -pkg ~/Desktop/CUDADriver.pkg -target /
            rm ~/Desktop/CUDADriver.pkg
            scheduleReboot=1
        fi
    else
        if [ "$uninstall" == 1 ]
        then
            if [ "$enabler" == 1 ]
            then
                echo
                echo "Downloading and preparing goalque's automate-eGPU script ..."
                curl -o ~/Desktop/automate-eGPU.sh https://raw.githubusercontent.com/goalque/automate-eGPU/master/automate-eGPU.sh
                cd ~/Desktop/
                chmod +x automate-eGPU.sh
                echo "Executing goalque's automate-eGPU script with root privileges and uninstall parameter..."
                sudo ./automate-eGPU.sh -uninstall
                rm automate-eGPU.sh
                scheduleReboot=1
            fi
            if [ "$driver" == 1 ]
            then
                echo
                echo "Executing NVIDIA Driver uninstaller with root privileges ..."
                sudo installer -pkg /Library/PreferencePanes/NVIDIA\ Driver\ Manager.prefPane/Contents/MacOS/NVIDIA\ Web\ Driver\ Uninstaller.app/Contents/Resources/NVUninstall.pkg -target /
                scheduleReboot=1
            fi
            if [ "$cuda" == 1 ]
            then
                echo
                echo "Executing cuda uninstall script with root privileges ..."
                sudo perl /usr/local/bin/uninstall_cuda_drv.pl
                scheduleReboot=1
            fi
        else
            echo "An unexpected error has occured."
            echo "The script has failed."
            if [ "$scheduleReboot" == 1 ]
            then
                echo "Some configurations have been changed."
            else
                echo "Nothing has been changed."
            fi
        fi
    fi
    ;;
"10.13")
    echo "macOS 10.13 High Sierra (build: $build) has been detected"
    if [ "$install" == 1 ]
    then
        if [ "$driver" == 1 ]
        then
            echo
            echo "Downloading and executing Benjamin Dobell's nvidia-driver script ..."
            bash <(curl -s https://raw.githubusercontent.com/Benjamin-Dobell/nvidia-update/master/nvidia-update.sh)
            scheduleReboot=1
        fi
        if [ "$enabler" == 1 ]
        then
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
                echo
                echo
                echo "You have an unsupported build of macOS High Sierra."
                echo "This may change in the future, so try again in a few days."
                echo "The script has failed. Nothing has been changed."
                exit
                ;;
            esac
            echo
            echo "Downloading and installing ""$author""'s eGPU-enabler ..."
            curl -o ~/Desktop/NVDAEGPU.zip "$downPath"
            unzip ~/Desktop/NVDAEGPU.zip -d ~/Desktop/
            rm ~/Desktop/NVDAEGPU.zip
            mv ~/Desktop/$appName ~/Desktop/NVDAEGPUSupport.pkg
            sudo installer -pkg ~/Desktop/NVDAEGPUSupport.pkg -target /
            rm ~/Desktop/NVDAEGPUSupport.pkg
            scheduleReboot=1
        fi
        if [ "$cuda" == 1 ]
        then
            echo
            echo "Downloading and preparing cuda installer ..."
            curl -o ~/Desktop/cudaDriver.dmg http://us.download.nvidia.com/Mac/cuda_387/cudadriver_387.128_macos.dmg
            hdiutil attach ~/Desktop/cudaDriver.dmg
            cp /Volumes/CUDADriver/CUDADriver.pkg ~/Desktop/CUDADriver.pkg
            hdiutil detach /Volumes/CUDADriver/
            rm ~/Desktop/cudaDriver.dmg
            echo "Executing cuda installer with root privileges ..."
            sudo installer -pkg ~/Desktop/CUDADriver.pkg -target /
            rm ~/Desktop/CUDADriver.pkg
            scheduleReboot=1
        fi
    else
        if [ "$uninstall" == 1 ]
        then
            if [ "$enabler" == 1 ]
            then
                echo
                echo "Removing enabler (root privileges needed) ..."
                sudo rm /Library/Extensions/NVDAEGPUSupport.kext
                scheduleReboot=1
            fi
            if [ "$driver" == 1 ]
            then
                echo
                echo "Executing NVIDIA Driver uninstaller with root privileges ..."
                sudo installer -pkg /Library/PreferencePanes/NVIDIA\ Driver\ Manager.prefPane/Contents/MacOS/NVIDIA\ Web\ Driver\ Uninstaller.app/Contents/Resources/NVUninstall.pkg -target /
                scheduleReboot=1
            fi
            if [ "$cuda" == 1 ]
            then
                echo
                echo "Executing cuda uninstall script with root privileges ..."
                sudo perl /usr/local/bin/uninstall_cuda_drv.pl
                scheduleReboot=1
            fi
        else
            echo "An unexpected error has occured."
            echo "The script has failed."
            if [ "$scheduleReboot" == 1 ]
            then
                echo "Some configurations have been changed."
            else
                echo "Nothing has been changed."
            fi
        fi
    fi
    ;;
"10.14")
    echo
    echo
    echo "Your OS is to new."
    echo "There is no enabler currently available."
    echo "This may change in the future, so try again in a few days."
    echo "The script has failed. Nothing has been changed."
    exit
    ;;
*)
    echo
    echo
    echo "Your OS version is to old."
    echo "It is unlikely that a tool will be available."
    echo "Try updating your OS instead."
    echo "The script has failed. Nothing has been changed."
    exit
    ;;
esac

if [ "$scheduleReboot" == 1 ]
then
    sudo reboot
fi

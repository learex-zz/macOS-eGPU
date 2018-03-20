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
####


#define all settings variables
doneSomething=0
installedNvidiaDrivers=0
installedEnabler=0
installedCuda=0

waitTime=15

#define error functions and messages and end functions


function printChanges {
####
    echo "Print changes"
}

function rebootSystem {
    if [ "$noReboot" == 1 ]
    then
        echo "A reboot of the system is recommended."
    else
        if [ "$waitTime" == 1 ]
        then
            echo "The system will reboot in 1 second ..."
        elif [ "$waitTime" == 0 ]
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
    echo
    echo "The script has stopped."
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
        exit
        ;;
    *)
        echo "An unknown error as occured."
        ;;
    esac
    irupt
exit
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
        echo "No cuda installation was detected."
        ;;
    "unCudaDriver")
        echo "No cuda driver was detected."
        ;;
    "unCudaToolkit")
        echo "No cuda toolkit was detected."
        ;;
    "unCudaSamples")
        echo "No cuda samples were detected."
        ;;
    "unNvidiaDriver")
        echo "No cuda driver was found."
        ;;
    "unEnabler")
        echo "No nvidia eGPU enabler kext was found."
        ;;
    *)
        echo "An unknown error as occured."
        fail=1
        ;;
    esac
    if [ "$fail" == 1 ]
    then
        echo "Continuation might result in failure!"
    fi
    cont "ask" "Continue?" "The script will try to execute the rest of the queue ..."
    echo "The script will still try to continue executing ..."
}
















































#!/bin/bash

#   Preamble
#
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

#   Note for programmers
#   This script consists of several parts that are completeley intertwined, therefore, it's important to look out for crossreferences.
#   The script will only start at the very last line of the script. Earlier function-calls are disallowed.
#   Please refrain from using another scripting-style than the one displayed below.




#   A - beginning

gitBranch="master"
gitPath="https://raw.githubusercontent.com/learex/macOS-eGPU/""$gitBranch"
scriptVersion="2.0"

securityIsActive=true
loggingIsActive=true

lastTestedOS="10.13.6"
lastTestedBuild="17G65"

unixTimeStampOfStart="$(date +%s)"
humanReadableTimeStampOfStart="$(date -r $unixTimeStampOfStart)"
logFileName="macOS-eGPU-log-""$unixTimeStampOfStart"".txt"
logFilePath="$HOME""/Desktop/""$logFileName"

recentFailure=false


#   B - logger

function saveExitCode() {
  exitCode="$?"
}

function createLogFile() {
  if "$loggingIsActive"; then
    if ! [[ -f "$logFilePath" ]]; then
      touch "$logFilePath"
      echo "$logFileName" >> "$logFilePath"
      echo "This is the log of macOS-eGPU.sh from ""$humanReadableTimeStampOfStart" >> "$logFilePath"
      echo "$gitBranch"" | ""$gitPath"" | ""$scriptVersion"" | ""$lastTestedOS"" | ""$unixTimeStampOfStart" >> "$logFilePath"
      echo >> "$logFilePath"
    fi
  fi
}

function logFunctionEcho() {
  lineToExececutefn="$@"

  if "$loggingIsActive"; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - function echo - ""$lineToExececutefn" >> "$logFilePath"
    echo "- Verbose Function Call Log Beginning -" >> "$logFilePath"
    $lineToExececutefn >> "$logFilePath" 2>&1
    saveExitCode
    echo "- Verbose Function Call Log End -" >> "$logFilePath"
    echo "exited with (""$exitCode"")" >> "$logFilePath"
  else
    $lineToExececutefn &> /dev/null
    saveExitCode
  fi
}

function logEvent() {
  eventTextfn="$@"

  if "$loggingIsActive"; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - event log     - ""$eventTextfn" >> "$logFilePath"
    echo "exited with (""$exitCode"")" >> "$logFilePath"
  fi
}

function logEventNoExitcode() {
  eventTextfn="$@"

  if "$loggingIsActive"; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - event log nec - ""$eventTextfn" >> "$logFilePath"
  fi
}

function logEventOnFailure() {
  eventTextfn="$@"

  if "$loggingIsActive" && [[ "$exitCode" != 0 ]]; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - event log onf - ""$eventTextfn" >> "$logFilePath"
    echo "exited with (""$exitCode"")" >> "$logFilePath"

    recentFailure=true
  fi
}

function logEventOnFailureNoExitcode() {
  eventTextfn="$@"

  if "$loggingIsActive" && [[ "$exitCode" != 0 ]]; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - event log fne - ""$eventTextfn" >> "$logFilePath"

    recentFailure=true
  fi
}

function logFunctionCall() {
  functionNamefn="$@"

  if "$loggingIsActive"; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - function call - ""$functionNamefn" >> "$logFilePath"
  fi
}

function logVariable() {
  variableNamefn="$1"

  if "$loggingIsActive"; then
    createLogFile

    echo -n -e "\n" >> "$logFilePath"
    echo "[$(date)] - variable      - ""$variableNamefn" >> "$logFilePath"
    echo "$(eval echo \$$variableNamefn)" >> "$logFilePath"
  fi
}




#   C - screenplay

terminalWidth=0
textWidth=0
lastLineLeft=""
lastLineAwaitingRightBoundText=false
recentIntermissionMessage=false
inlineOffset=0
inlineOffsetText=""
silentExecution=false

numerator=0
denominator=1
percentile=0

function updateTerminalWidth() {
  terminalWidth="$(expr $(tput cols))"
}

function updateInlineOffset() {
  inlineOffsetText=""
  for (( i = 0; i < "$inlineOffset"; i = i + 2 )); do
    inlineOffsetText="$inlineOffsetText""| "
  done
}

function echoInset() {
  inlineOffset=$(dc -e "$inlineOffset 2 + n")
}

function echoOutset() {
  inlineOffset=$(dc -e "$inlineOffset 2 - n")

  if [[ "$inlineOffset" < 0 ]]; then
    inlineOffset=0
  fi
}

function echoResetOffset() {
  inlineOffset=0
}

function echoLeftBound() {
  echoTextfn="$1"
  echoAwaitRightBoundTextfn="$2"

  if ! "$silentExecution"; then
    if [[ "$echoAwaitRightBoundTextfn" != "true" ]]; then
      echoAwaitRightBoundTextfn=false
    else
      echoAwaitRightBoundTextfn=true
    fi

    updateInlineOffset

    echo -n "$inlineOffsetText""$echoTextfn"
    if ! "$echoAwaitRightBoundTextfn"; then
      echo
      lastLineAwaitingRightBoundText=false
    else
      textWidth=$(echo -n "$inlineOffsetText""$echoTextfn" | wc -c | xargs)
      lastLineLeft="$echoTextfn"
      lastLineAwaitingRightBoundText=true
    fi

    recentIntermissionMessage=false
  fi
}

function echoOpen() {
  echoTextfn="$1"

  echoLeftBound "┌ ""$echoTextfn"
  echoInset
}

function echoClose() {
  echoOutset
  echoLeftBound "└────────────"
}

function echoRightBound() {
  echoTextRightfn="$1"
  echoStylingfn="$2"

  if ! $silentExecution; then
    updateTerminalWidth

    if "$recentIntermissionMessage" && "$lastLineAwaitingRightBoundText"; then
      echoLeftBound "$lastLineLeft" true
    fi

    textWidthtmp=$(echo -n "$echoTextRightfn" | wc -c | xargs)
    remainingSpacestmp=$(expr "$terminalWidth" - "$textWidthtmp" - "$textWidth")

    for (( i = 0; i < "$remainingSpacestmp"; i++ )); do
      echo -n " "
    done

    if [[ "$echoStylingfn" != "" ]]; then
      tput setaf "$echoStylingfn"
    fi

    echo "$echoTextRightfn"

    if [[ "$echoStylingfn" != "" ]]; then
      tput sgr0
    fi

    lastLineAwaitingRightBoundText=false
    recentIntermissionMessage=false
  fi
}

function echoErrorMessage() {
  echoErrorMessagefn="$1"

  updateTerminalWidth
  if "$lastLineAwaitingRightBoundText"; then
    echoRightBound "[ERROR]" 1
    lastLineAwaitingRightBoundText=true
  fi

  tput setaf 1
  tput bold
  echo "ERROR: execution has stopped"
  tput sgr0
  tput setaf 1
  echo -e "$echoErrorMessagefn"
  tput sgr0
  echo
  recentIntermissionMessage=true
}

function echoErrorMessageOnFailure() {
  echoErrorMessagefn="$1"

  if [[ "$exitCode" != 0 ]]; then
    recentFailure=true
    echoErrorMessage "$echoErrorMessagefn"
  fi
}

function echoIntermissionMessage() {
  echoIntermissionMessagefn="$1"

  updateTerminalWidth
  if "$lastLineAwaitingRightBoundText"; then
    echoRightBound "[HALT]" 3
    lastLineAwaitingRightBoundText=true
  fi

  tput setaf 3
  tput bold
  echo "The current exectution flow has been halted."
  tput sgr0
  tput setaf 3
  echo -e "$echoIntermissionMessagefn"
  tput sgr0
  echo
  recentIntermissionMessage=true
}

function echoIntermissionMessageOnFailure() {
  echoIntermissionMessagefn="$1"

  if [[ "$exitCode" != 0 ]]; then
    recentFailure=true
    echoIntermissionMessage "$echoIntermissionMessagefn"
  fi
}

function echoSuccessError() {
  if [[ "$exitCode" != 0 ]]; then
    echoRightBound "[ERROR]" 1
    recentFailure=false
  else
    echoRightBound "[success]" 2
  fi
}

function echoDoneFailure() {
  if "$recentFailure"; then
    echoRightBound "[FAILED]" 1
    recentFailure=false
  else
    echoRightBound "[done]" 2
  fi
}

function insertNewLines() {
  numberOfWhiteLinesfn="$1"

  for (( i = 0; i < "$numberOfWhiteLinesfn"; i++ )); do
    echo
  done
}

function percentageMeterInitalize() {
  numberOfTasksfn="$1"

  numerator=0
  denominator="$numberOfTasksfn"
  percentile=0
}

function nextPercentile() {
  numerator=$(dc -e "$numerator 1 + n")
  percentile=$(dc -e "$numerator 100 * $denominator / n")
}

function waiter() {
  numberOfSecondsToWaitfn="$1"

  for (( i = "$numberOfSecondsToWaitfn"; i > 0; i-- )); do
    echo -n "$i"".."
    sleep 1
  done
  echo "0"
}

function silentWaiter() {
  numberOfSecondsToWaitfn="$1"

  for (( i = "$numberOfSecondsToWaitfn"; i > 0; i-- )); do
    sleep 1
  done
}




#   D - privilege handling

privilegesAreElevated=false
privilegesWereElevated=false

function checkElevatedPrivileges() {
  logFunctionCall checkElevatedPrivileges

  logVariable privilegesAreElevated

  sudo -n -v &> /dev/null
  saveExitCode

  if [[ "$exitCode" == 0 ]]; then
    privilegesAreElevated=true
  fi

  logVariable privilegesAreElevated
}

function checkInitialPrivileges() {
  logFunctionCall checkInitialPrivileges

  logVariable privilegesWereElevated

  checkElevatedPrivileges
  privilegesWereElevated="$privilegesAreElevated"

  logVariable privilegesWereElevated
}

function prolongElevatedPrivilegeWindow() {
  logFunctionCall prolongElevatedPrivilegeWindow

  logVariable privilegesAreElevated

  if "$privilegesAreElevated"; then
    logEventNoExitcode prolongRootAccessWindow

    sudo -n -v &> /dev/null

    saveExitCode
    logEventOnFailure prolongRootAccessWindowFailed

    echoIntermissionMessageOnFailure "Elevated privileges could not be automatically renewed. The script will continue the execution, you might however, be asked to enter your password again."
  fi
}

function aquireElevatedPrivileges() {
  logFunctionCall aquireElevatedPrivileges

  privilegesAreElevatedOld="$privilegesAreElevated"
  checkElevatedPrivileges

  if "$privilegesAreElevated"; then
    prolongElevatedPrivilegeWindow
  else
    if "$privilegesAreElevatedOld"; then
      logEventNoExitcode elevatedPrivilegesLost

      echoIntermissionMessage "Elevated privileges could not be automatically renewed. You will now be asked to enter your password again."
    else
      echoIntermissionMessage "To continue the execution flow, the script will need elevated privileges. You will now be asked to enter your password."
    fi

    logEventNoExitcode aquireElevatedPrivileges

    sudo -v

    saveExitCode
    logEventOnFailure aquireElevatedPrivilegesFailed
    echoErrorMessageOnFailure "Elevated privileges could not be aquired, the script cannot continue and hence will abort."
    abortOnFailure

    checkElevatedPrivileges
  fi
}

function restorePrivileges() {
  logFunctionCall restorePrivileges

  if ! "$privilegesWereElevated"; then
    sudo -k

    logEventNoExitcode privilegesRestored
  fi
}




#   E - finalizing and cleaning functions

attachedDMGVolumes=""
scheduleReboot=false
skipReboot=false
scheduleKextCacheRebuild=false
scheduleDyldCacheRebuild=false
theSystemHasChanged=false
unrollActionCommands=""

function detachDMGVolumes() {
  logFunctionCall detachDMGVolumes
  logVariable attachedDMGVolumes

  echoLeftBound "Detaching mounted disk images..." true
  while read -r currentDMGVolumeToDetachtmp; do
    if [[ -d "$currentDMGVolumeToDetachtmp" ]]; then
      logFunctionEcho hdiutil detach "$currentDMGVolumeToDetachtmp"
      echoErrorMessageOnFailure "$currentDMGVolumeToDetachtmp"" could not be detached. The script will try to continue."
    fi
  done <<< "$attachedDMGVolumes"

  echoDoneFailure
}

function systemClean() {
  logFunctionCall systemClean

  echoOpen "Cleaning the system..."
  removeTemporaryDirectory
  detachDMGVolumes
  echoClose
}

function rebuildKextCache() {
  logFunctionCall rebuildKextCache
  logVariable scheduleKextCacheRebuild
  logVariable scheduleDyldCacheRebuild

  echoOpen "Updating caches..."
  if "$scheduleKextCacheRebuild"; then
    echoOpen "Rebuilding kernel extension caches..."
    aquireElevatedPrivileges
    trapAllowDirectExit

    echoLeftBound "Phase 1" true
    logFunctionEcho sudo touch /System/Library/Extensions
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 2" true
    logFunctionEcho sudo kextcache -q -update-volume /
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 3" true
    logFunctionEcho sudo touch /System/Library/Extensions
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 4" true
    logFunctionEcho sudo kextcache -system-caches
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 5" true
    logFunctionEcho sudo kextcache -clear-staging
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoClose
  fi

  if "$scheduleDyldCacheRebuild"; then
    echoOpen "Rebuilding dynamic link editor cache..."
    aquireElevatedPrivileges
    trapAllowDirectExit

    echoLeftBound "Phase 1" true
    logFunctionEcho sudo update_dyld_shared_cache -root / -force
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 2" true
    logFunctionEcho sudo update_dyld_shared_cache -debug
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoLeftBound "Phase 3" true
    logFunctionEcho sudo update_dyld_shared_cache
    echoErrorMessageOnFailure "An unknown error occured, the script will try to continue."
    echoDoneFailure

    echoClose
  fi

  echoClose
}

function rebootSystem() {
  logFunctionCall rebootSystem

  logVariable skipReboot
  logVariable scheduleReboot
  logVariable securityIsActive

  if ! "$scheduleReboot"; then
    echoLeftBound "The script has come to a close and will now exit."
  elif "$skipReboot" || ( ! "$securityIsActive" ); then
    echoLeftBound "A reboot is recommended. Some changes may only take effect after a reboot."
  else
    aquireElevatedPrivileges

    echoLeftBound "The script has come to a close and will now try to reboot the system."
    echoLeftBound "It may take upto 30s until the shutdown starts."

    #sudo reboot &
    saveExitCode
    logEvent rebootCommandSent

    sleep 1
  fi

  restorePrivileges

  if "$loggingIsActive"; then
    echoLeftBound "The logfile can be found here:"
    echoLeftBound "$logFilePath"
  fi

  logEvent exitingScript
  exit 0
}

function finishScript() {
  logFunctionCall finishScript
  logVariable theSystemHasChanged

  echoResetOffset

  insertNewLines 2
  if "$theSystemHasChanged"; then
    echoLeftBound "The script is about to finalize all updates to the system. Please do not abort."
    systemClean
    rebuildKextCache
    rebootSystem
  else
    systemClean
    restorePrivileges
    echoLeftBound "The script has come to a close and will now exit. No changes were made."

    if "$loggingIsActive"; then
      echoLeftBound "The logfile can be found here:"
      echoLeftBound "$logFilePath"
    fi

    logEvent exitingScript
    exit 0
  fi
}

function unrollActions() {
  logFunctionCall unrollActions

  logVariable unrollActionCommands

  unrollActionCommands=$(echo -e -n "$unrollActionCommands")

  echoOpen "Unrolling changes..."
  while read -r currentCommandtmp; do
    if [[ "$currentCommandtmp" != "" ]]; then
      logVariable currentCommandtmp
      eval "$currentCommandtmp"
      saveExitCode
      logEvent "$currentCommandtmp"
    fi
  done <<< "$unrollActionCommands"
  echoClose
}

function interruptScript() {
  interuptMessagefn="$1"

  logFunctionCall interruptScript

  logVariable theSystemHasChanged

  echoResetOffset

  if [[ "$interuptMessagefn" != "" ]]; then
    echoErrorMessage "$interuptMessagefn"
  else
    echoErrorMessage "Panic mode has been triggered due to an unexpected error."
  fi

  if "$theSystemHasChanged"; then
    echo "The script will now try and revert all changes and close into a state prior to the execution."
    unrollActions
  else
    echo "The script has come to a close and will now exit. No changes were made."
  fi

  if "$loggingIsActive"; then
    echoLeftBound "The logfile can be found here:"
    echoLeftBound "$logFilePath"
  fi

  logEvent exitingScript
  exit 0
}


function abortOnFailure() {
  abortMessagefn="$1"

  logFunctionCall abortOnFailure

  if [[ "$exitCode" != 0 ]]; then
    recentFailure=true
    interruptScript "$abortMessagefn"
  fi
}




#   F - traps
exitScriptOnInteruptWarning1=false
exitScriptOnInteruptWarning2=false
scheduleRollbackOnceExecutionLockIsLifted=false

function doRollbackOnceExecutionLockIsLifted() {
  if "$scheduleRollbackOnceExecutionLockIsLifted"; then
    interruptScript
  fi
}


function trapInterrupt() {
  logFunctionCall trapInterrupt
  logVariable exitScriptOnInteruptWarning1
  logVariable exitScriptOnInteruptWarning2

  if ( "$exitScriptOnInteruptWarning1" && "$exitScriptOnInteruptWarning2" ) || ( ! "$securityIsActive" ); then
    interruptScript
  fi
  if ! "$exitScriptOnInteruptWarning1"; then
    exitScriptOnInteruptWarning1=true
    echo "You pressed ^C. This command is for exiting a running script. However, the script currently is in a state where an exit is not recommended."
    sleep 5
  else
    exitScriptOnInteruptWarning2=true
    echo "It seems you pressed ^C again. If you are absolutely sure you want to abort the script press again, but beware, your system might exit into an unrepairable state."
  fi
}

function trapInterruptDirect() {
  logFunctionCall trapInterruptDirect
  logVariable exitScriptOnInteruptWarning1
  logVariable exitScriptOnInteruptWarning2

  if ( "$exitScriptOnInteruptWarning1" && "$exitScriptOnInteruptWarning2" ) || ( ! "$activeSecurity" ); then
    trap '{ logFunctionCall manualInterrupt; echoResetOffset; echo "Abort in progress..."; systemClean; restorePrivileges; exit 1; }' INT
  fi
  if ! "$exitScriptOnInteruptWarning1"; then
    exitScriptOnInteruptWarning1=true
    echo "You pressed ^C. This command is for exiting a running script. However, the script currently is in a state where an exit is not recommended."
    sleep 5
  else
    exitScriptOnInteruptWarning2=true
    echo "It seems you pressed ^C again. If you are absolutely sure you want to abort the script press again, but beware, your system might exit into an unrepairable state."
  fi
}

function scheduleRevert() {
  logFunctionCall scheduleRevert
  logVariable exitScriptOnInteruptWarning1=false
  logVariable exitScriptOnInteruptWarning2=false
  logVariable doRollbackOnceExecutionLockIsLifted

  if ( "$exitScriptOnInteruptWarning1" && "$exitScriptOnInteruptWarning2" ) || ( ! "$securityIsActive" ); then
    doRollbackOnceExecutionLockIsLifted=true
  fi
  if ! "$exitScriptOnInteruptWarning1"; then
    exitScriptOnInteruptWarning1=true
    echo "You pressed ^C. This command is for exiting a running script. However, the script currently is in a state where an exit should be avoided under any circumstances."
    sleep 5
  else
    exitScriptOnInteruptWarning2=true
    echo "It seems you pressed ^C again. If you are absolutely sure you want to abort the script press again. The script will then finish the current task and then revert all changes."
  fi
}

function trapAllowExit() {
  logFunctionCall trapAllowExit

  doRollbackOnceExecutionLockIsLifted

  exitScriptOnInteruptWarning1=false
  exitScriptOnInteruptWarning2=false

  trap trapInterrupt INT
}

function trapAllowDirectExit() {
  logFunctionCall trapAllowDirectExit

  doRollbackOnceExecutionLockIsLifted

  exitScriptOnInteruptWarning1=false
  exitScriptOnInteruptWarning2=false

  trap trapInterruptDirect INT
}

function trapDirectExit() {
  logFunctionCall trapDirectExit

  doRollbackOnceExecutionLockIsLifted

  trap '{ logFunctionCall manualInterrupt; exitingMessage="Aborting in progress..."; interruptScript; }' INT
}

function trapLockExecution() {
  logFunctionCall trapLockExecution

  exitScriptOnInteruptWarning1=false
  exitScriptOnInteruptWarning2=false

  echo "Locking execution"

  trap scheduleRevert INT
}




#   G - temporary Directory handling

tmpDirName="$(uuidgen)"
tmpDirPath="/var/tmp/""macOS.eGPU.""$tmpDirName"

function createTemporaryDirectory() {
  logFunctionCall createTemporaryDirectory

  if ! [[ -d "$tmpDirPath" ]]; then
    echoLeftBound "Creating temporary working directory..." true
    logFunctionEcho mkdir -p "$tmpDirPath"

    echoErrorMessageOnFailure "The directory could not be created."
    abortOnFailure

    echoDoneFailure

    logEvent createTemporaryDirectory
    logVariable tmpDirPath
  fi
}

function removeTemporaryDirectory() {
  logFunctionCall removeTemporaryDirectory

  if [[ -d "$tmpDirPath" ]]; then
    echoLeftBound "Deleting the temporary working directory..." true
    logFunctionEcho rm -rfv "$tmpDirPath"

    echoErrorMessageOnFailure "The directory could not be removed completely."
    abortOnFailure

    echoDoneFailure

    logEvent removeTemporaryDirectory
    logVariable tmpDirPath
  fi
}




#   H - helper
function pbuddy() {
  parametersfn="$@"

  logFunctionCallInline /usr/libexec/PlistBuddy -c $parametersfn
}

function sudopbuddy() {
  parametersfn="$@"

  logFunctionCallInline sudo /usr/libexec/PlistBuddy -c $parametersfn
}

function killAllApps() {
  logFunctionCall killAllApps

  if "$securityIsActive"; then
    openedAppListtmp=""
    openedAppListtmp=$(osascript -e 'tell application "System Events" to set quitapps to name of every application process whose name is not "Finder" and name is not "Terminal"' -e 'return quitapps') &>/dev/null
    openedBashSessionstmp=$(ps -A | grep "\-bash" | grep -v "grep" | wc -l | xargs) &>/dev/null

    logVariable openedAppListtmp
    logVariable openedBashSessionstmp

    if ( ! [[ "$openedAppListtmp" == "" ]] ) || [[ "$openedBashSessionstmp" > 1 ]]; then
      # iTerm detection
      if [[ "$openedAppListtmp" =~ "iTerm" ]]; then
        exitingMessage="An open session of iTerm is detected. Since the script hasn't been tested in the iTerm environment, it will now abort. Please continue using the Terminal."
        interruptScript
      fi

      # multiple bash sessions
      if [[ "$openedBashSessionstmp" > 1 ]]; then
        exitingMessage="$openedBashSessionstmp"" opened Terminal sessions have been detected. To avoid beeing interrupted by another Terminal session, close all other sessions. The script will now abort."
        interruptScript
      fi

      # killing all apps
      openedAppListtmp="${openedAppListtmp//, /\n}"
      openedAppListtmp="$(echo -e $openedAppListtmp)"
      while read -r currentAppToQuittmp; do
        exitingMessage="Not all programs were killed. The script will now abort, in order to avoid being interrupted by another program."

        killall "$currentAppToQuittmp"
        saveExitCode

        logEvent killAllApps
        abortOnFailure
      done <<< "$openedAppListtmp"
    fi
  fi
}

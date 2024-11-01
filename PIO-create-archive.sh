#!/bin/bash
# --------------------------------------------------------------------------------
# PIO create archive from build output for release
# --------------------------------------------------------------------------------
# The purpose of this script is to create a 'framework-arduinoespressif32' archive
# from the build output of the 'esp32-arduino-lib-builder' for release.
#
# .... This script typically called by 'build.sh'.
# OUTPUT is placed at:
#      $oneUpDir/PIO-Out
#        /framework-arduinoespressif32 << Files arranged for PIO framework needs 
#        /forRelease                   << Archive and release-info files
#                                         to be used for release on Github
#                        e.g. at https://github.com/twischi/platform-espressif32
#
# .... It used the given following variables (in order of appearance):
# INPUT
#      $ArduionoCOMPS   = Folder with Arduino-Components
#      $AR_OWN_OUT      = Folder with the build output
#      $IDF_PATH        = Folder with the IDF-Components
#      $BUILD_TYPE      = Type of build (all, lib, core) used with build.sh
#      $SH_ROOT         = Root Folder lib builder >> esp32-arduino-lib-builder
# --------------------------------------------------------------------------------
clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# -----------------------------------------
# Get variables 
# -----------------------------------------
# ... Base Folder Structure
SH_ROOT=$(realpath "$(pwd)")           # Root-Folder of the lib builder
oneUpDir=$(realpath "$(pwd)"/../)      # DIR above the lib builder
echo oneUpDir: $oneUpDir
echo SH_ROOT: $SH_ROOT
# ... Load the varialbes and functions for pretty output
source $oneUpDir/addOns-esp32_AR_lib-builder//myToolsEnhancements.sh
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#... Root-Folder for PIO framework outputs
PIO_Out_DIR=$oneUpDir/PIO-Out 
echo -n PIO_Out_DIR: $PIO_Out_DIR && [ -d "$PIO_Out_DIR" ] && echo " (FOUND)" || echo " (CREATED)"
mkdir -p "$PIO_Out_DIR"                # Make sure Folder exists
#... AR_OUT = Folder with the build output
AR_OUT=$(realpath "$(pwd)"/out)        # Folder with the build output
echo -n AR_OUT: $AR_OUT  && [ -d "$AR_OUT" ] && echo " (FOUND)" || echo " (NOT FOUND)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#... Folder to arduino-esp32 -Components
AR_PATH=$(realpath "$(pwd)"/components/arduino)  # Folder with Arduino-Components
echo "AR_PATH:    "$AR_PATH
#... Repositories (from remote urls)
AR_REPO=$(git -C $AR_PATH remote get-url origin | sed -E 's#https?://[^/]+/([^/]+/[^.]+)\.git#\1#')
echo "AR_REPO:    "$AR_REPO
AR_BRANCH=$(git -C "$AR_PATH" branch --show-current --quiet)
echo "AR_BRANCH:  "$AR_BRANCH
AR_Commit_short=$(git -C "$AR_PATH" rev-parse --short HEAD || echo "") # Short commit hash of the 'arduino-esp32'
echo "AR_COMMIT:  "$AR_Commit_short "(short)"
AR_VERSION=$(jq -c '.version' "$AR_PATH/package.json" | tr -d '"')     # Version of the 'arduino-esp32'
echo "AR_VERSION: "$AR_VERSION
echo "......................................................................................"
#... Folder to the IDF-Components
IDF_PATH=$(realpath "$(pwd)"/esp-idf) # Folder with the IDF-Components
echo "IDF_PATH:   "$IDF_PATH
#... Repositories (from remote urls)
IDF_REPO=$(git -C $IDF_PATH remote get-url origin | sed -E 's#https?://[^/]+/([^/]+/[^.]+)\.git#\1#')
echo "IDF_REPO:   "$IDF_REPO
IDF_BRANCH=$(git -C "$IDF_PATH" branch --show-current --quiet)
echo "IDF_BRANCH: "$IDF_BRANCH
#... Versions of the used components
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
pioIDF_verStr="IDF_$IDF_BRANCH"
echo "pioIDF_verStr: $pioIDF_verStr"
pioAR_verStr="AR_$AR_BRANCH"
echo "pioAR_verStr:  $pioAR_verStr"
#... Create list of targets used for the build
searchFolder="$AR_OUT"/tools/esp32-arduino-libs # Folder with the build output
TargetsHyphenSep=""                             # For hyphen separated list of targets, one line!
for dir in "$searchFolder"/*/; do                           # Loop to Subfolers
    if [ -d "$dir" ]; then
        [ -n "$TargetsHyphenSep" ] && TargetsHyphenSep+="-" # Add hyphen if not first entry
        TargetsHyphenSep+=$(basename "$dir")                # Add target to list
    fi
done
echo "4Targets=      "$TargetsHyphenSep
echo "===================================================================================="
echo "                            Create  Stuff for PIO release"
echo "------------------------------------------------------------------------------------"
# -----------------------------------------
# PIO Framework Folder = from build output 
# -----------------------------------------
OUT_PIO=$PIO_Out_DIR/framework-arduinoespressif32
[ -d "$OUT_PIO" ] && rm -rf "$OUT_PIO" # Remove old folder if exists
mkdir -p dist "$OUT_PIO"               # Make sure Folder exists
OUT_PIO_Release=$PIO_Out_DIR/forRelease
# echo "ArduionoCOMPS: $ArduionoCOMPS"
#-----------------------------------------
# Message: Start Creating content
#-----------------------------------------
echo -e " for Target(s):$eTG $TargetsHyphenSep $eNO"
echo -e " a) Create PlatformIO 'framework-arduinoespressif32' from build (copying...)"
echo -e "    ...in: $(shortFP "$OUT_PIO")"
####################################################
# Create PIO - framework-arduinoespressif32  
####################################################
#-----------------------------------------
# PIO COPY 'cores/esp32' - FOLDER
#-----------------------------------------
mkdir -p "$OUT_PIO"/cores/esp32
cp -rf "$AR_PATH"/cores "$OUT_PIO"       # cores-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY 'tools' - FOLDER
#-----------------------------------------
mkdir -p "$OUT_PIO"/tools/partitions
cp -rf "$AR_PATH"/tools "$OUT_PIO"       # tools-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#   Remove *.exe files as they are not needed
    rm -f "$OUT_PIO"/tools/*.exe               # *.exe in Tools-Folder >> remove 
cp -rf out/tools/esp32-arduino-libs "$OUT_PIO"/tools/  # from 'esp32-arduino-libs'       (BUILD output-libs)
#--------------------------------------------- 
# PIO modify .../tools//platformio-build.py 
#---------------------------------------------
echo -e " ...modfied '/tools//platformio-build.py' for FRAMEWORK_LIBS_DIR"
searchLineBy='FRAMEWORK_LIBS_DIR ='
 replaceLine='FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")'
sed -i '' "/^$searchLineBy/s/.*/$replaceLine/" "$OUT_PIO"/tools/platformio-build.py
#-----------------------------------------
# PIO COPY 'libraries' - FOLDER
#-----------------------------------------
cp -rf "$AR_PATH"/libraries "$OUT_PIO"     # libraries-Folder  from 'arduino-esp32'  -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY 'variants' - FOLDER
#-----------------------------------------
cp -rf "$AR_PATH"/variants "$OUT_PIO"      # variants-Folder   from 'arduino-esp32   -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY Single FILES
#-----------------------------------------
cp -f "$AR_PATH"/CMakeLists.txt "$OUT_PIO" # CMakeLists.txt    from 'arduino-esp32'  -IDF Components (GitSource)
cp -rf "$AR_PATH"/idf_* "$OUT_PIO"         # idf.py            from 'arduino-esp32'  -IDF Components (GitSource)
cp -f "$AR_PATH"/Kconfig.projbuild "$OUT_PIO" # Kconfig.projbuild from 'arduino-esp32'  -IDF Components (GitSource)
#----------------------------------- 
# PIO CREATE NEW file: cores/esp32/              # core_version.h    from 'arduino-esp32' & 'esp-idf'  -IDF Components (GitSource)
#----------------------------------- 
# Get needed Info's for this file
AR_VERSION_UNDERSCORE=$(echo "$AR_VERSION" | tr . _)                         # Replace dots with underscores
IDF_Commit_short=$(git -C "$IDF_PATH" rev-parse --short HEAD || echo "")     # Short commit hash of the 'esp-idf'
#echo -e "AR_VERSION_UNDERSCORE: $AR_VERSION_UNDERSCORE"
#------------------------------------------
# PIO create/write the core_version.h file
#-----------------------------------------
echo -e " b) Add core_version.h - File(creating...)"
echo -e "    ...to: $(shortFP "$OUT_PIO"/cores/esp32/)$eTG"core_version.h"$eNO"
cat <<EOL > "$OUT_PIO"/cores/esp32/core_version.h
#define ARDUINO_ESP32_GIT_VER 0x$AR_Commit_short
#define ARDUINO_ESP32_GIT_DESC $AR_VERSION
#define ARDUINO_ESP32_RELEASE_$AR_VERSION_UNDERSCORE
#define ARDUINO_ESP32_RELEASE "$AR_VERSION_UNDERSCORE"
EOL
#---------------------------------------------
# PIO generate framework manifest file            # package.json      from 'arduino-esp32' & 'esp-idf'  -IDF Components (GitSource)
#--------------------------------------------- 
echo -e " c) Add PIO framework manifest (creating...)"
echo -e "    ...to: $(shortFP "$OUT_PIO"/)$eTG"package.json"$eNO" 
if [ "$BUILD_TYPE" = "all" ]; then
    python3 $SH_ROOT/tools/PIO-gen_frmwk_manifest.py -o "$OUT_PIO/" -s "v$AR_VERSION" -c "$IDF_COMMIT"
    if [ $? -ne 0 ]; then exit 1; fi
fi
# -----------------------------------------------------
# PIO generate release-info that will be added archive
# -----------------------------------------------------
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) # Get current branch of used esp32-arduiono-lib-builder
echo -e " d) Creating release-info.txt used for publishing (creating...)"
echo -e "    ...to: $(shortFP $OUT_PIO/)$eTG"release-info.txt"$eNO" 
cat <<EOL > $OUT_PIO/release-info.txt
Framework built from resources:

-- $IDF_REPO
 * branch [$IDF_BRANCH]
   https://github.com/$IDF_REPO/tree/$IDF_BRANCH
 * commit [$IDF_Commit_short]
   https://github.com/$IDF_REPO/commits/$IDF_BRANCH/#:~:text=$IDF_Commit_short

-- $AR_REPO
 * branch [$AR_BRANCH]
   https://github.com/$AR_REPO/tree/$AR_BRANCH
 * commit [$AR_Commit_short]
   https://github.com/$AR_REPO/commits/$AR_BRANCH/#:~:text=$AR_Commit_short

build with:
-- esp32-arduino-lib-builder
   * branch [$GIT_BRANCH]
     https://github.com/twischi/esp32-arduino-lib-builder.git

Build for this targets:
   $TargetsHyphenSep
EOL
#cat "$OUT_PIO"/release-info.txt
#-----------------------------------------
# Message create archive
#-----------------------------------------
echo -e " e) Creating Archive-File (compressing...)"
#---------------------------------------------------------
# Set variables for the archive file tar.gz or zip 
#---------------------------------------------------------
#... Versions of the used components 
idfVersStr="$pioIDF_verStr-$pioAR_verStr"       # Create Version string
idfVersStr=${idfVersStr//\//_}                  # Remove '/' from string
#... compose Filename
pioArchFN="framework-arduinoespressif32-$idfVersStr-$TargetsHyphenSep.tar.gz"    # Name of the archive
echo -e "    ...in:            $(shortFP $OUT_PIO_Release)"
echo -e "    ...arch-Filename:$eTG $pioArchFN $eNO"
pioArchFP="$OUT_PIO_Release/$pioArchFN"            # Full path of the archive
# ---------------------------------------------
# Create the Archive with tar
# ---------------------------------------------
cd $OUT_PIO/..           # Step to source-Folder
rm -f "$pioArchFP"       # Remove potential old file
mkdir -p "$OUT_PIO_Release" # Make sure Folder exists
#          <target>    <source> in currtent dir 
tar -zcf "$pioArchFP" framework-arduinoespressif32/
cd $SH_ROOT             # Step back to script-Folder
# ---------------------------------------------
# Export Release-Info to be used for git upload
# ---------------------------------------------
esp_AR_libBuilder_Url=$(git remote get-url origin)
# echo esp_AR_libBuilder_Url: $esp_AR_libBuilder_Url
echo -e " f) Create Relase-Info for git upload - File(creating...)"
# ..............................................
# Release-Info as text-file
# ..............................................
echo -e "    ...to: $(shortFP $OUT_PIO_Release/)$eTG"pio-release-info.txt"$eNO"
# Get list targets used for the build
rm -f $OUT_PIO_Release/pio-release-info.txt  # Remove potential old file
cat <<EOL > "$OUT_PIO_Release"/pio-release-info.txt
-----------------------------------------------------
PIO <framework-arduinoespressif32> 
-----------------------------------------------------
Filename:
$pioArchFN

Build-Tools-Version used in Filename:
$idfVersStr

Version for PIO package.json:
$(date +"%Y.%m.%d")

<esp-idf> - Used for the build:
$pioIDF_verStr

<arduino-esp32> - Used for the build:
$pioAR_verStr

Build for this targets:
$TargetsHyphenSep
-----------------------------------------------------
Build with this <esp32-arduino-lib-builder>:
-----------------------------------------------------
$esp_AR_libBuilder_Url
EOL
#cat $OUT_PIO_Release/pio-release-info.txt
# ..............................................
# Release-Info as shell-file to import variables
# ..............................................
echo -e "         ...to: $(shortFP "$OUT_PIO_Release"/)$eTG"pio-release-info.sh"$eNO"
rm -f "$OUT_PIO_Release"/pio-release-info.sh  # Remove potential old file
cat <<EOL > "$OUT_PIO_Release"/pio-release-info.sh
#!/bin/bash
# ---------------------------------------------------
# PIO <framework-arduinoespressif32> 
# ---------------------------------------------------
# This *.sh is called by 
#    https://github.com/twischi/platform-espressif32
# to set varibles used to release this build version
# ---------------------------------------------------
# Filename:
rlFN="$pioArchFN"

# Build-Tools-Version used in Filename:
rlVersionBuild="$idfVersStr"

# Version for PIO package.json:
rlVersionPkg="$(date +"%Y.%m.%d")"

# <esp-idf> - Used for the build:
rlIDF="$pioIDF_verStr"
rlIdfTag="$IDF_TAG"

# <arduino-esp32> - Used for the build:
rlAR="$pioAR_verStr"

# Build for this targets:
rlTagets="$TargetsHyphenSep"
# -----------------------------------------------------
# Build with this <esp32-arduino-lib-builder>:
# -----------------------------------------------------
# $esp_AR_libBuilder_Url
EOL
chmod +x "$OUT_PIO_Release"/pio-release-info.sh
#cat "$OUT_PIO_Release"/pio-release-info.sh
#--------------------------------------------
# Display CREATED OUTPUT Message
#--------------------------------------------
read -r -d 'XXX' textToOutput <<EOL

--------------------------------------------
PIO <framework-arduinoespressif32> CREATED  
--------------------------------------------
OUTPUT is placed at:
   ...Files for PIO Framework needs
   $ePF $OUT_PIO $eNO

   ... Perpared for release on Github
   ... e.g. at $eGI https://github.com/twischi/platform-espressif32 $eNO
   $ePF $OUT_PIO_Release $eNO
      $eUS $pioArchFN $eNO
      ... READY to be released
XXX
EOL
echo -e "$textToOutput"
echo "------------------------------------------------------------------------------------"
echo -e "                                 PIO DONE!"
echo "===================================================================================="
# echo -e "STOPPED HERE"; exit 0
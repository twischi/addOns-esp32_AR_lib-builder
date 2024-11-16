#!/bin/bash
# --------------------------------------------------------------------------------
# PIO create archive 
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
# --- Introduce 'dryrun'-option (2024-11-15)
#     Call this script with 'dryrun' as argument for TESTING
# --------------------------------------------------------------------------------  

# FOR DEBUG ONLY
#cd ~/LB_and_PIO-ORIGINAL/esp32-arduino-lib-builder-Mod_PIO_start

clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# ---------------------------------------------------------
# Check if the script is called with 'dryrun' as argument
# -> Set and export flag 'dryrun'
# ---------------------------------------------------------
[ "$1" == "dryrun" ] && echo -e "--- DRY-RUN MODE ---\n"  || NdR=1 # Set flag for dry-run
# $NdR Set = Dry-run- // Unset = Real run >> [ $NdR ] && COMMEAND
# --------------------------------------------------
# Get many essential infomations and set variables
# --------------------------------------------------
# ... Base Folder Structure
LIB_BUILD=$(realpath "$(pwd)")         # Root-Folder of Lib-builder
oneUpDir=$(realpath "$(pwd)"/../)      # DIR above the Lib-builder
ADD_ON_PATH=$oneUpDir/addOns-esp32_AR_lib-builder 
# ... Load the varialbes and functions for pretty output
source $ADD_ON_PATH/myToolsEnhancements.sh
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Read (YOUR) configuration: Gets userGH & tokenGH, needed for GitHub authentication
source $ADD_ON_PATH/config/config.sh # Used for API calls
echo -e "oneUpDir: "    $(shortFP $oneUpDir)
echo -e LIB_BUILD:      $(shortFP $LIB_BUILD)
#... Root-Folder for PIO framework outputs
PIO_Out_DIR=$oneUpDir/PIO-Out 
echo -n PIO_Out_DIR: $PIO_Out_DIR && [ -d "$PIO_Out_DIR" ] && echo " (FOUND)" || echo " (CREATED)"
[ $NdR ] && mkdir -p "$PIO_Out_DIR" # Make sure Folder exists

#... AR_OUT = Folder with the build output
AR_OUT=$(realpath "$(pwd)"/out)         # Folder with the build output
echo -n AR_OUT: $AR_OUT  && [ -d "$AR_OUT" ] && echo " (FOUND)" || echo " (NOT FOUND)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#... Folder to arduino-esp32 -Components // https://github.com/espressif/arduino-esp32
AR_PATH=$(realpath "$(pwd)"/components/arduino)  # Folder with Arduino-Components
echo -e "AR_PATH:    "$(shortFP $AR_PATH)
#... Repositories (from remote urls)
AR_REPO=$(git -C $AR_PATH remote get-url origin | sed -E 's#https?://[^/]+/([^/]+/[^.]+)\.git#\1#')
echo "AR_REPO:    "$AR_REPO
AR_BRANCH=$(git -C "$AR_PATH" branch --show-current --quiet)
echo "AR_BRANCH:  "$AR_BRANCH
AR_Commit_short=$(git -C "$AR_PATH" rev-parse --short HEAD || echo "") # Short commit hash of the 'arduino-esp32'
echo "AR_COMMIT:  "$AR_Commit_short "(short)"
AR_Tag_closest=$(git -C "$AR_PATH" describe --tags --abbrev=0 $AR_Commit_short || echo "") # Get closest tag from commit hash
echo "AR_TAG:     "$AR_Tag_closest
AR_API="https://api.github.com/repos/"$AR_REPO"/releases/tags/"$AR_Tag_closest
AR_VERSION=$(jq -c '.version' "$AR_PATH/package.json" | tr -d '"')     # Version of the 'arduino-esp32'
echo "AR_VERSION: "$AR_VERSION
echo "....................................................................................."

#... Folder to the IDF-Components  // https://github.com/espressif/esp-idf
IDF_PATH=$(realpath "$(pwd)"/esp-idf) # Folder with the IDF-Components
echo -e "IDF_PATH:   "$(shortFP $IDF_PATH)

#... Repositories (from remote urls)
IDF_REPO=$(git -C $IDF_PATH remote get-url origin | sed -E 's#https?://[^/]+/([^/]+/[^.]+)\.git#\1#')
echo "IDF_REPO:   "$IDF_REPO
#IDF_BRANCH=$(git -C "$IDF_PATH" branch --show-current --quiet)
#echo "IDF_BRANCH: "$IDF_BRANCH
IDF_Commit_short=$(git -C "$IDF_PATH" rev-parse --short HEAD || echo "")    # Get Short commit hash of the 'esp-idf'
echo "IDF_COMMIT: "$IDF_Commit_short "(short)"
IDF_Tag_closest=$(git -C "$IDF_PATH" describe --tags --abbrev=0 $IDF_Commit_short || echo "") # Get closest tag of the 'esp-idf'
echo "IDF_TAG:    "$IDF_Tag_closest
IDF_API="https://api.github.com/repos/"$IDF_REPO"/releases/tags/"$IDF_Tag_closest
echo "IDF_API:    "$IDF_API
IDF_DL_URL=$(curl -su $userGH:$tokenGH $IDF_API | jq -r '.assets[].browser_download_url')
echo "IDF_DL_URL: "$IDF_DL_URL
IDF_DL_NAME=$(curl -su $userGH:$tokenGH $IDF_API| jq -r '.assets[].name') 
echo "IDF_DL_FN:  "$IDF_DL_NAME
IDF_DL_TAG=$(curl -su $userGH:$tokenGH $IDF_API | jq -r '.tag_name') 
#echo "IDF_TAG: "$IDF_DL_TAG
echo "....................................................................................."

#... Branch of Lib-Builder
LB_BRANCH=$(git rev-parse --abbrev-ref HEAD) # Get current branch of used esp32-arduiono-lib-builder
echo "LB_BRANCH:  "$LB_BRANCH "(esp32-arduino-lib-builder)"

#... Versions of the used components
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
pioIDF_verStr="IDF_$IDF_DL_TAG"
echo "pioIDF_verStr: $pioIDF_verStr"
pioAR_verStr="AR_$AR_VERSION"
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

# Folder Name for this release                   (e.g. 2024-11-15_IDF_v5.3.1-AR_3.1.0_esp32h2)
releaseMainFN=$(date +"%Y-%m-%d")"_"$pioIDF_verStr"-"$pioAR_verStr"_"$TargetsHyphenSep
PIO_frmwkDIR=$PIO_Out_DIR"/"$releaseMainFN"/framework-arduinoespressif32"
#echo "PIO_frmwkDIR: $PIO_frmwkDIR" && exit  
[ -d "$PIO_frmwkDIR" ] && [ $NdR ] && rm -rf "$PIO_frmwkDIR"   # Remove old folder if exists
[ $NdR ] && mkdir -p "$PIO_frmwkDIR"             # Make sure Folder exists
PIO_RelDIR=$PIO_Out_DIR"/"$releaseMainFN"/forRelease"
if [ ! $NdR ]; then
  echo "....................................................................................."
  echo -e "PIO_frmwkDIR:         "$(shortFP $PIO_frmwkDIR)
  echo -e "PIO_RelDIR: "$(shortFP $PIO_RelDIR)
fi
#-----------------------
# dry-run - STOP HERE
#-----------------------
if [ ! $NdR ]; then
    echo "END OF dryrun = STOPPED HERE"; exit 0
fi

echo "===================================================================================="
echo "                            Create  Stuff for PIO release"
echo "------------------------------------------------------------------------------------"
# ----------------------------------------------------------------------------------------
# Fill PIO Framework Folders = from 'out' of espressif's 'esp32-arduino-lib-builder'
# ----------------------------------------------------------------------------------------

#-----------------------------------------
# Message: Start Creating content
#-----------------------------------------
echo -e " for Target(s):$eTG $TargetsHyphenSep $eNO"
echo -e " a) Create PlatformIO 'framework-arduinoespressif32' from build (copying...)"
echo -e "    ...in: $(shortFP "$PIO_frmwkDIR")"

####################################################
# Create PIO - framework-arduinoespressif32  
####################################################
#--------------------------------------------
# PIO COPY 'cores/esp32' - FOLDER
#    <LB>: /components/arduino/cores/esp32
# >> <RL>: /framework-arduinoespressif32/cores/esp32
#--------------------------------------------
mkdir -p "$PIO_frmwkDIR"/cores/esp32
cp -rf "$AR_PATH"/cores "$PIO_frmwkDIR" # cores-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#--------------------------------------------
# PIO COPY 'tools' - FOLDER
#    <LB>: /components/arduino/tools
# >> <RL>: /framework-arduinoespressif32/tools
#--------------------------------------------
mkdir -p "$PIO_frmwkDIR"/tools/partitions
cp -rf "$AR_PATH"/tools "$PIO_frmwkDIR" # tools-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#   Remove *.exe files as they are not needed
    rm -f "$PIO_frmwkDIR"/tools/*.exe   # *.exe in Tools-Folder >> remove 
cp -rf out/tools/esp32-arduino-libs "$PIO_frmwkDIR"/tools/  # from 'esp32-arduino-libs'       (BUILD output-libs)

#----------------------------------------------------------------------------------
# Correct WRONG CODE BLOCK that in .../tools/platformio-build.py 
# Source espressif's    'arduino-esp32' 
# in                    .../tools/platformio-build.py
#----------------------------------------------------------------------------------
# Wrong code block
echo -e "    Correct /tools/"$eTG"platformio-build.py"$eNO
searchBlock=$(cat <<EOL
FRAMEWORK_DIR = platform.get_package_dir("framework-arduinoespressif32")
FRAMEWORK_LIBS_DIR = platform.get_package_dir("framework-arduinoespressif32-libs")
assert isdir(FRAMEWORK_DIR)
EOL
)
# Correct code block for replacement
replaceBlock=$(cat <<EOL
FRAMEWORK_DIR = platform.get_package_dir("framework-arduinoespressif32")
#-------------------------------------------------------------------------------- 
# Changes from TW @ 2024-11-16
#-------------------------------------------------------------------------------- 
# FRAMEWORK_LIBS_DIR
#-------------------------------------------------------------------------------- 
# Is later one used way:
#
# SConscript(
#    join(FRAMEWORK_LIBS_DIR, build_mcu, "platformio-build.py"))
#
# What is used
#     to include the 'platformio-build.py' of the cores
#     'build_mcu' is a placholder for the cores like 'esp32h2'
#
# >>> So us have to set the path to where it will be located
#     inside the package-Folder 'framework-arduinoespressif32'
#
# !!! My 
#      'addOns-esp32_AR_lib-builder' for providing add on's 
#      to espressif's 'esp32-arduino-lib-builder' 
#      the script 'PIO-create-archive.sh' stores the files of the cores 
#      in the folder:
#      framework-arduinoespressif32 / tools / sdk-4-targets
#-------------------------------------------------------------------------------- 
FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "sdk-4-targets")
assert isdir(FRAMEWORK_DIR)
EOL
)
# Process block replacement
perl -0777 -pi -e "s|\Q$searchBlock\E|$replaceBlock|g" ""$PIO_frmwkDIR"/tools/platformio-build.py"

#----------------------------------------------------------------
# PIO RENAME 'esp32-arduino-libs' - FOLDER
# !! <RL>: /framework-arduinoespressif32/tools/esp32-arduino-libs
# >> <RL>: /framework-arduinoespressif32/tools/sdk-4-targets
#----------------------------------------------------------------
mv -f "$PIO_frmwkDIR"/tools/esp32-arduino-libs "$PIO_frmwkDIR"/tools/sdk-4-targets
#-------------------------------------------------
# PIO COPY 'libraries' - FOLDER
#    <LB>: /components/arduino/libraries
# >> <RL>: /framework-arduinoespressif32/libraries
#-------------------------------------------------
cp -rf "$AR_PATH"/libraries "$PIO_frmwkDIR" # libraries-Folder  from 'arduino-esp32'  -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY 'variants' - FOLDER
#    <LB>: /components/arduino/variants
# >> <RL>: /framework-arduinoespressif32/variants
#-----------------------------------------
cp -rf "$AR_PATH"/variants "$PIO_frmwkDIR"      # variants-Folder   from 'arduino-esp32   -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY Single FILES
#-----------------------------------------
cp -f "$AR_PATH"/CMakeLists.txt "$PIO_frmwkDIR" # CMakeLists.txt    from 'arduino-esp32'  -IDF Components (GitSource)
cp -rf "$AR_PATH"/idf_* "$PIO_frmwkDIR"         # idf.py            from 'arduino-esp32'  -IDF Components (GitSource)
cp -f "$AR_PATH"/Kconfig.projbuild "$PIO_frmwkDIR" # Kconfig.projbuild from 'arduino-esp32'  -IDF Components (GitSource)
#----------------------------------- 
# PIO CREATE NEW file: cores/esp32/        # core_version.h    from 'arduino-esp32' & 'esp-idf'  -IDF Components (GitSource)
#----------------------------------- 
# Get needed Info's for this file
AR_VERSION_UNDERSCORE=$(echo "$AR_VERSION" | tr . _)                         # Replace dots with underscores
#echo -e "AR_VERSION_UNDERSCORE: $AR_VERSION_UNDERSCORE"
echo "....................................................................................."

#------------------------------------------
# PIO create/write the core_version.h file
#-----------------------------------------
echo -e " b) Add core_version.h - File(creating...)"
echo -e "    ...to: $(shortFP "$PIO_frmwkDIR"/cores/esp32/)$eTG"core_version.h"$eNO"
cat <<EOL > "$PIO_frmwkDIR"/cores/esp32/core_version.h
#define ARDUINO_ESP32_GIT_VER 0x$AR_Commit_short
#define ARDUINO_ESP32_GIT_DESC $AR_VERSION
#define ARDUINO_ESP32_RELEASE_$AR_VERSION_UNDERSCORE
#define ARDUINO_ESP32_RELEASE "$AR_VERSION_UNDERSCORE"
EOL
echo "....................................................................................."

#---------------------------------------------
# PIO generate framework manifest file            # package.json      from 'arduino-esp32' & 'esp-idf'  -IDF Components (GitSource)
#--------------------------------------------- 
echo -e " c) Add PIO framework manifest (creating...)"
echo -e "    ...to: $(shortFP "$PIO_frmwkDIR"/)$eTG"package.json"$eNO" 
ibr=$(git -C "$IDF_PATH" describe --all 2>/dev/null) # echo "ibr: $ibr"
python3 $LIB_BUILD/tools/gen_platformio_manifest.py -o "$PIO_frmwkDIR/" -s "$ibr" -c "$IDF_Commit_short"
if [ $? -ne 0 ]; then exit 1; fi
# echo "v$AR_VERSION"  "$IDF_Commit_short"
echo "....................................................................................."

# -----------------------------------------------------
# PIO generate release-info that will be added archive
# -----------------------------------------------------
echo -e " d) Creating release-info.txt used for publishing (creating...)"
echo -e "    ...to: $(shortFP $PIO_frmwkDIR/)$eTG"release-info.txt"$eNO" 
cat <<EOL > $PIO_frmwkDIR/release-info.txt
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
   * branch [$LB_BRANCH]
     https://github.com/twischi/esp32-arduino-lib-builder.git

Build for this targets:
   $TargetsHyphenSep
EOL
# cat "$PIO_frmwkDIR"/release-info.txt
echo "....................................................................................."

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
echo -e "    ...in:            $(shortFP $PIO_RelDIR)"
echo -e "    ...arch-Filename:$eTG $pioArchFN $eNO"
pioArchFP="$PIO_RelDIR/$pioArchFN"            # Full path of the archive
# ---------------------------------------------
# Create the Archive with tar
# ---------------------------------------------
cd $PIO_frmwkDIR/..              # Step to source-Folder
rm -f "$pioArchFP"          # Remove potential old file
mkdir -p "$PIO_RelDIR" # Make sure Folder exists
#          <target>    <source> in currtent dir 
tar -zcf "$pioArchFP" framework-arduinoespressif32/
cd $LIB_BUILD            # Step back to Lib-Builder-Folder
echo "....................................................................................."

# ---------------------------------------------
# Export Release-Info to be used for git upload
# ---------------------------------------------
esp_AR_libBuilder_Url=$(git remote get-url origin)
# echo esp_AR_libBuilder_Url: $esp_AR_libBuilder_Url
echo -e " f) Create Relase-Info for git upload - File(creating...)"
# ..............................................
# Release-Info as text-file
# ..............................................
echo -e "    ...to: $(shortFP $PIO_RelDIR/)$eTG"pio-release-info.txt"$eNO"
# Get list targets used for the build
rm -f $PIO_RelDIR/pio-release-info.txt  # Remove potential old file
cat <<EOL > "$PIO_RelDIR"/pio-release-info.txt
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
#cat $PIO_RelDIR/pio-release-info.txt
# ..............................................
# Release-Info as shell-file to import variables
# ..............................................
echo -e "    ...to: $(shortFP "$PIO_RelDIR"/)$eTG"pio-release-info.sh"$eNO"
rm -f "$PIO_RelDIR"/pio-release-info.sh  # Remove potential old file
cat <<EOL > "$PIO_RelDIR"/pio-release-info.sh
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
rlIdfTag="$IDF_Tag_closest"
# Release-Download https://github.com/espressif/esp-idf/releases/
rlIDF_DL_URL="$IDF_DL_URL"
rlIDF_DL_FN="$IDF_DL_NAME"

# <arduino-esp32> - Used for the build:
rlAR="$pioAR_verStr"

# Build for this targets:
rlTagets="$TargetsHyphenSep"
# -----------------------------------------------------
# Build with this <esp32-arduino-lib-builder>:
# -----------------------------------------------------
# $esp_AR_libBuilder_Url
EOL
chmod +x "$PIO_RelDIR"/pio-release-info.sh
#cat "$PIO_RelDIR"/pio-release-info.sh
#--------------------------------------------
# Display CREATED OUTPUT Message
#--------------------------------------------
read -r -d 'XXX' textToOutput <<EOL
------------------------------------------------------------------------------------
PIO <framework-arduinoespressif32> CREATED  
------------------------------------------------------------------------------------
OUTPUT is placed at:
   ...Files for PIO Framework needs
   $ePF $PIO_frmwkDIR $eNO
   ... Perpared for release on Github
   ... e.g. at $eGI https://github.com/twischi/platform-espressif32 $eNO
   $ePF $PIO_RelDIR $eNO
      $eUS $pioArchFN $eNO
      ... READY to be released
XXX
EOL
echo -e "$textToOutput"
echo "------------------------------------------------------------------------------------"
echo -e "                                 PIO DONE!"
echo "===================================================================================="
# echo -e "STOPPED HERE"; exit 0
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

# --------------------------------------------------------------------------------
# Read (YOUR) configuration: Gets userGH & tokenGH, needed for GitHub authentication
# --------------------------------------------------------------------------------
source config/config.sh # Used for API calls

clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# ---------------------------------------------------------
# Check if the script is called with 'dryrun' as argument
# -> Set and export flag 'dryrun'
# ---------------------------------------------------------
[ "$1" == "dryrun" ] && echo -e "--- DRY-RUN MODE ---\n"  || NdR=1 # Set flag for dry-run
# $NdR Set = Dry-run- // Unset = Real run >> [ $NdR ] && COMMEAND
# -----------------------------------------
# Get variables 
# -----------------------------------------
# ... Base Folder Structure
LIB_BUILD=$(realpath "$(pwd)")         # Root-Folder of Lib-builder
oneUpDir=$(realpath "$(pwd)"/../)      # DIR above the Lib-builder
echo "oneUpDir: "    $oneUpDir
echo LIB_BUILD:      $LIB_BUILD
# ... Load the varialbes and functions for pretty output
source $oneUpDir/addOns-esp32_AR_lib-builder//myToolsEnhancements.sh
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
echo "===================================================================================="
echo "                            Create  Stuff for PIO release"
echo "------------------------------------------------------------------------------------"
# -----------------------------------------------
# Fill PIO Framework Folders = from build output 
# ----------------------------------------------
# Folder Name for this release                   (e.g. 2024-11-15_IDF_v5.3.1-AR_3.1.0_esp32h2)
releaseMainFN=$(date +"%Y-%m-%d")"_"$pioIDF_verStr"-"$pioAR_verStr"_"$TargetsHyphenSep
OUT_PIO=$PIO_Out_DIR"/"$releaseMainFN"/framework-arduinoespressif32"
#echo "OUT_PIO: $OUT_PIO" && exit  
[ -d "$OUT_PIO" ] && [ $NdR ] && rm -rf "$OUT_PIO"   # Remove old folder if exists
[ $NdR ] && mkdir -p dist "$OUT_PIO"             # Make sure Folder exists
OUT_PIO_Release=$PIO_Out_DIR"/"$releaseMainFN"/forRelease"
if [ ! $NdR ]; then
  echo -e "OUT_PIO:         "$(shortFP $OUT_PIO)
  echo -e "OUT_PIO_Release: "$(shortFP $OUT_PIO_Release)
fi
echo "....................................................................................."

#------------------------------------------------ 
# Correct .../tools/{target}/platformio-build.py 
#------------------------------------------------
echo -e " ...Correct 'platformio-build.py' of {target}s"
# Code block that is wrong and needs to be replaced 
searchBlock=$(cat <<EOL
FRAMEWORK_DIR = env.PioPlatform().get_package_dir("framework-arduinoespressif32")
FRAMEWORK_SDK_DIR = env.PioPlatform().get_package_dir(
    "framework-arduinoespressif32-libs"
)
EOL
)
# Correct code block for replacement
replaceBlock=$(cat <<EOL
# --------------------------------------------------------------
# PIO-create-archive.sh has replaced the following 2 lines, because 
# the code-block in 'esp32-arduino-lib-builder'-tool (LB) 
#
# in file:      'pio_start.txt'
# located at:   ./configs/ 
# is WRONG!
# -------------------------------------------------------------
# LB adds the wrong code of 'pio_start.txt' into 
# the 'platformio-build.py' of each {target} it build.
#
# This is happens when CMake calls 'copy-libs.sh' create/modify  
# the file:       platformio-build.py 
# where the wrong code-block end's up.
#
#  Hint there is also a 'pio_end.txt', what is correct.
# --------------------------------------------------------------
FRAMEWORK_DIR = env.PioPlatform().get_package_dir("framework-arduinoespressif32")
FRAMEWORK_SDK_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")
EOL
)
# Process files
find "$searchFolder" -type f -name "platformio-build.py" | while read -r file; do
    echo -e "Processing file: $(shortFP $file)"
    [ $NdR ] && perl -0777 -pi -e "s|\Q$searchBlock\E|$replaceBlock|g" "$file"
done
echo "....................................................................................."
#-----------------------
# dry-run - STOP HERE
#-----------------------
if [ ! $NdR ]; then
    echo "END OF dryrun = STOPPED HERE"; exit 0
fi
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
cp -rf "$AR_PATH"/cores "$OUT_PIO" # cores-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#-----------------------------------------
# PIO COPY 'tools' - FOLDER
#-----------------------------------------
mkdir -p "$OUT_PIO"/tools/partitions
cp -rf "$AR_PATH"/tools "$OUT_PIO" # tools-Folder      from 'arduino-esp32'  -IDF Components (GitSource)
#   Remove *.exe files as they are not needed
    rm -f "$OUT_PIO"/tools/*.exe   # *.exe in Tools-Folder >> remove 
cp -rf out/tools/esp32-arduino-libs "$OUT_PIO"/tools/  # from 'esp32-arduino-libs'       (BUILD output-libs)
#-----------------------------------------
# PIO COPY 'libraries' - FOLDER
#-----------------------------------------
cp -rf "$AR_PATH"/libraries "$OUT_PIO" # libraries-Folder  from 'arduino-esp32'  -IDF Components (GitSource)
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
# PIO CREATE NEW file: cores/esp32/        # core_version.h    from 'arduino-esp32' & 'esp-idf'  -IDF Components (GitSource)
#----------------------------------- 
# Get needed Info's for this file
AR_VERSION_UNDERSCORE=$(echo "$AR_VERSION" | tr . _)                         # Replace dots with underscores
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
ibr=$(git -C "$IDF_PATH" describe --all 2>/dev/null) # echo "ibr: $ibr"
python3 $LIB_BUILD/tools/gen_platformio_manifest.py -o "$OUT_PIO/" -s "$ibr" -c "$IDF_Commit_short"
if [ $? -ne 0 ]; then exit 1; fi
# echo "v$AR_VERSION"  "$IDF_Commit_short"
# -----------------------------------------------------
# PIO generate release-info that will be added archive
# -----------------------------------------------------
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
   * branch [$LB_BRANCH]
     https://github.com/twischi/esp32-arduino-lib-builder.git

Build for this targets:
   $TargetsHyphenSep
EOL
# cat "$OUT_PIO"/release-info.txt
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
cd $OUT_PIO/..              # Step to source-Folder
rm -f "$pioArchFP"          # Remove potential old file
mkdir -p "$OUT_PIO_Release" # Make sure Folder exists
#          <target>    <source> in currtent dir 
tar -zcf "$pioArchFP" framework-arduinoespressif32/
cd $LIB_BUILD            # Step back to Lib-Builder-Folder
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
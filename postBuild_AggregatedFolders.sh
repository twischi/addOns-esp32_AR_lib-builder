#!/bin/bash
# --------------------------------------------------
# Collects serveral Folders to a common location
# -------------------------------------------------
# This common locations will offer files needed to 
# for release process for PIO  
#
# 1) Save all downloads from GitHub in ONE folder, affects
#    - arduino-esp32 / /- esp-idf / - esp32-arduino-libs
#
# 2) Set OWN arduino-esp32-BUILD Output Folder location
# -------------------------------------------------

# ---------------------------------------
# FUNCTIONS to Create SYMLINK for Folders
# >> used below! 
# ---------------------------------------
create_symlink() {
    echo "~~~~~~~~~~~~~~~~~~ Create Symlink if needed ~~~~~~~~~~~~~~~~~~" 
    echo "Standard-PATH: $std_PATH"
    echo "Target  -PATH: $target_PATH"
    echo "---"
    mkdir -p "$target_PATH" # Target-Folder (no effect if it already exists)
    # Check if Standard-Folder is a SYMLINK?
    # >> Will be the CASE when this script has been CALLED BEFORE
    if [ ! -L "$std_PATH" ]; then # ask for "NOT a symlink"?
        
        # NOT NOT NOT a symlink yet
        echo "SYMLINK NOT existing yet @Standard-Folder= $std_PATH"
        echo "... Check if Standard-Folder exists?"
        
        # Is the Standard-Folder existing?
        if [ -d "$std_PATH" ]; then # ask "Is Path a directory"?
            # YES it is a directory & exists
            echo "... Standard-Folder EXISTS, cleanup needed"
            
            # >> MOVE the content of the Standard-Folder to the Target-Folder
            echo "... Move his (potential) content to Target-Folder= $target_PATH"
            mv -f "$std_PATH"/{.,}* "$target_PATH"/ # Include hidden files & folders
            
            # >> Delete the (now empty) Standard-Folder to be able to create a symlink
            echo "... Then delete the existing Standard-Folder=$std_PATH"
            rm -rf "$std_PATH"
        else 
            # NO Standard-Folder does not exist
            echo "... Standard-Folder NOT EXISTS --> Symlink will be created directly"
        fi

        # >> CREATE the symlink
        echo "... Create a symlink at Standard-Folder"
        # to this  <Target>    at    <link_name(Folder)> new Folder that's symlinked
        ln -s   "$target_PATH"       "$std_PATH" > /dev/null
    
    else
        # Symlink already EXIST
        echo "SIMLINK already EXITS @Standard-Folder --> NO action needed" && echo
    fi
}

# ------------------------------------------------------------------
# Move directories that has a GitHub sources to ONE a common folder
# ------------------------------------------------------------------
# Affects GitHub Download for 
# - arduino-esp32 / /- esp-idf / - esp32-arduino-libs
process_GH_Folder() {
    #clear
    local oneUpDir=$(realpath $(pwd)/../)  # Find directory above the current one
    GitHubSources=$oneUpDir/GitHub-Sources # GitHub-Sources-Folder
    mkdir -p "$GitHubSources"              # if not exists create the Target-Folder
    # -----------------------------------------
    # Set OWN Arduino Folder location (AR_PATH)
    # -----------------------------------------
    std_PATH=$(pwd)"/components/arduino"          # Standard-Folder in Scope
    target_PATH="$GitHubSources""/arduino-esp32"  # Target-Folder in Scope
    create_symlink # Call the function
    # -----------------------------------------
    # Set OWN IDF-Folder location (IDF_PATH)
    # -----------------------------------------
    std_PATH=$(pwd)"/esp-idf"                     # Standard-Folder in Scope
    target_PATH="$GitHubSources""/esp-idf"        # Target-Folder in Scope
    create_symlink # Call the function
    # ---------------------------------------------------
    # Set OWN arduino-esp32-BUILD Output Folder location
    # ---------------------------------------------------
    std_PATH="$PWD"/out                           # Standard-Folder in Scope
    target_PATH="$oneUpDir""/OUT-from_build"      # Target-Folder in Scope
    create_symlink # Call the function
    # ---------------------------------------------------
    # Set OWN arduino-esp32-BUILD Distribution Folder
    # ---------------------------------------------------
    std_PATH="$PWD"/dist                          # Standard-Folder in Scope
    target_PATH="$oneUpDir"/"OUT-from_build/dist" # Target-Folder in Scope
    create_symlink # Call the function
    # ----------------------------------------------
    # Set OWN Arduino Folder location (IDF_LIBS_DIR)
    # ----------------------------------------------
    # local Temp_PATH="$GitHubSources""/esp32-arduino-libs" # New Location
    # mkdir -p "$Temp_PATH" # if not exists create the Target-Folder
    # # Modify path to 'esp32-arduino-libs'
    # export IDF_LIBS_DIR=$(realpath "$Temp_PATH"/../)/esp32-arduino-libs
}     
# Option '-o' : Set OWN arduino-esp32-BUILD Output Folder location


#-------------------------------------------------------------------------------
# Function to extract file names from semicolon-separated paths and format them
#-------------------------------------------------------------------------------
extractFileName() {
    local configs="$1"
    # Convert the semicolon-separated string into an array
    IFS=';' read -ra paths <<< "$configs"   
    # Initialize an empty array to hold file names
    local helperArray=()
    # Iterate over each path and extract the file name
    for path in "${paths[@]}"; do
        local extractedFN
        extractedFN=$(basename "$path")
        helperArray+=("$extractedFN")
    done
    local result
    # Join the file names into a semicolon-separated string
    result=$(IFS=';'; echo "${helperArray[*]}")
    # Replace semicolons with " - " for better readability
    result=${result//;/ - }
    echo "$result"
}

# Function to shorten the File-Pathes for put buy remove parts
# usage: echo -e "$(shortFP "/Users/thomas/JOINED/esp32-arduino-lib-builder/out/tools")
shortFP() {   
    local filePathLong="$1"
    local removePart="$(realpath $(pwd)/../)/" # DIR above the current directory
    local filePathShort=$(echo "$filePathLong" | sed "s|$removePart||")     
    echo "$ePF$filePathShort$eNO"
}
echo "myTools & Enhancements > Variables & Functions loaded successfully."

# echo "Press Enter to continue..." && read

# Option '-G' : Save all downloads from GitHub in ONE folder, affect
# - arduino-esp32 / /- esp-idf / - esp32-arduino-libs
process_GH_Folder
# Option '-o' : Set OWN arduino-esp32-BUILD Output Folder location
#process_OWN_OutFolder_AR
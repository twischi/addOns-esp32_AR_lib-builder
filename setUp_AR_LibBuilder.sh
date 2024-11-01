#!/bin/bash
# --------------------------------------------------
# Setup for Arduino-Lib-Builderfor ESP32
# -------------------------------------------------
# Used my fork of the Arduino-Lib-Builder for ESP32
#
# 1) Deletes the Lib-Builder if it already exists
#    - Folder 'esp32-arduino-lib-builder'
#
# 2) Downloads the Lib-Builder and prepares it
#
# -------------------------------------------------
clear 
# ---------------------------
# Delete existing Lib-Builder
# ---------------------------
libBuilder_PATH="esp32-arduino-lib-builder"
libBuilder_PATH=$(realpath $libBuilder_PATH)
if [ -d "$libBuilder_PATH" ]; then
    # Folder exists
    echo "Lib-Builder Found @: "$libBuilder_PATH
    read -p "Folder 'esp32-arduino-lib-builder' exists. Delete it? (y/n) " -n 1 -r
    echo
    rm -rf "$libBuilder_PATH"
else 
    # Standard-Folder does not exist
    echo "Lib-Builder NOT FOUND"
    # It 
fi

# ---------------------
# Download from GitHub
# ---------------------
git clone https://github.com/twischi/esp32-arduino-lib-builder.git --quiet
echo "Current directory is now: $(pwd)"
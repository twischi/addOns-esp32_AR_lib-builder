# Add-on's for ESP32 Arduino Lib Builder

This repository holds add-on's used for **my fork** of Espressif's

[`twischi/esp32-arduino-lib-builder`](https://github.com/twischi/esp32-arduino-lib-builder)

**Be aware** my fork

contains code using code the uses Apple-MacOS script 'osascript'.

| add-on -File  |&nbsp;&nbsp; Description &nbsp;&nbsp;|
|:------------ | :--------------------------------------------------:|
| postBuild_AggregatedFolders.sh | The bash-scrict aggregats the folder of the common location used to PIO-out |

| PIO-create-archive.sh    | |

--------------------------------------------------
Collects serveral Folders to a common location
-------------------------------------------------
This common locations will offer files needed to 
for release process for PIO  

1) Save all downloads from GitHub in ONE folder, affects
   - arduino-esp32 / /- esp-idf / - esp32-arduino-libs

2) Set OWN arduino-esp32-BUILD Output Folder location
-------------------------------------------------
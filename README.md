# Add-on's for ESP32 Arduino Lib Builder

This repository holds **Add-on's** used with **my variant** [`twischi/esp32-arduino-lib-builder`](https://github.com/twischi/esp32-arduino-lib-builder) of Espressif's Arduino-Lib-Builder.

| Add-on-Script  | Description &nbsp;&nbsp;|
|:------------ | :--------------------------------------------------|
| ```bashpostBuild_AggregatedFolders.sh``` | Aggregates the folders of the **common**-location created by ```esp32-arduino-lib-builder``` **new lacation** |
| ```PIO-create-archive.sh``` | tbd.|

### Script: ```postBuild_AggregatedFolders.sh```

- Creates a **new folder-structure**
- And use it with  **symlink's** from original structure inside the esp32-arduino-lib-builder-Folder.

| Symlinked-Location | Original-Location|  
|:------------ | :--------------------------------------------------|
|`GitHub-Sources/arduino-esp32`| `esp32-arduino-lib-builder/components/arduino` |
|`GitHub-Sources/esp-idf`| `esp32-arduino-lib-builder/esp-idf` |
| &nbsp; | &nbsp; |
|```OUT-from_build```| ```esp32-arduino-lib-builder/out``` |
|```OUT-from_build/dist```| ```esp32-arduino-lib-builder/dist``` |

### Script: ```PIO-create-archive.sh```

to be done!

# PRAKED -  PARKED    - PARKED
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# from 'PIO-create-archive.sh'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#--------------------------------------------- 
# PIO modify .../tools//platformio-build.py 
#---------------------------------------------
echo -e " ...modfied '/tools//platformio-build.py' for FRAMEWORK_LIBS_DIR"
searchLineBy='FRAMEWORK_LIBS_DIR ='
 replaceLine='FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")'
sed -i '' "/^$searchLineBy/s/.*/$replaceLine/" "$OUT_PIO"/tools/platformio-build.py






# PRAKED -  PARKED    - PARKED
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# from 'PIO-create-archive.sh'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

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

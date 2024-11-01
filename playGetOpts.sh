#!/bin/bash

### Section 1: Process Main Script Option (-x) ###

# Parse the first option for the main script
#declare -p
#exit 0


#echo "run FIRST getopts"
#             optstring     name
#echo -e "\n1-START     Remaining arguments: $@"

gLoop=1
OPTIND=1
OPTERR=0
clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
while getopts "abx:y:" opt; do # This will process all options passed to the script
                                   # and compare if in optstring
                                   # to be passed to the script.
    echo -e "1 ... \t\t\t\t$gLoop OI="$OPTIND"  Curr. opt= <"$opt">  OPTARG= <"$OPTARG">"   
    case "$opt" in
        a)
            echo "1 ... >> -a was set" ;;
        b)
            echo "1 ... >> -b was set" ;;
        x)
            echo "1 ... >> -x was set with $OPTARG" ;;
        ?)
            echo "1 !?! >> Skipping -"$OPTARG ;;  
        *)
            echo "1 !*! >> Skipping -"$OPTARG ;;
        :)
            echo "1 !:! >> Skipping -"$OPTARG ;;  
    esac
    ((gLoop++))
done

OPTIND=1 # Reset the OPTIND to start from the beginning of given arguments in $@
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

gLoop=1
while getopts "y:x:cd" opt; do # This will process all options passed to the script
                                   # and compare if in optstring
                                   # to be passed to the script.
    echo -e "2 ... \t\t\t\t$gLoop OI="$OPTIND"  Curr. opt= <"$opt">  OPTARG= <"$OPTARG">"   
    case "$opt" in
        c)
            echo "2 ... >> -c was set" ;;
        d)
            echo "2 ... >> -d was set" ;;
        y)
            echo "2 ... >> -y was set with $OPTARG" ;;
        ?)
            echo "2 !?! >> Skipping -"$OPTARG ;;  
        *)
            echo "2 !*! >> Skipping -"$OPTARG ;;
        :)
            echo "21 !:! >> Skipping -"$OPTARG ;;  
    esac
    ((gLoop++))
done
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
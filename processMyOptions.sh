#!/bin/bash
# --------------------------------------------------
# ....sh
# -------------------------------------------------
# This script post-processes NEW options passed to 
# the build.sh script. That was not part
# of the original build.sh script.
# --------------------------------
echo "Loading processMyOptions.sh"
#-------------------------------
# Process Options that as passed
#-------------------------------
#while getopts ":A:    c: b: D: i:    I: t:    de  s"      opt
#while getopts ":A: a: c: b: D: i: g: I: t: T: delosGSVWX" opt
# The NEW Options
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# --- with Parameter
# a: AR_COMMIT
# g: AR_TAG
# T: IDF_TAG
#doIt() {
optWthArg="a:g:T:"
# --- Flags only
# l >  PIO_OUT_F
# o >  process_OWN_OutFolder_AR
# G >  process_GH_Folder
# S >  IDF_InstallSilent
# V >  IDF_BuildTargetSilent
# W >  IDF_BuildInfosSilent
# X >  IDF_ExportSilent
optFlags="GloSVWX"
optFlags="G" && optWthArg=""
echo -e "\n--------------------------    1) Given ARGUMENTS Process & Check    -----------------------------"
# "$optWthArg""$optFlags"  "a:g:T:GloSVWX"
while getopts "$optWthArg""$optFlags" optA; do
    case ${optA} in
    # with PARAMETER 
        # a )
        #     export AR_COMMIT="$OPTARG"
        #     echo -e "-a  <ar.-esp32>\t Set COMMIT to be used for compilation (AR_COMMIT):$eTG '$AR_COMMIT' $eNO"
        #     pioAR_verStr="AR_$AR_COMMIT"
        #     ;;
        # g )
        #     export AR_TAG="$OPTARG"
        #     echo -e "-g  <ar.-esp32>\t Set TAG to be used for compilation (AR_TAG):$eTG '$AR_TAG' $eNO"
        #     pioAR_verStr="AR_tag_$AR_TAG"
        #     ;;
        # T )
        #     export IDF_TAG="$OPTARG"
        #     echo -e "-G  <esp-idf>\t Set TAG to be used for compilation (IDF_TAG):$eTG '$IDF_TAG' $eNO"
        #     pioIDF_verStr="IDF_tag_$IDF_TAG"
        #     ;;
    # FLAGS
        G )
            echo -e "-G  <Git-Hub>\t Save GitHub Download to ONE folder."
            #process_GH_Folder "$Temporarily"            
            #echo -e "\t\t >> $ePF'../$(shortFP $GitHubSources)'"
        #     ;;
        # l )
        #     PIO_OUT_F=1
        #     echo -e '-l \tPIO\t Create structure & archive (PIO_OUT_F)=1'
        #     #echo -e "\t\t >> '$(shortFP "PIO")'"
        #     ;;
        # o )
        #     echo -e "-o \t..\t Use a own OUT-Folder for build-outputs:"
        #     #process_OWN_OutFolder_AR
        #     #echo -e "\t\t >> $ePF'../$(shortFP $AR_Build_Output)'"
        #     ;;
        # S )
        #     IDF_InstallSilent=1
        #     echo -e '-S  <esp-idf>\t Silent mode for installing ESP-IDF and components'
        #     ;;
        # V )
        #     IDF_BuildTargetSilent=1
        #     echo -e '-V \tbuild\t Silent mode for building Targets with idf.py'
        #     ;;
        # W )
        #     IDF_BuildInfosSilent=1
        #     echo -e '-W \tOutput\t Silent mode for building of Infos.'
        #     ;;
        # X )
        #     SKIP_BUILD=1
        #     echo -e '-X \tbuild\t Skip building for TESTING DEBUGING.'
        #     ;;
        # * ) echo "Invalid option: $opt"
        #     ;;
    esac
done
echo -e   "------------------------------     DONE:  processing ARGUMENTS     ------------------------------\n"
# echo "Remaining arguments: $@"
# echo $OPTIND 
shift $((OPTIND -1))

echo "Remaining arguments: $@"
# exit 0
#}
echo "processMyOptions.sh loading DONE"

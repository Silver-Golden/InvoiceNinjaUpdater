#!/bin/bash -ue
#Invoice Ninja Self-Hosted Automatic Update
#This version will check https://invoiceninja.org for an updated version and install if found.
#Tested and works with cron. Lines 51, 54, & 79 output timestamps so you can pipe to a logfile.
#USE AT YOUR OWN RISK
 
# Load config values
source config.conf
 
#SET INITIAL VARIABLES
#Remaining variables will be set if an update is required
#--------------------------------------------------------
ninja_storage="$ninja_home/storage"
versiontxt="$ninja_storage/version.txt"
storage_owner="$storage_owner"
storage_group="$storage_group"
 
 
#GET INSTALLED AND CURRENT VERSION NUMBERS
#--------------------------------------------------------
ninja_installed=$(cat "$versiontxt")
ninja_current=$((wget -qO- https://invoiceninja.org/index.php) | (grep -oP 'Download Version \K[0-9]+\.[0-9]+(\.[0-9]+)'))
 
 
#SEE IF AN UPDATE IS REQUIRED
#--------------------------------------------------------
update_required="no"
set -f
array_ninja_installed=(${ninja_installed//./ })
array_ninja_current=(${ninja_current//./ })
 
if (( ${#array_ninja_installed[@]} == "2" ))
then
    array_ninja_installed+=("0")
fi
 
for ((i=0; i<${#array_ninja_installed[@]}; i++))
do
    if (( ${array_ninja_installed[$i]} < ${array_ninja_current[$i]} ))
    then
    update_required="yes"
    fi
done
 
 
#MAIN UPDATE SECTION
#--------------------------------------------------------
case $update_required in
    no)
    printf '%s - Invoice Ninja v%s is installed and is current. No update required.\n' "$(date)" "$ninja_installed"
    ;;
    yes)
    printf '\n%s - Updating Invoice Ninja from v%s to v%s.\n\n' "$(date)" "$ninja_installed" "$ninja_current"
 
    #Set remaining variables
    tempdir="$tempdir/InvoiceNinja"
    ninja_temp="$tempdir/ninja"    
    ninja_file="ninja-v$ninja_current.zip"
    ninja_url="https://download.invoiceninja.com/$ninja_file"
    ninja_zip="$tempdir/$ninja_file"
   
    printf 'Downloading Invoice Ninja v%s archive "%s" ...\n\n' "$ninja_current" "$ninja_url"
    wget -P "$tempdir/" "$ninja_url"
   
    printf 'Extracting to temporary folder "%s" ...\n\n' "$tempdir"
    unzip -q "$ninja_zip" -d "$tempdir/"
   
    printf 'Syncing to install folder "%s" ...\n' "$ninja_home"
    sudo rsync -tr --stats "$ninja_temp/" "$ninja_home/"
   
    printf '\nResetting permissions for "%s" ...\n\n' "$ninja_storage"
    sudo chown -R "$storage_owner":"$storage_group" "$ninja_storage/"
    sudo chmod -R 775 "$ninja_storage/"
   
    printf 'Removing downloaded ZIP file "%s" ...\n\nRemoving temporary folder "%s" ...\n\n' "$ninja_zip" "$tempdir"
    rm -rf "$tempdir/"
   
    printf 'Running update migration commands (%s/update)...\n\n' "$app_url"
    wget -q --spider "$app_url/update"
   
    printf '%s - Invoice Ninja successfully updated to v%s!\n\n' "$(date)" "$ninja_current"
    ;;
esac
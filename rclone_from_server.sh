#!/bin/bash

################################################################################
# Script to use rclone to sync data between various sources and destinations.
# The script uses a config file to set some options, including
#   a list of source and destination servers and paths
#
# rclone is avialable from: https://rclone.org/
# SMB is supported in rclone versions 1.6 and on
# 
# Sends email notifications of completion.
#
# Matt Gitzendanner
#
# Version 1.0: 4/11/2024
#        - Copy from rsync 1.2 version of the script.
#        
#
# To run via cron daily:
# $ crontab -e
# Then edit that to have (there shouldn't be any output for cron to mail, but just in case...):
# MAILTO="email@some.com"
# 0 5 * * * /path/rclone_from_server.sh >/dev/null 2>&1
# That will run this at 5am every day.
################################################################################

# On HiPerGator, we need to load the rclone module
module load rclone

################################################################################
# Configuration options are sourced from a config file.
Config_file='/home/magitz/MyApps/UFRC_scripts/Soltis_rclone_BU.settings.cfg'

# Read the config file
source $Config_file

# Set log file
Log_file=${Log_file_path}/${Log_file_prefix}_`date +%F`.log

# Parse the config file
while IFS= read -r line
do
    # Skip comment and blank lines in the Backup_list string
    if [[ `echo $line | egrep '#'` ]] || [[ -z $line ]]
    then
      continue
    else
      # Parse the current line of Backup_list
      backup=($line)
      config1=${backup[0]}
      path1=${backup[1]}
      config2=${backup[2]}
      path2=${backup[3]}
    fi


    # Set server:path or path for rsync
    if [[ $config1 == "local" ]]
    then
        config_path1=$path1
    else
        config_path1=$config1:$path1
    fi

    if [[ $config2 == "local" ]]
    then
        config_path2=$path2
    else
        config_path2=$config2:$path2
    fi

    # rclone options used:
    # copy: Copy files from source to dest, skipping already copied.
    # --stats-one-line-date: Print one line of stats per run with date.
    # --stats=60: Print stats every 60 minutes (vs default of 1 min).
    # --human-readable: Print numbers in a human-readable format, sizes with suffix Ki|Mi|Gi|Ti|Pi
    # --log-file string  
    # --log-level INFO  Log level DEBUG|INFO|NOTICE|ERROR (default NOTICE)

    echo `date` ": Starting: rclone copy --stats=60m --stats-one-line-date --human-readable --log-file $Log_file --log-level INFO $config_path1 $config_path2" >> $Log_file
    rclone copy --stats=60m --stats-one-line-date --human-readable --log-file $Log_file --log-level INFO $config_path1 $config_path2 

    # Fill log with line for easy reading...
    echo `date` ": Finished!" >> $Log_file
    echo "--------------------------------------------------------------------------------------------------------------" >> $Log_file

done <<< "$Backup_list"

# Notify user that backup ran.
SUBJECT="HiPerGator rclone copy ran"
cat $Log_file | mail -s "$SUBJECT" "$Email"

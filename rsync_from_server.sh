#!/bin/bash

################################################################################
# Script to rsync data between various sources and destinations.
# The script uses a config file to set some options, including
#   a list of source and destination servers and paths
#
# Sends email notifications of completion.
#
# Matt Gitzendanner
#
# Version 1.0: 07/12/18
#         1.1: 11/05/18
#               Changes to source config options from file
#               Allows for multiple source and destination servers/paths
#         1.2: 06/21/22
#               Move summary file date code before loop to keep multi-day
#                    runs in the same file.
#
# To run via cron daily:
# $ crontab -e
# Then edit that to have (there shouldn't be any output for cron to mail, but just in case...):
# MAILTO="email@some.com"
# 0 5 * * * /path/rsync_from_server.sh >/dev/null 2>&1
# That will run this at 5am every day.
################################################################################

################################################################################
# Configuration options are sourced from a config file.
Config_file='BU.settings.cfg'

# Read the config file
source $Config_file

# Set summary file
Summary_file=$Summary_file_prefix`date +%F`.log

# Handle errors during rsync.
function trap_clean {
    # Error handling...
    echo -e "$(hostname) caught error on line $LINENO at $(date +%l:%M%p) via script $(basename $0)" | tee -a $Error_file $Log_file
    echo -e "Please see the tail end of $Log_file for additional error details...">> $Error_file
    mail -s "ALERT: Backup Error Caught for $Server_address" "$Email" < $Error_file
    exit # Exit if error caught.
}
# Defined trap conditions
trap trap_clean ERR SIGHUP SIGINT SIGTERM

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
      server1=${backup[0]}
      path1=${backup[1]}
      server2=${backup[2]}
      path2=${backup[3]}
    fi


    # Set server:path or path for rsync
    if [[ $server1 == "local" ]]
    then
        serverpath1=$path1
    else
        serverpath1=$server1:$path1
    fi

    if [[ $server2 == "local" ]]
    then
        serverpath2=$path2
    else
        serverpath2=$server2:$path2
    fi

    # rsync options used:
    #   -a archive mode
    #   -z compress
    #   -h human reabable sizes
    #   --stats report rsync stats
    echo "rsync -azh --stats $serverpath1 $serverpath2 >> $Log_file 2>> $Error_file"
    rsync -azh --stats $serverpath1 $serverpath2 >> $Log_file 2>> $Error_file

    # Fill log with line for easy reading...
    date >> $Log_file
    echo "--------------------------------------------------------------------------------------------------------------" >> $Log_file

    # Write summary to today's log file.
    echo "Finished rsync of $serverpath1 to $serverpath2" >> $Summary_file
    tail -n16 $Log_file >> $Summary_file
    echo "--------------------------------------------------------------------------------------------------------------" >> $Summary_file_prefix`date +%F`.log

done <<< "$Backup_list"

# Notify user that backup ran.
SUBJECT="$Server_address backup ran"
cat $Summary_file | mail -s "$SUBJECT" "$Email"

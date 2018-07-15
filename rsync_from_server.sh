#!/bin/bash

################################################################################
# Script to rsync a folder to a backup server.
# Currently, this is configured to pull the data to the backup server.
# In other words, it runs on the backup server and pulls from the source.
#
# Sends email notifications of completion.
#
# Matt Gitzendanner
#
# Version 1.0: 07/12/18
#
# To run via cron daily:
# $ crontab -e
# Then edit that to have (there shouldn't be any output for cron to mail, but just in case...):
# MAILTO="email@some.com"
# 0 5 * * * /path/rsync_from_server.sh >/dev/null 2>&1
# That will run this at 5am every day.
################################################################################

################################################################################
# Configuration options. Change these as needed.
################################################################################

Path_to_backup='/path/on/server/Backup/' #Path to the folder to rsync
Log_file='rsync_backup.log' #Daily log file name
Error_file='rsync_errors.log'
Email='email@some.com' #Where to send emails on alert
Server_address='server.address.some.com' # Original server name or IP
Server_user='user' # Username to login to the backup server with
# Note, you should have the ssh key set so you can login without a password.
Dest_path='/local/path/Backup/' # Where to store the data on the backup server.

################################################################################
################################################################################


function trap_clean {
    # Error handling...
    echo -e "$(hostname) caught error on line $LINENO at $(date +%l:%M%p) via script $(basename $0)" | tee -a $Error_file $Log_file
    echo -e "Please see the tail end of $Log_file for additional error details...">> $Error_file
    mail -s "ALERT: Backup Error Caught for $Server_address" "$Email" < $Error_file
}

# Defined trap conditions
trap trap_clean ERR SIGHUP SIGINT SIGTERM

# rsync options used:
#   -a archive mode
#   -z compress
#   -h human reabable sizes
#   --stats report rsync stats
#   -e use ssh
echo "rsync -azh --stats -e $Server_address:$Path_to_backup $Dest_path >> $Log_file 2>> $Error_file"
      rsync -azh --stats -e $Server_address:$Path_to_backup $Dest_path >> $Log_file 2>> $Error_file

# Fill log with line for easy reading...
date >> $Log_file
echo "--------------------------------------------------------------------------------------------------------------" >> $Log_file


# Notify user that backup ran.
SUBJECT="$Server_address backup ran"
tail -n16 $Log_file | mail -s "$SUBJECT" "$Email"

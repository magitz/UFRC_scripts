#!/bin/bash

################################################################################
# Script to monitor storage space on LFS filesystem.
#
# Sends email warnings when space free falls below configured value, space used
# changes more than configured value, or quota changes between runs.
# All quota data is saved to a log file, which shouldn't get too big as it's only
# being added to once a day. If you run more often, might need to purge now and then.
#
#
# Matt Gitzendanner
#
# Version 1.0: 8/16/16
#
# To run via cron daily:
# $ crontab -e
# Then edit that to have (there shouldn't be any output for cron to mail, but just in case...):
# MAILTO="magitz@ufl.edu"
# 0 5 * * * /home/magitz/bin/lfs_storage_check.sh >/dev/null 2>&1
# That will run this at 5am every day.
################################################################################

################################################################################
# Configuration options. Change these as needed.
################################################################################
Group='YOUR_GROUP' #Group to check
Filesystem='/ufrc' #Filesystem to check
LogFile='PATH_TO_LOG_FILE_TO_MAKE' #Daily log file name
DailyChangeAlert=0.25 #Daily change to allert over. In TB
FreeSpaceAlert=1 #Total free space to allert over. Also in TB
Email='YOUR_EMAIL' #Where to send emails on alert
KBtoTB=1073741824 #Number to convert KB to TB or visa-versa.

################################################################################
################################################################################


#Get group usage and add to log file in the format:
# Date Used Quota Free
lfs quota -g $Group $Filesystem | grep $Filesystem | \
  awk '{free = $3-$2; print strftime("%Y-%m-%d"), $2,  $3, free}' \
  >> $LogFile
 
# Get the last 2 entries from the log file: the most recent and the one before to compare to.
# Convert numbers to TB dividing by $KBtoTB using bc as bash doesn't do math!
IFS=' '
Today=`tail -n 1 $LogFile`
set $Today
TodayUsed=$2
TodayQuota=$3
TodayFree=$4

#Let's go ahead and get the TB equivalents of these, note the -l in bc to get more decimals.
TodayUsedTB=$(echo "$TodayUsed / $KBtoTB" | bc -l)
TodayQuotaTB=$(echo "$TodayQuota / $KBtoTB" | bc -l)
TodayFreeTB=$(echo "$TodayFree / $KBtoTB" | bc -l)
   
Yesterday=`tail -n 2 $LogFile | head -n 1`
set $Yesterday
YesterdayUsed=$2
YesterdayQuota=$3
YesterdayFree=$4

#Let's go ahead and get the TB equivalents of these:
YesterdayUsedTB=$(echo "$YesterdayUsed / $KBtoTB" | bc -l)
YesterdayQuotaTB=$(echo "$YesterdayQuota / $KBtoTB" | bc -l)
YesterdayFreeTB=$(echo "$YesterdayFree / $KBtoTB" | bc -l)


#Calculate changes
ChangeUsed=$((TodayUsed - YesterdayUsed ))
ChangeQuota=$((TodayQuota - YesterdayQuota ))
ChangeFree=$((TodayFree - YesterdayFree ))

#Let's go ahead and get the TB equivalents of these:
ChangeUsedTB=$(echo "$ChangeUsed / $KBtoTB" | bc -l)
ChangeQuotaTB=$(echo "$ChangeQuota / $KBtoTB" | bc -l)
ChangeFreeTB=$(echo "$ChangeFree / $KBtoTB" | bc -l)


#Send email if the change in space used between runs is greater than $DailyChangeAlert
if [ $(echo "$ChangeUsedTB > $DailyChangeAlert" | bc) -eq 1 ] #Bash doesn't work with Floats, so need to use bc
then
  SUBJECT="Warning $Group $Filesystem daily change alert "

  printf "Warning daily change in storage used on $Filesystem by group $Group is greater than %.2f TB!! \n Yesterday's usage was %.2f TB, today it's %.2f TB. \n There is still %.2f TB free space available." $DailyChangeAlert $YesterdayUsedTB $TodayUsedTB $TodayFreeTB \
   | mail -s "$SUBJECT" "$Email" 
fi

#Send email if the group's quota has changed since previous run.
if [ $ChangeQuota -ne 0 ]
then
   SUBJECT="Warning $Group $Filesystem quota change alert"   

  printf "Warning the quota for group $Group on $Filesystem has changed!! \n Yesterday it was %.2f TB, today it's %.2f TB. \n There is still %.2f TB free space available." $YesterdayQuotaTB $TodayQuotaTB $TodayFreeTB \
   | mail -s "$SUBJECT" "$Email" 

fi

#Send email is the free space is lower than FreeSpaceAlert
if [ $(echo "$TodayFreeTB < $FreeSpaceAlert" | bc) -eq 1 ]
then
  SUBJECT="Warning $Group $Filesystem low space alert"
  
  printf "Warning group $Group has only %.2f TB free space one $Filesystem!!" $TodayFreeTB \
   | mail -s "$SUBJECT" "$Email" 
fi

#Provide a weekly summary of filesystem use
if [[ $(date '+%a') == "Mon" ]]
then 
  SUBJECT="$Group $Filesystem Weekly Space Report"

  printf "All looks good.\n The group $Group is using %.2f TB of its %.2f TB quota, leaving %.2f TB free space on $Filesystem." $TodayUsedTB $TodayQuotaTB $TodayFreeTB \
   | mail -s "$SUBJECT" "$Email" 
 
fi

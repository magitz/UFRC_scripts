# UFRC_scripts
Helpful scripts for users of UF Research Computing

This repository will be used to collect various scripts that I write for doing things on HiPerGator, the [University of Florida](http://www.ufl.edu/)'s computer cluster managed by [Research Computing](https://www.rc.ufl.edu/).

While I do work for Research Computing, these scripts are NOT official scripts and are not a product of UF Research Computing. These are scripts that I wrote to make my life as a researcher easier. All of these can be run without any special privileges. 

## lfs_storage_check.sh
This script is the first script I made for the repo (and so far the only one!). I wrote this after our lab group ran into our storage quota a few times causing frustration for our users whose jobs died as they ran out of space to write output. UFRC uses a [Lustre](http://lustre.org/) filesystem with quotas enforced at the group level.

The script is designed to run daily through cron on a [daemon node](https://wiki.rc.ufl.edu/doc/Daemons) and compare today's group storage use to yesterday's. It will send email alerts:
1. If the amount of space used increases by a configured value (DailyChangeAlert)
2. The amount of free space falls below a configured value (FreeSpaceAlert)
3. The disk quota changes 
4. A weekly summary with current use.

Other than configuring the alert values, group name, filesystem name and email, there isn't much to it. Set it to run daily with cron and have some piece of mind that storage space isn't going to cause problems for your group.

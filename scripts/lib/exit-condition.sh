#!/usr/bin/env zsh

############################################################################################
##
## Script to Create Exit Condition File for SecondSon Baseline
##
## This script creates a marker file to signal that the Baseline script
## should not execute again. It MUST be the last script in the SecondSon
## Scripts array to ensure all other scripts complete successfully first.
##
## The marker path MUST match var.baseline_exit_condition in the Terraform
## (rendered into the SecondSon mobileconfig as ExitCondition). On its next
## startup, Baseline checks that path and exits silently if it exists.
##
## The marker path is deliberately OUTSIDE /usr/local/Baseline/ because
## Baseline's CleanupAfterUse=true deletes that directory after a
## successful run, which would otherwise wipe the marker we just wrote.
##
## /var/db/ is a system path that survives reboots and Baseline cleanup,
## and is wiped on a device reset/re-enrolment — which is the correct
## behaviour (a wiped device should re-run baseline).
##
## IDEMPOTENT: Safe to re-run, checks if marker already exists
##
############################################################################################

# Define variables
scriptname="Create Baseline Exit Condition"
logdir="/Library/IntuneScripts/createBaselineExitCondition"
log="$logdir/createBaselineExitCondition.log"
exit_condition_file="/var/db/.talieisin-baseline-complete"

# Prepare logging directory
if [[ -d $logdir ]]; then
    echo "# $(date) | Log directory already exists - $logdir"
else
    echo "# $(date) | Creating log directory - $logdir"
    mkdir -p "$logdir"
fi

# Start logging
exec 1>> "$log" 2>&1

echo ""
echo "##############################################################"
echo "# $(date) | Starting $scriptname"
echo "##############################################################"
echo ""

# Check if exit condition file already exists
if [[ -f "$exit_condition_file" ]]; then
    echo "$(date) | Exit condition file already exists at $exit_condition_file"
    echo "$(date) | No action needed. Exiting script."
    exit 0
else
    echo "$(date) | Exit condition file not found. Proceeding to create it."
fi

# Create the directory for the exit condition file if it doesn't exist
exit_condition_dir=$(dirname "$exit_condition_file")
if [[ ! -d "$exit_condition_dir" ]]; then
    echo "$(date) | Creating directory for exit condition file: $exit_condition_dir"
    mkdir -p "$exit_condition_dir"
fi

# Create the exit condition file with a timestamp
echo "$(date) | Creating exit condition file at $exit_condition_file"
echo "Baseline script completed on $(date)" > "$exit_condition_file"

# Set appropriate permissions
chmod 644 "$exit_condition_file"
echo "$(date) | Set permissions to 644 for $exit_condition_file"

echo "$(date) | Exit condition file created successfully. Script completed."

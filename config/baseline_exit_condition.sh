#!/usr/bin/env zsh

############################################################################################
##
## Script to Create Exit Condition File for Baseline Script
##
## This script creates a marker file to signal that the Baseline script
## should not execute again. It follows the structure and logging practices
## of the provided local admin account creation script.
##
############################################################################################

# Define variables
scriptname="Create Baseline Exit Condition"
logdir="/Library/IntuneScripts/createBaselineExitCondition"
log="$logdir/createBaselineExitCondition.log"
exit_condition_file="/usr/local/Baseline/baseline_exit_condition"

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
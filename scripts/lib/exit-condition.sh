#!/usr/bin/env zsh

############################################################################################
##
## Mark SecondSon Baseline as provisioned for this device.
##
## Final lifecycle script in the SecondSon Baseline Scripts array. Writes a
## marker file that bootstrap.sh's Phase 3 short-circuit checks before
## re-installing the Baseline pkg + re-running Baseline.
##
## SOURCE OF TRUTH for the marker path:
##   `SECONDSON_BASELINE_EXIT_CONDITION` managed pref in
##   /Library/Managed Preferences/com.talieisin.baseline.plist
##   (rendered by Terraform from var.baseline_exit_condition).
##
## The script reads that managed pref so the marker path is configurable
## from Terraform without editing this script. If the pref is unset (which
## shouldn't happen in normal operation), the script logs a warning and
## exits without writing — Phase 3 will then re-run on the next bootstrap.
##
## MARKER CONTENTS (forensic only, not parsed):
##   version=<SECONDSON_BASELINE_VERSION>
##   completed=<ISO 8601 UTC timestamp>
##   hostname=<device name>
##
## bootstrap.sh treats the marker as a binary signal — presence = skip,
## absence = run. The contents exist for IT support: `cat /var/db/...`
## shows what version provisioned the device and when.
##
## Operator contract (see baseline/README.md):
##   Bumping `var.secondson_baseline_version` does NOT auto-upgrade existing
##   devices. To force re-run on the fleet, deploy a one-off Intune script
##   that removes the marker, then redeploy bootstrap.sh.
##
## CleanupAfterUse=true deletes /usr/local/Baseline/ after a successful
## Baseline run; we deliberately write to /var/db/ instead so the marker
## survives. /var/db/ is also wiped on a device reset/re-enrolment — which
## is the correct behaviour (a fresh device should re-run baseline).
##
## IDEMPOTENT: safe to re-run; overwrites the marker on each successful run.
##
############################################################################################

scriptname="Create Baseline Exit Condition"
logdir="/Library/IntuneScripts/createBaselineExitCondition"
log="$logdir/createBaselineExitCondition.log"
pref_domain="com.talieisin.baseline"
managed_prefs="/Library/Managed Preferences/$pref_domain"

# Prepare logging directory
mkdir -p "$logdir"
exec 1>> "$log" 2>&1

echo ""
echo "##############################################################"
echo "# $(date) | Starting $scriptname"
echo "##############################################################"
echo ""

# Read the marker path + version from managed prefs (the rendered mobileconfig
# is the single source of truth for both).
exit_condition_file=$(/usr/bin/defaults read "$managed_prefs" SECONDSON_BASELINE_EXIT_CONDITION 2>/dev/null || echo "")
baseline_version=$(/usr/bin/defaults read "$managed_prefs" SECONDSON_BASELINE_VERSION 2>/dev/null || echo "unknown")

if [[ -z "$exit_condition_file" ]]; then
    echo "$(date) | ERROR: SECONDSON_BASELINE_EXIT_CONDITION not set in $managed_prefs"
    echo "$(date) | Refusing to write marker without a configured path. Exiting."
    exit 1
fi

# Ensure parent dir exists (normally /var/db, which is always present).
exit_condition_dir=$(dirname "$exit_condition_file")
if [[ ! -d "$exit_condition_dir" ]]; then
    echo "$(date) | Creating parent directory: $exit_condition_dir"
    mkdir -p "$exit_condition_dir"
fi

# Write the marker file. Contents are forensic (not parsed by bootstrap.sh).
# Overwrite unconditionally so re-runs after a force-remove + re-provision
# capture the latest version/timestamp.
echo "$(date) | Writing exit condition marker at $exit_condition_file"
completed_ts=$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)
hostname=$(/bin/hostname -s 2>/dev/null || echo "unknown")
cat > "$exit_condition_file" <<EOF
version=$baseline_version
completed=$completed_ts
hostname=$hostname
EOF

chmod 644 "$exit_condition_file"
chown root:wheel "$exit_condition_file" 2>/dev/null || true

echo "$(date) | Marker written: version=$baseline_version completed=$completed_ts"
echo "$(date) | Script completed successfully."

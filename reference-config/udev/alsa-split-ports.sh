#!/usr/bin/env bash
VENDOR_ID="0x10ec0295"
SUBSYSTEN_ID="0x103c8575"
HINTS="indep_hp = yes
vmaster = no
"

# log output to system log
exec 1> >(logger -s -t "$(basename "$0")") 2>&1

get_codec() {
    local vendor_id=$1
    local subsystem_id=$2
    [[ -z "$vendor_id" || -z "$subsystem_id" ]] && { echo "ERROR: Not enough arguments given"; return; }
    for hw in /sys/class/sound/card*/hwC*D*; do
        if grep -q "$vendor_id" "$hw/vendor_id" && grep -q "$subsystem_id" "$hw/subsystem_id"; then
            echo "Found matching codec: $hw $(cat "$hw"/vendor_name) - $(cat "$hw"/chip_name) Vendor Id: $(cat "$hw"/vendor_id) Subsystem Id: $(cat "$hw"/subsystem_id)"
            codec=$hw
            break
        fi
    done
}

codec=""
get_codec "$VENDOR_ID" "$SUBSYSTEN_ID"

if [[ -z "$codec" ]]; then
  echo "ERROR: Could not get codec for VENDOR_ID: $VENDOR_ID SUBSYSTEN_ID: $SUBSYSTEN_ID"
  echo "Codecs found:"
  for hw in /sys/class/sound/card*/hwC*D*; do
    echo "$hw" "$(cat "$hw"/vendor_name)" - "$(cat "$hw"/chip_name)" Vendor Id: "$(cat "$hw"/vendor_id)" Subsystem Id: "$(cat "$hw"/subsystem_id)"
  done
  exit 1
fi


while IFS=$'\n' read -r line; do
  if [[ -z "$line" ]]; then
      continue
  fi
  echo "$line > ${codec}/hints"
  echo "$line" > "${codec}"/hints
done <<< "$HINTS"

echo "echo 1 > ${codec}/reconfig"
echo 1 > "${codec}"/reconfig

# give some time to intialize before restoring
sleep 5
alsactl restore

#!/usr/bin/env bash
set -euo pipefail
# Prefer a modern iPhone close to a 390pt-wide reference.
PREFERRED_MODELS=("iPhone 17" "iPhone 16" "iPhone 16e" "iPhone 17e" "iPhone Air")
DEVICES="$(xcrun simctl list devices available)"
echo "$DEVICES"
pick() {
  local model="$1"
  echo "$DEVICES" | awk -v model="$model" '
    $0 ~ "iOS" { os=$0; gsub(/--/, "", os); gsub(/^[[:space:]]+/, "", os) }
    $0 ~ model && $0 ~ "\\(" {
      id=$0
      gsub(/.*\\(/, "", id)
      gsub(/\\).*/, "", id)
      print model "|" os "|" id
      exit
    }'
}
SELECTED=""
for model in "${PREFERRED_MODELS[@]}"; do
  SELECTED="$(pick "$model" || true)"
  if [[ -n "$SELECTED" ]]; then
    break
  fi
done
if [[ -z "$SELECTED" ]]; then
  SELECTED="$(echo "$DEVICES" | awk '
    $0 ~ "iPhone" && $0 ~ "\\(" {
      name=$0
      gsub(/^[[:space:]]+/, "", name)
      gsub(/ \\(.*/, "", name)
      id=$0
      gsub(/.*\\(/, "", id)
      gsub(/\\).*/, "", id)
      print name "|available|" id
      exit
    }')"
fi
IFS='|' read -r SIM_NAME SIM_OS SIM_UDID <<< "$SELECTED"
echo "SIM_NAME=$SIM_NAME" >> "$GITHUB_ENV"
echo "SIM_OS=$SIM_OS" >> "$GITHUB_ENV"
echo "SIM_UDID=$SIM_UDID" >> "$GITHUB_ENV"
echo "Selected simulator: $SIM_NAME ($SIM_OS) $SIM_UDID"

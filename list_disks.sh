#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

[ "${SHELLCHECK:-0}" == "1" ] && shellcheck "$0"

readarray -t uuids < <(find /dev/disk/by-uuid -mindepth 1 -maxdepth 1 -type l -printf "%f\n")

for uuid in "${uuids[@]}" ; do
    block_device="$(readlink -f /dev/disk/by-uuid/"$uuid")"
    printf '%s -> %s\n' "$uuid" "$block_device"
    awk -v 'device='"$block_device" '
    {
        if ($1 == device) {
            printf(" - %s\n", $2);
        }
    }' /proc/mounts
done

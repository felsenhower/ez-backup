#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

[ "${SHELLCHECK:-0}" == "1" ] && shellcheck "$0"

function fail() {
    echo 'Error:' "$@" >&2
    exit 1
}

if [[ "$UID" != 0 ]] ; then
    fail 'Must run as root'
fi

dependencies=(
    jq
    rsync
    printf
)

for dependency in "${dependencies[@]}" ; do
  if ! type "$dependency" >/dev/null 2>&1 ; then
    fail "$(printf 'Dependency "%s" is missing!' "$dependency")"
  fi
done

config_file_name='config.json'

if ! [[ -f "$config_file_name" ]] ; then
    fail 'Config not found!'
fi

config="$(cat "$config_file_name")"

mount_dir="$(echo "$config" | jq -r '.mount_dir')"

if [[ "$mount_dir" == 'null' ]] ; then
    fail 'Config is missing mount directory'
fi

mkdir -p "$mount_dir"

function cleanup() {
    local max_retries=9
    for i in $(seq 1 "$max_retries") ; do
        readarray -t mounts < <(find "$mount_dir" -mindepth 1 -maxdepth 1 -type d)
        if (( "${#mounts[@]}" == 0 )) ; then
            break
        fi
        wait_duration="$(( 2**(i-1) ))"
        wait_duration_length="$(echo -n "$wait_duration" | wc -c)"
        for j in $(seq "$wait_duration" -1 1) ; do
            printf '\rUnmount attempt %s / %s. Wait for %s s... [%*s] ' "$i" "$max_retries" "$wait_duration" "$wait_duration_length" "$j"
            sleep 1
        done
        printf '\rUnmount attempt %s / %s. Wait for %s s... [%*s] \n' "$i" "$max_retries" "$wait_duration" "$wait_duration_length" 0
        sync
        for mountpoint in "${mounts[@]}" ; do
            printf 'Unmount %s...\n' "$mountpoint"
            umount "$mountpoint" || true
            if ! mountpoint -q "$mountpoint" ; then
                rmdir "$mountpoint"
            fi
        done
    done
    echo 'All mounts unmounted successfully.'
}

trap cleanup EXIT

readarray -t backup_keys_from_config < <(echo "$config" | jq -r '.backups | keys | .[]')

if (( "$#" == 0 )) ; then
    backup_keys=( "${backup_keys_from_config[@]}" )
else
    backup_keys_from_args=( "$@" )
    for key in "${backup_keys_from_args[@]}" ; do
        if [[ ! " ${backup_keys_from_config[*]} " =~ [[:space:]]${key}[[:space:]] ]]; then
            fail "$(printf 'Unknown backup name "%s"' "$key")"
        fi
    done
    backup_keys=( "${backup_keys_from_args[@]}" )
fi

for backup_key in "${backup_keys[@]}" ; do
    printf 'Backing up "%s":\n' "$backup_key"
    source_device="$(echo "$config" | jq -r "$(printf '.backups.%s.source_device' "$backup_key")")"
    target_device="$(echo "$config" | jq -r "$(printf '.backups.%s.target_device' "$backup_key")")"
    target_subdir="$(echo "$config" | jq -r "$(printf '.backups.%s.target_subdir' "$backup_key")")"
    source_block_device='/dev/disk/by-uuid/'"$source_device"
    target_block_device='/dev/disk/by-uuid/'"$target_device"
    source_mount_dir="$mount_dir"/"$source_device"
    target_mount_dir="$mount_dir"/"$target_device"
    printf '[%s] -> [%s]:%s\n' "$source_device" "$target_device" "$target_subdir"
    if ! [[ -L "$source_block_device" ]] ; then
        fail "$(printf 'Source device "%s" does not exist' "$source_device")"
    fi
    if ! [[ -L "$target_block_device" ]] ; then
        fail "$(printf 'Target device "%s" does not exist' "$target_device")"
    fi
    readarray -t mounts < <(cut -d' ' -f2 /proc/mounts)
    if [[ ! " ${mounts[*]} " =~ [[:space:]]${source_mount_dir}[[:space:]] ]]; then
        printf 'Mount device "%s"\n' "$source_device"
        mkdir -p "$source_mount_dir"
        mount "$source_block_device" "$source_mount_dir"
    else
        printf 'Device "%s" is already mounted.\n' "$source_device"
    fi    
    if [[ ! " ${mounts[*]} " =~ [[:space:]]${target_mount_dir}[[:space:]] ]]; then
        printf 'Mount device "%s"\n' "$target_device"
        mkdir -p "$target_mount_dir"
        mount "$target_block_device" "$target_mount_dir"
    else
        printf 'Device "%s" is already mounted.\n' "$target_device"
    fi    
    target_directory="$target_mount_dir"/"$target_subdir"
    mkdir -p "$target_directory"
    rsync -avu --delete --exclude "$mount_dir" "$source_mount_dir"/ "$target_directory"/
done

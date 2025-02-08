# ez-backup

This is a simple backup tool that I wrote.

I took some inspiration from timeshift, but this is a bit simpler.

You may lose your data! Use at your own risk!

## Dependencies

- `bash`
- `rsync`
- `jq`

## Usage

First, find the UUIDs of the device(s) you want to back up and of the device(s) that you want to write the backup to:

```bash
$ sudo lsblk --paths --output=NAME,FSTYPE,LABEL,UUID,MOUNTPOINTS --exclude=7
NAME                      FSTYPE       LABEL    UUID                                  MOUNTPOINTS
/dev/sda1
├─/dev/sda1               vfat                  90D5-9933                             /boot/efi
└─/dev/sda2               ext4         root     5b7e9c56-b11f-4403-bdf5-1053f42e6337  /
/dev/sdb
└─/dev/sdb1               crypto_LUKS  bob      6eb75e49-fa9e-4ef2-a75e-78dbe96ed9c4
  └─/dev/mapper/home-bob  ext4         bob      f99416c8-e250-43ad-aeab-3bc76eab5ec9  /home/bob
/dev/sdc
└─/dev/sdc1               ext4         Backups  66445309-f07d-4230-9674-2d6e78876f9f  /run/media/bob/Backups
```

```bash
$ git clone git@github.com:felsenhower/ez-backup.git
$ cd ez-backup
```

Create config like so:

```json
{
    "mount_dir": "/mnt/ez_backup",
    "backups": {
        "boot": {
            "source_device": "90D5-9933",
            "target_device": "66445309-f07d-4230-9674-2d6e78876f9f",
            "target_subdir": "backup_boot"
        },
        "root": {
            "source_device": "5b7e9c56-b11f-4403-bdf5-1053f42e6337",
            "target_device": "66445309-f07d-4230-9674-2d6e78876f9f",
            "target_subdir": "backup_root"
        },
        "home": {
            "source_device": "f99416c8-e250-43ad-aeab-3bc76eab5ec9",
            "target_device": "66445309-f07d-4230-9674-2d6e78876f9f",
            "target_subdir": "backup_home"
        }
    }
}
```

Note that for bob's encrypted home directory, the UUID of the ext4 device is used, not the LUKS device.

Now you can simply run `sudo ./ez_backup.sh`.

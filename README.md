# ez-backup

This is a simple backup tool that I wrote.

I took some inspiration from timeshift, but this is a bit simpler.

You may lose your data! Use at your own risk!

## Dependencies

- `bash`
- `rsync`
- `jq`

## Usage

```bash
$ git clone git@github.com:felsenhower/ez-backup.git
$ cd ez-backup
$ ./list_disks.sh
9353affd-1472-4cdd-9800-3ed7e1b0d80d -> /dev/sda1
 - /boot/efi
863c3d5b-3e22-4158-b147-2ae5c0ffdc60 -> /dev/sda2
 - /
eeb78f9e-d873-49b3-ac24-6bc03e0cc0a5 -> /dev/sdb1
 - /home
65cb6471-7dad-4bb3-9e4b-415a0615ac86 -> /dev/sdc1
 - /run/media/ruben/Backups
```

Create config like so:

```json
{
    "mount_dir": "/mnt/ez_backup",
    "backups": {
        "boot": {
            "source_device": "9353affd-1472-4cdd-9800-3ed7e1b0d80d",
            "target_device": "65cb6471-7dad-4bb3-9e4b-415a0615ac86",
            "target_subdir": "backup_boot"
        },
        "root": {
            "source_device": "863c3d5b-3e22-4158-b147-2ae5c0ffdc60",
            "target_device": "65cb6471-7dad-4bb3-9e4b-415a0615ac86",
            "target_subdir": "backup_root"
        },
        "home": {
            "source_device": "eeb78f9e-d873-49b3-ac24-6bc03e0cc0a5",
            "target_device": "65cb6471-7dad-4bb3-9e4b-415a0615ac86",
            "target_subdir": "backup_home"
        }
    }
}
```

Now you can simply run `sudo ./ez_backup.sh`.

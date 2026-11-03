# MEGA Writable Backup

Home Assistant add-on that copies local backups to a [Mega](https://mega.nz/) **writable folder**. Home Assistant logs in with a folder link and an auth key, not with your Mega email and password, so the box only has access to that folder.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fgreemo%2Fha-mega-writable-backup)

![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)
![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)

## Why this exists

Home Assistant can send backups to local disk, SMB/NFS, Home Assistant Cloud, Google Drive, OneDrive, and similar **backup locations**. Mega is not one of those.

A Mega **file request** (the upload-only page in the web UI) cannot be used either. File requests have no API, MEGAcmd cannot log into them for writes, and Home Assistant cannot restore or prune files there.

Mega **writable folder exports** are the supported way to give another machine write access to one folder without a full-account login. They are created in [MEGAcmd](https://mega.io/cmd), not in the Mega website.

This add-on is that missing piece for Home Assistant OS: after you create the export, it uploads new files from `/backup` and deletes old ones once a keep-count is exceeded.

## What it is not

| Project | Difference |
| --- | --- |
| [Home Assistant Community Apps](https://github.com/hassio-addons/repository) | Default community store. It does not include Mega, and it is not accepting third-party apps. |
| [heidrich76 MEGAcmd](https://github.com/heidrich76/ha-addons) | MEGAcmd shell/GUI. You log in with the full Mega account and sync folders yourself. |
| [rclone-backup](https://github.com/jcwillox/hassio-rclone-backup) | Can target Mega, but rclone's Mega backend needs email and password. |
| [MEGA S4 integration](https://github.com/luizof/mega_s4_ha_integration) | Native backup agent for paid MEGA S4 object storage, not a normal Mega folder. |

This add-on does **not** register as a Home Assistant backup location. Home Assistant still creates backups locally. The add-on copies those `.tar` files to Mega afterwards.

## Install

1. In Home Assistant go to **Settings → Add-ons → Add-on Store**.
2. Open the three-dot menu → **Repositories**.
3. Add:

   `https://github.com/greemo/ha-mega-writable-backup`

4. Find **MEGA Writable Backup**, install it, then open **Documentation** in the add-on for MEGAcmd setup.

The first install builds a container image on the Home Assistant machine (Debian + MEGAcmd). That can take a few minutes.

## Configure in short

On a computer logged into your Mega **account**, in MEGAcmd:

```text
mkdir /HA-Backups
export -a --writable /HA-Backups
```

That prints a folder URL and an `AuthToken`. Put them in the add-on options:

- **Mega folder URL** — `https://mega.nz/folder/HANDLE#KEY`
- **Auth key** — the part after the last colon on the `AuthToken` line, or the whole token

Start the add-on. It logs into that folder, uploads any `.tar` files from `/backup` that are not already on Mega, and then checks again every 30 minutes (configurable). By default it keeps the newest 14 remote files.

Treat both the folder URL and the auth key as secrets. The URL includes the folder decryption key; anyone who has it can read the files. If Home Assistant backups are password-protected, that password still protects the tar contents.

Full MEGAcmd steps for Linux, macOS, and Windows are in [`mega_writable_backup/DOCS.md`](mega_writable_backup/DOCS.md).

## Restore

1. Download the `.tar` from Mega (web site or MEGAcmd `get`).
2. In Home Assistant: **Settings → System → Backups → Upload backup**, or copy the file into `/backup` (Samba / SSH) and refresh.

## Privileges

MEGAcmd needs `/dev/fuse` and `SYS_ADMIN` inside its container. AppArmor is disabled for this add-on. The Mega session is limited to the exported folder, and `/backup` is mounted read-only.

## License

[MIT](LICENSE)

# MEGA Writable Backup

Copies Home Assistant backup archives from `/backup` to a Mega writable folder using official [MEGAcmd](https://mega.io/cmd).

Home Assistant is given a **folder link plus auth key**, not your Mega account password. The session can only see that folder.

## Requirements

- Home Assistant OS or Supervised (this is an add-on, not a HACS integration)
- A Mega account
- MEGAcmd on a computer where you can log into that account, to create the writable export
- Existing local backups (automatic or manual). This add-on uploads files that Home Assistant has already created.

## Create the writable folder

Do this in **MEGAcmd** from a dev machine (likely not the HA machine), not in the Mega website. A web **file request** uses a different encryption scheme. MEGAcmd cannot log into a file request for writes, and this add-on cannot use one.

### 1. Install MEGAcmd

Pick the package for the machine that will create the export: [MEGA CMD downloads](https://mega.io/cmd).

**Linux (Debian / Ubuntu / Mint)** — use the repo that matches your release. Linux Mint 22 is Ubuntu 24.04:

```bash
curl -fsSL https://mega.nz/linux/repo/xUbuntu_24.04/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/meganz-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/meganz-archive-keyring.gpg] https://mega.nz/linux/repo/xUbuntu_24.04/ ./" | sudo tee /etc/apt/sources.list.d/mega.list
sudo apt update
sudo apt install megacmd
```

Debian 12:

```bash
curl -fsSL https://mega.nz/linux/repo/Debian_12/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/meganz-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/meganz-archive-keyring.gpg] https://mega.nz/linux/repo/Debian_12/ ./" | sudo tee /etc/apt/sources.list.d/mega.list
sudo apt update
sudo apt install megacmd
```

**Windows / macOS:** install the MEGA CMD package from the same downloads page.

### 2. Export a writable folder

```text
mega-cmd
login you@your-mega-email
mkdir /HA-Backups
export -a --writable /HA-Backups
```

You should see two lines:

```text
Exported /HA-Backups: https://mega.nz/folder/HANDLE#KEY
AuthToken = HANDLE#KEY:AUTHKEY
```

Copy both. To print them again later, while still logged into the account:

```text
export /HA-Backups
```

The folder name can be anything. `/HA-Backups` is only a convention.

### 3. Fill the add-on options

| Option | What to paste |
| --- | --- |
| **Mega folder URL** | `https://mega.nz/folder/HANDLE#KEY` |
| **Auth key** | `AUTHKEY` (the part after the last colon). Pasting the whole `AuthToken` also works. |
| **Backups to keep** | Newest remote files to keep. Default `14`. Older uploads are deleted from the Mega folder only. |
| **Sync interval (minutes)** | How often to look for new local backups. Default `30`. |

Then **Start** the add-on (or restart it if it was already running).

Do not paste the auth key into a public issue, forum post, or chat. The folder URL also contains the decryption key; treat it as a secret too.

## How it behaves

1. Starts `mega-cmd-server` and logs in with the folder URL and `--auth-key`.
2. Uploads each `/backup/*.tar` (and `*.tar.enc` if present) that is not already in the folder.
3. Deletes the oldest remote files until at most **Backups to keep** remain.
4. Sleeps for **Sync interval**, then repeats.

The first pass runs as soon as login succeeds. Home Assistant still stores backups locally; this add-on only copies them.

It is **not** a backup location in **Settings → System → Backups**. Automatic backup still writes to local storage (and any other locations you configured). Leave local backups enabled.

## Restore a backup

1. Download the `.tar` from Mega (website, Mega desktop, or `mega-get` after logging into the folder).
2. In Home Assistant open **Settings → System → Backups** and use **Upload backup**, **or** copy the file into `/backup` with Samba / SSH and refresh the backup list.
3. Restore as usual. If the archive was created with a backup password, Home Assistant will ask for it.

## Logs

**Settings → Add-ons → MEGA Writable Backup → Log.**

Useful lines:

- `Mega login ok` — folder session is up
- `Uploading <filename>` then `Upload finished:` — that file is on Mega
- `Not logged into Mega` / `Mega login command failed` — URL or auth key is wrong, or MEGAcmd could not reach Mega
- `Set the Mega folder URL and auth key` — options are still empty

## Troubleshooting

**Login fails immediately**

- Create the export with `export -a --writable`. A normal (read-only) folder link has no auth key.
- Do not use a file-request URL from the Mega website.
- The folder URL must include `#` and the key. If you paste it into YAML by hand, quote the value so `#` is not treated as a comment. The add-on UI stores JSON, so this does not apply there.

**Files never appear on Mega**

- Confirm Home Assistant has local backups under **Settings → System → Backups**.
- Wait for the current upload; large archives can take several minutes.
- Check the add-on log for `Not logged in` or `Upload finished`.

**First install is slow**

Supervisor builds the image on the machine (Debian Bookworm + the official `megacmd` package). Later starts reuse that image.

**I rotated the folder export**

Disable the old export in MEGAcmd (`export -d /HA-Backups`), create a new writable export, paste the new URL and auth key, restart the add-on. Files already uploaded under the old link stay in Mega unless you delete them yourself.

## Security notes

- The Mega session cannot see the rest of your account.
- `/backup` is mounted read-only. The add-on cannot delete local Home Assistant backups.
- MEGAcmd in this container runs with `SYS_ADMIN` and `/dev/fuse`, and AppArmor is off, because that is what the Mega client needs. Do not put an untrusted folder URL here.
- Anyone with the folder URL can **read** the remote files. Anyone with the auth key can **write**. Password-protect Home Assistant backups if the tar contents are sensitive.

## Related Mega docs

- [MEGAcmd login](https://github.com/meganz/MEGAcmd/blob/master/contrib/docs/commands/login.md) (`--auth-key`)
- [MEGAcmd export](https://github.com/meganz/MEGAcmd/blob/master/contrib/docs/commands/export.md) (`--writable`)
- Writable folder login without a full account: [MEGAcmd issue 624](https://github.com/meganz/MEGAcmd/issues/624)

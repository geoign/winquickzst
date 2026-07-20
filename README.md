# WinQuickArchiver

*Languages: **English** | [日本語](README.ja.md)*

A tiny Windows right-click tool that compresses a folder **straight into a
destination you choose** — as `tar.zst` (default), `tar.gz`, `tar.bz2`, or `zip`.
The default `tar.zst` / Light mode uses the bundled fast Rust engine; other
formats use Windows' built-in `tar`. No admin rights or network access is needed.

## What it does

- Right-click a folder → **"Compress with WinQuickArchiver…"** → pick a format and level → pick a destination. Done: `folder_YYYYMMDD-HHMMSS.tar.zst` (default mode) is written **directly** where you chose.
- No temp file and no move afterwards, so it stays **fast even for large folders**.
- The default `tar.zst` / Light mode is fixed at level 2 and uses every available logical CPU.
- The `tar` family stores file names as **UTF-8**, so they are not garbled when extracted on Linux.
- The UI language is chosen automatically — Japanese if your Windows display language **or** region is Japanese, otherwise English. You can force it with the environment variable `WQA_LANG=ja` or `WQA_LANG=en`.

## Requirements

- **64-bit Windows 10 or 11**. The default fast `tar.zst` mode runs entirely from the bundled executable.
- `tar.gz`, `tar.bz2`, `zip`, and Normal/Maximum compression use Windows' built-in `tar.exe`.

## Install (3 easy steps)

1. Click **Code → Download ZIP** and **extract** it (or place the folder anywhere, e.g. `Documents\winquickarchiver`).
2. Double-click **`Install.cmd`** inside the folder.
3. When you see "Done", it worked. You can close the window.

> Because the files come from the internet, Windows may show a SmartScreen or security warning the first time. Review it, then choose **More info → Run** (or **Open**) to proceed. The tool uses no admin rights and makes only the minimal changes listed below.

## Usage

- **One folder:** right-click → **"Compress with WinQuickArchiver…"**
  - If you don't see it on Windows 11, it is under **"Show more options"** (`Shift + F10`).
- **Several at once:** select multiple folders/files → right-click → **Send to** → **WinQuickArchiver**
- Pick a **format** and **level** in the dialog, then choose the **destination** (the picker opens at your Desktop).

### Formats and levels

| Format | Good for |
|---|---|
| `tar.zst` (default) | Fast and small. Recommended for exchanging files with Linux |
| `tar.gz` | The most widely compatible classic |
| `tar.bz2` | A bit smaller than gz |
| `zip` | Easy to open on Windows / Mac |

Level: **Light (fast, level 2, all CPUs) / Normal / Maximum**. The fast Rust engine is used for folders in `tar.zst` / Light mode.

## What it changes on your PC (safety)

For transparency — **no admin rights are used**:

- It adds, **for the current user only (HKCU)**:
  - one registry entry for the right-click menu
  - one "Send to" shortcut
- Compression calls the bundled `bin\fast-tarzst.exe` or Windows' built-in `tar.exe`. **No network, no background service, no data collection.**
- Everything is reversible with **`Uninstall.cmd`**.

## Uninstall

1. Double-click **`Uninstall.cmd`** (removes the right-click entry and the "Send to" shortcut).
2. Delete this folder to remove the app itself.

## Troubleshooting

- **Menu doesn't appear:** `Install.cmd` restarts Explorer automatically; if it still doesn't show, sign out and back in, or restart the PC. On Windows 11 also check under "Show more options".
- **Cloud-synced folders (OneDrive / Dropbox, etc.):** if the files become "online-only", the right-click may fail. Set the folder to **"Always keep on this device"**, or put it outside the synced area.
- **Can't create fast `tar.zst`:** check that `bin\fast-tarzst.exe` exists, extract the ZIP again, and rerun `Install.cmd`.
- **Other formats fail:** run `tar --version` in PowerShell and confirm that Windows' built-in tar is available.

## Extracting on Linux

```bash
tar --zstd -xf name.tar.zst     # tar.zst
tar -xzf   name.tar.gz          # tar.gz
tar -xjf   name.tar.bz2         # tar.bz2
unzip      name.zip             # zip
```

## Note

This tool does not fully preserve Unix permissions / ownership / symlinks.
If you need exact reproduction of executable bits or symlinks, create the tar on
Linux (or WSL). For plain data files it is fine.

## License

The PowerShell wrapper is released under [The Unlicense](LICENSE) (public domain). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the bundled engine and dependencies. No warranty.

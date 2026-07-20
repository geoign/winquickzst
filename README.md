# WinQuickZst

*Languages: **English** | [日本語](README.ja.md)*

A Windows right-click tool that creates a fast `tar.zst` archive directly in a destination you choose. Its bundled Rust engine generates tar and compresses with Zstandard on the fly, with no intermediate tar file and no move afterwards.

## Features

- Right-click a folder → **Compress to tar.zst with WinQuickZst…** → choose a compression level → choose a destination.
- Every level makes the available logical CPUs available to Zstandard workers.
- Files of 1 MiB or larger use a reusable 8 MiB input buffer to keep the
  Zstandard workers fed efficiently; smaller files retain a lightweight path.
- Output names use `folder_YYYYMMDD-HHMMSS.tar.zst`.
- The selected folder itself is stored at the archive root.
- A Zstandard frame checksum is generated on the fly.
- The UI follows the Windows display language and region. Override it with `WQZ_LANG=ja` or `WQZ_LANG=en`.

## Compression levels

| UI choice | Zstandard level | Intended use |
|---|---:|---|
| Fast (default) | 2 | Minimize transfer preparation time |
| Normal | 10 | Balance size and time |
| High | 19 | Prefer size over processing time |

## Requirements

- 64-bit Windows 10 or 11
- Folder input only
- No administrator rights, additional runtime, or network access required

## Install

1. Put this folder anywhere. If it is in a cloud-synced folder, mark it as always available on this device.
2. Double-click **`Install.cmd`**.
3. After Explorer restarts, the folder context menu contains **Compress to tar.zst with WinQuickZst…**.

## Usage

- **One folder:** right-click it → **Compress to tar.zst with WinQuickZst…**
  - On Windows 11, check **Show more options** (`Shift + F10`) if necessary.
- **Multiple folders:** select them → right-click → **Send to** → **WinQuickZst**
- Choose a compression level, then choose the destination folder.

Automation is also supported:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\WinQuickZst.ps1 -Level std -Dest "D:\out" "C:\data"
```

`-Level` accepts `light` (Lv.2), `std` (Lv.10), or `max` (Lv.19).

## Changes made to your PC

Only the following current-user (HKCU) entries are added; no administrator rights are used:

- One folder context-menu entry
- One Send-to shortcut

Compression uses only the bundled `bin\fast-tarzst.exe`. There is no background service, data collection, or network access.

## Extracting on Linux

The Linux side needs the `zstd` command:

```bash
sudo apt-get install zstd
tar --zstd -xf folder_YYYYMMDD-HHMMSS.tar.zst
```

## Uninstall

1. Double-click **`Uninstall.cmd`**.
2. Delete this folder manually.

## Notes

- If the source changes during compression, archive-wide consistency is not guaranteed.
- A power loss or forced termination can leave a partial `.tar.zst` file.
- NTFS ACLs, alternate data streams, Unix ownership, and executable bits are not preserved completely.
- High compression Lv.19 can use substantial CPU, memory, and time.

## License

The PowerShell wrapper is released under [The Unlicense](LICENSE) (public domain). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the bundled engine and dependencies. No warranty.

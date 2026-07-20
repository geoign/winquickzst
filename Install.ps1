<#
  Install.ps1 — Register WinQuickArchiver into the right-click / Send-to menus.
  HKCU only, no admin required, fully removable with Uninstall.ps1.
  Registration is based on this script's own folder, so moving the folder and
  re-running this script keeps everything pointing at the right place.
  UI language follows the Windows display language.
#>
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
function Get-IsJa {
  if ($env:WQA_LANG) { return ($env:WQA_LANG.Trim().ToLower().StartsWith('ja')) }
  $ui = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
  $cu = [System.Globalization.CultureInfo]::CurrentCulture.TwoLetterISOLanguageName
  return ($ui -eq 'ja' -or $cu -eq 'ja')
}
$isJa = Get-IsJa
function T([string]$ja, [string]$en){ if ($isJa) { $ja } else { $en } }

$script = Join-Path $PSScriptRoot 'WinQuickArchiver.ps1'
if (-not (Test-Path -LiteralPath $script)) { throw (T "本体が見つかりません: $script" "Main script not found: $script") }
$fastTarZst = Join-Path $PSScriptRoot 'bin\fast-tarzst.exe'
if (-not (Test-Path -LiteralPath $fastTarZst -PathType Leaf)) { throw (T "高速圧縮エンジンが見つかりません: $fastTarZst" "Fast compression engine not found: $fastTarZst") }

$iconPath = Join-Path $env:SystemRoot 'System32\imageres.dll'   # Windows built-in icon (no external dependency)
$icon  = '"' + $iconPath + '",-174'
$cmd   = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "' + $script + '" "%1"'
$label = T 'WinQuickArchiver で圧縮…' 'Compress with WinQuickArchiver…'

# 1) Folder right-click (aims at the Win11 top-level menu via a whitelisted verb id)
$key = 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper'
New-Item -Path "$key\command" -Force | Out-Null
Set-ItemProperty -Path $key -Name 'MUIVerb' -Value $label
Set-ItemProperty -Path $key -Name 'Icon'    -Value $icon
Set-ItemProperty -Path "$key\command" -Name '(default)' -Value $cmd

# 2) Send-to shortcut (handles multi-selection in one go)
$sendto = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
$lnk = Join-Path $sendto 'WinQuickArchiver.lnk'
$ws  = New-Object -ComObject WScript.Shell
$sc  = $ws.CreateShortcut($lnk)
$sc.TargetPath   = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$sc.Arguments    = '-NoProfile -ExecutionPolicy Bypass -File "' + $script + '"'
$sc.IconLocation = $iconPath + ',-174'
$sc.Save()

# 3) Clean up the legacy (tar-zst era) Send-to shortcut if present
$legacy = Join-Path $sendto 'tar.zst で圧縮.lnk'
if (Test-Path -LiteralPath $legacy) { Remove-Item -LiteralPath $legacy -Force }

Write-Host (T 'WinQuickArchiver を登録しました。' 'WinQuickArchiver has been installed.') -ForegroundColor Green
Write-Host (T '  フォルダ右クリック → 「WinQuickArchiver で圧縮…」' '  Right-click a folder -> "Compress with WinQuickArchiver..."')
Write-Host (T '  複数選択 → 右クリック → 送る → WinQuickArchiver' '  Multi-select -> right-click -> Send to -> WinQuickArchiver')
Write-Host ''
Write-Host (T 'メニューを反映するためエクスプローラーを再起動します...' 'Restarting Explorer to apply the menu...') -ForegroundColor DarkGray
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Write-Host (T '完了しました。' 'Done.') -ForegroundColor Green

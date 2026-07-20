<#
  Install.ps1 — Register WinQuickZst into the right-click / Send-to menus.
  HKCU only, no admin required, fully removable with Uninstall.ps1.
#>
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
function Get-IsJa {
  if ($env:WQZ_LANG) { return ($env:WQZ_LANG.Trim().ToLower().StartsWith('ja')) }
  $ui = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
  $cu = [System.Globalization.CultureInfo]::CurrentCulture.TwoLetterISOLanguageName
  return ($ui -eq 'ja' -or $cu -eq 'ja')
}
$isJa = Get-IsJa
function T([string]$ja, [string]$en){ if ($isJa) { $ja } else { $en } }

$script = Join-Path $PSScriptRoot 'WinQuickZst.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { throw (T "本体が見つかりません: $script" "Main script not found: $script") }
$fastTarZst = Join-Path $PSScriptRoot 'bin\fast-tarzst.exe'
if (-not (Test-Path -LiteralPath $fastTarZst -PathType Leaf)) { throw (T "圧縮エンジンが見つかりません: $fastTarZst" "Compression engine not found: $fastTarZst") }

$iconPath = Join-Path $env:SystemRoot 'System32\imageres.dll'
$icon = '"' + $iconPath + '",-174'
$cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "' + $script + '" "%1"'
$label = T 'WinQuickZst で tar.zst に圧縮…' 'Compress to tar.zst with WinQuickZst…'

# Folder right-click menu
$key = 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper'
New-Item -Path "$key\command" -Force | Out-Null
Set-ItemProperty -Path $key -Name 'MUIVerb' -Value $label
Set-ItemProperty -Path $key -Name 'Icon' -Value $icon
Set-ItemProperty -Path "$key\command" -Name '(default)' -Value $cmd

# Send-to shortcut for multiple folders
$sendto = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
$lnk = Join-Path $sendto 'WinQuickZst.lnk'
$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut($lnk)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $script + '"'
$shortcut.IconLocation = $iconPath + ',-174'
$shortcut.Save()

# Remove shortcuts from previous product names.
foreach ($legacyName in @('WinQuickArchiver.lnk', 'tar.zst で圧縮.lnk')) {
  $legacy = Join-Path $sendto $legacyName
  if (Test-Path -LiteralPath $legacy) { Remove-Item -LiteralPath $legacy -Force }
}

Write-Host (T 'WinQuickZst を登録しました。' 'WinQuickZst has been installed.') -ForegroundColor Green
Write-Host (T '  フォルダ右クリック → 「WinQuickZst で tar.zst に圧縮…」' '  Right-click a folder -> "Compress to tar.zst with WinQuickZst..."')
Write-Host (T '  複数フォルダ → 右クリック → 送る → WinQuickZst' '  Multiple folders -> right-click -> Send to -> WinQuickZst')
Write-Host ''
Write-Host (T 'メニューを反映するためエクスプローラーを再起動します...' 'Restarting Explorer to apply the menu...') -ForegroundColor DarkGray
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Write-Host (T '完了しました。' 'Done.') -ForegroundColor Green
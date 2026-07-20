<#
  Uninstall.ps1 — Remove WinQuickZst right-click / Send-to entries.
#>
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
function Get-IsJa {
  if ($env:WQZ_LANG) { return ($env:WQZ_LANG.Trim().ToLower().StartsWith('ja')) }
  $ui = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
  $cu = [System.Globalization.CultureInfo]::CurrentCulture.TwoLetterISOLanguageName
  return ($ui -eq 'ja' -or $cu -eq 'ja')
}
$isJa = Get-IsJa
function T([string]$ja, [string]$en){ if ($isJa) { $ja } else { $en } }

Remove-Item -Path 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper' -Recurse -Force
Remove-Item -Path 'HKCU:\Software\Classes\*\shell\SetDesktopWallpaper' -Recurse -Force

$sendto = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
foreach ($name in @('WinQuickZst.lnk', 'WinQuickArchiver.lnk')) {
  $lnk = Join-Path $sendto $name
  if (Test-Path -LiteralPath $lnk) { Remove-Item -LiteralPath $lnk -Force }
}

Write-Host (T 'メニューを反映するためエクスプローラーを再起動します...' 'Restarting Explorer to apply changes...') -ForegroundColor DarkGray
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Write-Host (T 'WinQuickZst を削除しました。' 'WinQuickZst has been uninstalled.') -ForegroundColor Green
Write-Host (T "本体フォルダを消すには手動で削除してください: $PSScriptRoot" "To remove the app itself, delete this folder: $PSScriptRoot")
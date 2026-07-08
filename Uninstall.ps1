<#
  Uninstall.ps1 — WinQuickArchiver の右クリック/送る を削除します。
  本体フォルダは最後に手動で削除してください。
#>
$ErrorActionPreference = 'SilentlyContinue'

Remove-Item -Path 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper' -Recurse -Force
Remove-Item -Path 'HKCU:\Software\Classes\*\shell\SetDesktopWallpaper'         -Recurse -Force

$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo\WinQuickArchiver.lnk'
if (Test-Path -LiteralPath $lnk) { Remove-Item -LiteralPath $lnk -Force }

Write-Host '削除しました。エクスプローラーを再起動すると反映されます。' -ForegroundColor Green
Write-Host "本体フォルダを消すには:  $PSScriptRoot  を手動で削除してください。"

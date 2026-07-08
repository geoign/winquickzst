<#
  Uninstall.ps1 — WinQuickArchiver の右クリック/送る を削除します。
  本体フォルダは最後に手動で削除してください。
#>
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Remove-Item -Path 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper' -Recurse -Force
Remove-Item -Path 'HKCU:\Software\Classes\*\shell\SetDesktopWallpaper'         -Recurse -Force

$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo\WinQuickArchiver.lnk'
if (Test-Path -LiteralPath $lnk) { Remove-Item -LiteralPath $lnk -Force }

Write-Host 'メニューを反映するためエクスプローラーを再起動します...' -ForegroundColor DarkGray
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Write-Host '削除しました。' -ForegroundColor Green
Write-Host "本体フォルダを消すには:  $PSScriptRoot  を手動で削除してください。"

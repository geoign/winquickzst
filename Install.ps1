<#
  Install.ps1 — WinQuickArchiver を右クリック/送る に登録します。
  HKCU のみ・管理者不要・いつでも Uninstall.ps1 で撤去可能。
  このスクリプト自身の場所を基準に登録するので、フォルダごと移動しても
  再実行すれば追従します。
#>
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'WinQuickArchiver.ps1'
if (-not (Test-Path -LiteralPath $script)) { throw "本体が見つかりません: $script" }

$icon = '"C:\Program Files\7-Zip-Zstandard\7z.exe",0'
$cmd  = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "' + $script + '" "%1"'

# 1) フォルダ右クリック (Win11 新メニュー最上段狙い = whitelisted ID)
$key = 'HKCU:\Software\Classes\Directory\shell\SetDesktopWallpaper'
New-Item -Path "$key\command" -Force | Out-Null
Set-ItemProperty -Path $key -Name 'MUIVerb' -Value 'WinQuickArchiver で圧縮…'
Set-ItemProperty -Path $key -Name 'Icon'    -Value $icon
Set-ItemProperty -Path "$key\command" -Name '(default)' -Value $cmd

# 2) 送る(Send to) ショートカット(複数選択を一度に処理)
$sendto = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
$lnk = Join-Path $sendto 'WinQuickArchiver.lnk'
$ws  = New-Object -ComObject WScript.Shell
$sc  = $ws.CreateShortcut($lnk)
$sc.TargetPath   = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$sc.Arguments    = '-NoProfile -ExecutionPolicy Bypass -File "' + $script + '"'
$sc.IconLocation = 'C:\Program Files\7-Zip-Zstandard\7z.exe,0'
$sc.Save()

# 3) 旧バージョン(tar-zst 時代)の送るショートカットを掃除
$legacy = Join-Path $sendto 'tar.zst で圧縮.lnk'
if (Test-Path -LiteralPath $legacy) { Remove-Item -LiteralPath $legacy -Force }

Write-Host 'WinQuickArchiver を登録しました。' -ForegroundColor Green
Write-Host '  フォルダ右クリック → 「WinQuickArchiver で圧縮…」'
Write-Host '  複数選択 → 右クリック → 送る → WinQuickArchiver'
Write-Host 'エクスプローラーを再起動すると確実に反映されます。'

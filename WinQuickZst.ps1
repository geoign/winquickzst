<#
  WinQuickZst.ps1
  ------------------------------------------------------------------
  Right-click one or more folders and write tar.zst archives directly
  into a destination you choose (no temp tar, no move afterwards).
  UI language follows the Windows display language (Japanese or English).

    Format : tar.zst only
    Levels : fast (Lv.2, default) / normal (Lv.10) / high (Lv.19)
    Engine : bundled fast-tarzst, using every available logical CPU
  ------------------------------------------------------------------
  Automation / test (skips the dialog):
    WinQuickZst.ps1 -Level light -Dest "D:\out" "C:\path\folder"
#>
param(
  [string]$Dest  = '',    # empty -> folder picker (defaults to Desktop)
  [string]$Level = '',    # light | std | max  (empty -> dialog)
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { & chcp 65001 > $null } catch {}
$fastTarZst = Join-Path $PSScriptRoot 'bin\fast-tarzst.exe'

# ---- 言語自動判定 / auto language. Force with WQZ_LANG=ja|en.
function Get-IsJa {
  if ($env:WQZ_LANG) { return ($env:WQZ_LANG.Trim().ToLower().StartsWith('ja')) }
  $ui = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
  $cu = [System.Globalization.CultureInfo]::CurrentCulture.TwoLetterISOLanguageName
  return ($ui -eq 'ja' -or $cu -eq 'ja')
}
$script:isJa = Get-IsJa
function T([string]$ja, [string]$en){ if ($script:isJa) { $ja } else { $en } }

$LEVELS = [ordered]@{
  light = @{ value = 2;  display = (T '高速 (Lv.2)'     'Fast (Lv.2)') }
  std   = @{ value = 10; display = (T '標準 (Lv.10)'    'Normal (Lv.10)') }
  max   = @{ value = 19; display = (T '高圧縮 (Lv.19)'  'High (Lv.19)') }
}
$LEVELKEYS = @($LEVELS.Keys)

function Fail([string]$msg){ Write-Host $msg -ForegroundColor Red; Read-Host (T 'Enter を押すと閉じます' 'Press Enter to close'); exit 1 }

function Format-ByteSize([double]$bytes) {
  $units = @('B', 'KiB', 'MiB', 'GiB', 'TiB')
  $value = [double]$bytes
  if ($value -lt 0) { $value = 0 }
  $unit = 0
  while ($value -ge 1024 -and $unit -lt ($units.Count - 1)) {
    $value /= 1024
    $unit++
  }
  if ($unit -eq 0) { return ('{0:N0} {1}' -f $value, $units[$unit]) }
  return ('{0:N1} {1}' -f $value, $units[$unit])
}

function Format-Elapsed([long]$milliseconds) {
  if ($milliseconds -lt 0) { $milliseconds = 0 }
  $elapsed = [TimeSpan]::FromMilliseconds($milliseconds)
  if ($elapsed.TotalHours -ge 1) { return $elapsed.ToString('hh\:mm\:ss') }
  return $elapsed.ToString('mm\:ss')
}

if (-not $Paths -or $Paths.Count -eq 0) { Fail (T '入力がありません。' 'No input.') }
if (-not (Test-Path -LiteralPath $fastTarZst -PathType Leaf)) {
  Fail (T "圧縮エンジンが見つかりません: $fastTarZst" "Compression engine not found: $fastTarZst")
}

$items = @()
foreach($p in $Paths){
  if (-not (Test-Path -LiteralPath $p)) { Fail (T "入力が見つかりません: $p" "Input not found: $p") }
  if (-not (Test-Path -LiteralPath $p -PathType Container)) {
    Fail (T "フォルダだけを指定できます: $p" "Only folders can be archived: $p")
  }
  $items += (Resolve-Path -LiteralPath $p).Path
}

Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

# ---- 圧縮レベル選択 / compression level dialog ----
if (-not $Level) {
  $frm = New-Object System.Windows.Forms.Form
  $frm.Text = 'WinQuickZst'
  $frm.ClientSize = New-Object System.Drawing.Size(330, 140)
  $frm.FormBorderStyle = 'FixedDialog'
  $frm.StartPosition = 'CenterScreen'
  $frm.MaximizeBox = $false; $frm.MinimizeBox = $false; $frm.TopMost = $true

  $lblInfo = New-Object System.Windows.Forms.Label
  $lblInfo.Text = (T ("対象: {0} フォルダ" -f $items.Count) ("Folders: {0}" -f $items.Count))
  $lblInfo.Location = New-Object System.Drawing.Point(16, 14); $lblInfo.AutoSize = $true
  $frm.Controls.Add($lblInfo)

  $lblLevel = New-Object System.Windows.Forms.Label
  $lblLevel.Text = (T '圧縮率:' 'Level:'); $lblLevel.Location = New-Object System.Drawing.Point(16, 52); $lblLevel.AutoSize = $true
  $frm.Controls.Add($lblLevel)
  $cbLevel = New-Object System.Windows.Forms.ComboBox
  $cbLevel.DropDownStyle = 'DropDownList'
  $cbLevel.Location = New-Object System.Drawing.Point(95, 49); $cbLevel.Width = 210
  foreach($key in $LEVELKEYS){ [void]$cbLevel.Items.Add($LEVELS[$key].display) }
  $cbLevel.SelectedIndex = 0
  $frm.Controls.Add($cbLevel)

  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = 'OK'; $btnOk.Location = New-Object System.Drawing.Point(135, 97)
  $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $frm.Controls.Add($btnOk); $frm.AcceptButton = $btnOk
  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = (T 'キャンセル' 'Cancel'); $btnCancel.Location = New-Object System.Drawing.Point(220, 97)
  $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $frm.Controls.Add($btnCancel); $frm.CancelButton = $btnCancel

  if ($frm.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Level = $LEVELKEYS[$cbLevel.SelectedIndex]
  $frm.Dispose()
}
if (-not $LEVELS.Contains($Level)) { Fail (T "不明な圧縮率: $Level" "Unknown compression level: $Level") }

# ---- 保存先(既定=デスクトップ) / destination (defaults to Desktop) ----
if (-not $Dest) {
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = (T 'tar.zst の保存先フォルダを選択' 'Choose the destination folder for tar.zst archives')
  $dlg.ShowNewFolderButton = $true
  $dlg.RootFolder = [System.Environment+SpecialFolder]::Desktop
  $dlg.SelectedPath = [Environment]::GetFolderPath('Desktop')
  if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Dest = $dlg.SelectedPath
}
if (-not (Test-Path -LiteralPath $Dest -PathType Container)) { Fail (T "保存先がありません: $Dest" "Destination not found: $Dest") }

# ---- 保存先へ直接圧縮 / compress straight into destination ----
$zstdLevel = [int]$LEVELS[$Level].value
Write-Host (T ("形式: tar.zst   圧縮率: {0} (Lv.{1})   保存先: {2}" -f $Level, $zstdLevel, $Dest) `
              ("Format: tar.zst   Level: {0} (Lv.{1})   Dest: {2}" -f $Level, $zstdLevel, $Dest)) -ForegroundColor DarkGray

$okCount = 0; $failCount = 0
foreach($item in $items){
  $leaf = [System.IO.Path]::GetFileName($item)
  $targetDisplay = Join-Path $Dest ($leaf + '_YYYYMMDD-HHMMSS.tar.zst')
  Write-Host ''
  Write-Host "▶ $leaf  →  $targetDisplay" -ForegroundColor Cyan
  Write-Host ("  " + (T '圧縮中... (完了までウィンドウは開いたままになります)' 'Compressing... (this window stays open until done)')) -ForegroundColor DarkGray

  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $engineOutput = New-Object 'System.Collections.Generic.List[string]'
  $progressWidth = 0
  try {
    & $fastTarZst --progress --level $zstdLevel $item $Dest 2>&1 | ForEach-Object {
      $line = [string]$_
      if ($line -match '^FAST_TARZST_PROGRESS ([0-9]+) ([0-9]+) ([0-9]+)$') {
        $processedBytes = [double]$Matches[1]
        $outputBytes = [double]$Matches[2]
        $elapsedMs = [long]$Matches[3]
        $bytesPerSecond = if ($elapsedMs -gt 0) { $processedBytes * 1000 / $elapsedMs } else { 0 }
        $progressText = T `
          ('  処理済み {0}  出力 {1}  速度 {2}/s  経過 {3}' -f `
            (Format-ByteSize $processedBytes), (Format-ByteSize $outputBytes),
            (Format-ByteSize $bytesPerSecond), (Format-Elapsed $elapsedMs)) `
          ('  Processed {0}  Output {1}  Speed {2}/s  Elapsed {3}' -f `
            (Format-ByteSize $processedBytes), (Format-ByteSize $outputBytes),
            (Format-ByteSize $bytesPerSecond), (Format-Elapsed $elapsedMs))
        $displayWidth = [math]::Max($progressWidth, $progressText.Length)
        Write-Host ("`r" + $progressText.PadRight($displayWidth)) -NoNewline -ForegroundColor DarkGray
        $progressWidth = $progressText.Length
      } else {
        [void]$engineOutput.Add($line)
      }
    }
    $rc = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorAction
  }
  if ($progressWidth -gt 0) { Write-Host '' }

  $out = $null
  if ($rc -eq 0) {
    foreach ($line in $engineOutput) {
      $candidate = [string]$line
      if (Test-Path -LiteralPath $candidate -PathType Leaf) { $out = $candidate }
    }
    if (-not $out) { $rc = 1 }
  }

  if ($rc -eq 0 -and $out) {
    $size = (Get-Item -LiteralPath $out).Length
    Write-Host ("  " + (T '✓ 完了' '✓ Done') + ("  {0:N1} MB  →  {1}" -f ($size/1MB), $out)) -ForegroundColor Green
    $okCount++
  } else {
    foreach ($line in $engineOutput) { Write-Host ("  " + [string]$line) -ForegroundColor DarkRed }
    Write-Host ("  " + (T "✗ 失敗 (code $rc)" "✗ Failed (code $rc)")) -ForegroundColor Red
    $failCount++
  }
}

Write-Host ''
Write-Host (T ("=== 完了: 成功 $okCount / 失敗 $failCount  (保存先: $Dest) ===") `
              ("=== Finished: OK $okCount / Failed $failCount  (dest: $Dest) ===")) -ForegroundColor Yellow
if ($failCount -gt 0) { Read-Host (T 'Enter を押すと閉じます' 'Press Enter to close'); exit 1 }
Start-Sleep -Seconds 2

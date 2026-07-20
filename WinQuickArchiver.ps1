<#
  WinQuickArchiver.ps1
  ------------------------------------------------------------------
  Right-click a folder (or select files) and write an archive directly
  into a destination you choose (no temp file, no move afterwards).
  UI language follows the Windows display language (Japanese or English).

    Formats : tar.zst (default) / tar.gz / tar.bz2 / zip     (chosen in a dialog)
    Levels  : light (default) / normal / max                 (chosen in a dialog)
    Engine  : bundled fast-tarzst for tar.zst/light folders; Windows bsdtar otherwise
    tar-family stores names as UTF-8 (pax) - no mojibake when extracted on Linux
  ------------------------------------------------------------------
  Automation / test (skips the dialog):
    WinQuickArchiver.ps1 -Format tar.zst -Level light -Dest "D:\out" "C:\path\folder"
#>
param(
  [string]$Dest   = '',    # empty -> folder picker (defaults to Desktop)
  [string]$Format = '',    # tar.zst | tar.gz | tar.bz2 | zip  (empty -> dialog)
  [string]$Level  = '',    # light | std | max                 (empty -> dialog)
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { & chcp 65001 > $null } catch {}
$tar = Join-Path $env:SystemRoot 'System32\tar.exe'
$fastTarZst = Join-Path $PSScriptRoot 'bin\fast-tarzst.exe'

# ---- 言語自動判定 / auto language.  Force with env var WQA_LANG=ja|en.
#      Default: Japanese if the display language OR the region is Japanese; otherwise English.
function Get-IsJa {
  if ($env:WQA_LANG) { return ($env:WQA_LANG.Trim().ToLower().StartsWith('ja')) }
  $ui = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName
  $cu = [System.Globalization.CultureInfo]::CurrentCulture.TwoLetterISOLanguageName
  return ($ui -eq 'ja' -or $cu -eq 'ja')
}
$script:isJa = Get-IsJa
function T([string]$ja, [string]$en){ if ($script:isJa) { $ja } else { $en } }

$FORMATS = [ordered]@{
  'tar.zst' = @{ ext = '.tar.zst'; sw = '--zstd';       mod = 'zstd';  extra = ',threads=0'; lv = @{ light = 2; std = 10; max = 19 } }
  'tar.gz'  = @{ ext = '.tar.gz';  sw = '--gzip';       mod = 'gzip';  extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
  'tar.bz2' = @{ ext = '.tar.bz2'; sw = '--bzip2';      mod = 'bzip2'; extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
  'zip'     = @{ ext = '.zip';     sw = '--format=zip'; mod = 'zip';   extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
}
$LEVELKEYS = @('light', 'std', 'max')
$LEVELDISP = @{
  light = (T '軽め (高速・全CPU)' 'Light (fast, all CPUs)')
  std   = (T '標準'         'Normal')
  max   = (T '最大圧縮'     'Maximum')
}

function Fail([string]$msg){ Write-Host $msg -ForegroundColor Red; Read-Host (T 'Enter を押すと閉じます' 'Press Enter to close'); exit 1 }

if (-not $Paths -or $Paths.Count -eq 0) { Fail (T '入力がありません。' 'No input.') }
$items = @()
foreach($p in $Paths){ if(Test-Path -LiteralPath $p){ $items += (Resolve-Path -LiteralPath $p).Path } }
if ($items.Count -eq 0) { Fail (T '有効な項目がありません。' 'No valid items.') }

Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

# ---- 形式・圧縮率の選択フォーム / format & level dialog ----
if (-not $Format -or -not $Level) {
  $frm = New-Object System.Windows.Forms.Form
  $frm.Text = 'WinQuickArchiver'
  $frm.ClientSize = New-Object System.Drawing.Size(330, 175)
  $frm.FormBorderStyle = 'FixedDialog'
  $frm.StartPosition = 'CenterScreen'
  $frm.MaximizeBox = $false; $frm.MinimizeBox = $false; $frm.TopMost = $true

  $lblInfo = New-Object System.Windows.Forms.Label
  $lblInfo.Text = (T ("対象: {0} 項目" -f $items.Count) ("Items: {0}" -f $items.Count))
  $lblInfo.Location = New-Object System.Drawing.Point(16, 14); $lblInfo.AutoSize = $true
  $frm.Controls.Add($lblInfo)

  $lbl1 = New-Object System.Windows.Forms.Label
  $lbl1.Text = (T '形式:' 'Format:'); $lbl1.Location = New-Object System.Drawing.Point(16, 48); $lbl1.AutoSize = $true
  $frm.Controls.Add($lbl1)
  $cbFmt = New-Object System.Windows.Forms.ComboBox
  $cbFmt.DropDownStyle = 'DropDownList'
  $cbFmt.Location = New-Object System.Drawing.Point(95, 45); $cbFmt.Width = 210
  [void]$cbFmt.Items.AddRange(@($FORMATS.Keys))
  $cbFmt.SelectedItem = 'tar.zst'
  $frm.Controls.Add($cbFmt)

  $lbl2 = New-Object System.Windows.Forms.Label
  $lbl2.Text = (T '圧縮率:' 'Level:'); $lbl2.Location = New-Object System.Drawing.Point(16, 85); $lbl2.AutoSize = $true
  $frm.Controls.Add($lbl2)
  $cbLv = New-Object System.Windows.Forms.ComboBox
  $cbLv.DropDownStyle = 'DropDownList'
  $cbLv.Location = New-Object System.Drawing.Point(95, 82); $cbLv.Width = 210
  foreach($k in $LEVELKEYS){ [void]$cbLv.Items.Add($LEVELDISP[$k]) }
  $cbLv.SelectedIndex = 0
  $frm.Controls.Add($cbLv)

  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = 'OK'; $btnOk.Location = New-Object System.Drawing.Point(135, 132)
  $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $frm.Controls.Add($btnOk); $frm.AcceptButton = $btnOk
  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = (T 'キャンセル' 'Cancel'); $btnCancel.Location = New-Object System.Drawing.Point(220, 132)
  $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $frm.Controls.Add($btnCancel); $frm.CancelButton = $btnCancel

  if ($frm.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Format = [string]$cbFmt.SelectedItem
  $Level  = $LEVELKEYS[$cbLv.SelectedIndex]
  $frm.Dispose()
}
if (-not $FORMATS.Contains($Format)) { Fail (T "不明な形式: $Format" "Unknown format: $Format") }
if (-not $FORMATS[$Format].lv.ContainsKey($Level)) { $Level = 'light' }

$needsFastTarZst = $Format -eq 'tar.zst' -and $Level -eq 'light' -and @($items | Where-Object { Test-Path -LiteralPath $_ -PathType Container }).Count -gt 0
if ($needsFastTarZst -and -not (Test-Path -LiteralPath $fastTarZst -PathType Leaf)) {
  Fail (T "高速圧縮エンジンが見つかりません: $fastTarZst" "Fast compression engine not found: $fastTarZst")
}

# ---- 保存先(既定=デスクトップ) / destination (defaults to Desktop) ----
if (-not $Dest) {
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = (T 'アーカイブの保存先フォルダを選択' 'Choose the destination folder for the archive')
  $dlg.ShowNewFolderButton = $true
  $dlg.RootFolder   = [System.Environment+SpecialFolder]::Desktop
  $dlg.SelectedPath = [Environment]::GetFolderPath('Desktop')
  if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Dest = $dlg.SelectedPath
}
if (-not (Test-Path -LiteralPath $Dest)) { Fail (T "保存先がありません: $Dest" "Destination not found: $Dest") }

# ---- 圧縮実行(保存先へ直接書き込み) / compress straight into destination ----
$fmt  = $FORMATS[$Format]
$L    = $fmt.lv[$Level]
$opts = "$($fmt.mod):compression-level=$L$($fmt.extra)"
Write-Host (T ("形式: {0}   圧縮率: {1}(lv{2})   保存先: {3}" -f $Format, $Level, $L, $Dest) `
              ("Format: {0}   Level: {1}(lv{2})   Dest: {3}" -f $Format, $Level, $L, $Dest)) -ForegroundColor DarkGray

$okCount = 0; $failCount = 0
foreach($it in $items){
  $parent = [System.IO.Path]::GetDirectoryName($it)
  $leaf   = [System.IO.Path]::GetFileName($it)
  $useFastTarZst = $Format -eq 'tar.zst' -and $Level -eq 'light' -and (Test-Path -LiteralPath $it -PathType Container)
  $out = $null
  $targetDisplay = if ($useFastTarZst) { Join-Path $Dest ($leaf + '_YYYYMMDD-HHMMSS.tar.zst') } else { Join-Path $Dest ($leaf + $fmt.ext) }
  Write-Host ''
  Write-Host "▶ $leaf  →  $targetDisplay" -ForegroundColor Cyan
  Write-Host ("  " + (T '圧縮中... (完了までウィンドウは開いたままになります)' 'Compressing... (this window stays open until done)')) -ForegroundColor DarkGray

  if ($useFastTarZst) {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      $engineOutput = @(& $fastTarZst $it $Dest 2>&1)
      $rc = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $previousErrorAction
    }
    if ($rc -eq 0) {
      foreach ($line in $engineOutput) {
        $candidate = [string]$line
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $out = $candidate }
      }
      if (-not $out) { $rc = 1 }
    }
  } else {
    $out = Join-Path $Dest ($leaf + $fmt.ext)
    Push-Location -LiteralPath $parent
    try {
      & $tar $fmt.sw "--options=$opts" -c -f "$out" -- "$leaf"   # names hidden (faster)
      $rc = $LASTEXITCODE
    } finally { Pop-Location }
  }

  if ($rc -eq 0 -and $out -and (Test-Path -LiteralPath $out -PathType Leaf)) {
    $sz = (Get-Item -LiteralPath $out).Length
    Write-Host ("  " + (T '✓ 完了' '✓ Done') + ("  {0:N1} MB  →  {1}" -f ($sz/1MB), $out)) -ForegroundColor Green
    $okCount++
  } else {
    if ($useFastTarZst) {
      foreach ($line in $engineOutput) { Write-Host ("  " + [string]$line) -ForegroundColor DarkRed }
    }
    Write-Host ("  " + (T "✗ 失敗 (code $rc)" "✗ Failed (code $rc)")) -ForegroundColor Red; $failCount++
  }
}
Write-Host ''
Write-Host (T ("=== 完了: 成功 $okCount / 失敗 $failCount  (保存先: $Dest) ===") `
              ("=== Finished: OK $okCount / Failed $failCount  (dest: $Dest) ===")) -ForegroundColor Yellow
if ($failCount -gt 0) { Read-Host (T 'Enter を押すと閉じます' 'Press Enter to close') } else { Start-Sleep -Seconds 2 }

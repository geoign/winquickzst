<#
  WinQuickArchiver.ps1
  ------------------------------------------------------------------
  右クリックしたフォルダ(または選択したファイル群)を、選んだ保存先へ
  アーカイブとして「直接」書き出します(一時ファイル無し・移動無し)。

    形式  : tar.zst(既定) / tar.gz / tar.bz2 / zip   ← フォームで選択
    圧縮率: 軽め(既定) / 標準 / 最大                 ← フォームで選択
    エンジン: Windows 標準の bsdtar (libzstd/liblzma/zlib/bz2lib) … 追加ソフト不要
    ファイル名は tar 系では UTF-8(pax) 格納 … Linux の tar でも文字化けしない
  ------------------------------------------------------------------
  呼び出し例(自動化/テスト用にフォームを飛ばす):
    WinQuickArchiver.ps1 -Format tar.zst -Level light -Dest "D:\out" "C:\path\folder"
#>
param(
  [string]$Dest   = '',    # 省略時はフォルダ選択ダイアログ(既定=デスクトップ)
  [string]$Format = '',    # tar.zst | tar.gz | tar.bz2 | zip  (空ならフォーム)
  [string]$Level  = '',    # light | std | max                 (空ならフォーム)
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { & chcp 65001 > $null } catch {}
$tar = Join-Path $env:SystemRoot 'System32\tar.exe'

# ---- 形式テーブル (レベルは形式ごとに妥当な値へマッピング) ----
$FORMATS = [ordered]@{
  'tar.zst' = @{ ext = '.tar.zst'; sw = '--zstd';       mod = 'zstd';  extra = ',threads=0'; lv = @{ light = 2; std = 10; max = 19 } }
  'tar.gz'  = @{ ext = '.tar.gz';  sw = '--gzip';       mod = 'gzip';  extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
  'tar.bz2' = @{ ext = '.tar.bz2'; sw = '--bzip2';      mod = 'bzip2'; extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
  'zip'     = @{ ext = '.zip';     sw = '--format=zip'; mod = 'zip';   extra = '';           lv = @{ light = 2; std = 6;  max = 9  } }
}
$LEVELS = [ordered]@{ 'light' = '軽め (高速)'; 'std' = '標準'; 'max' = '最大圧縮' }

function Fail($msg){ Write-Host $msg -ForegroundColor Red; Read-Host 'Enter を押すと閉じます'; exit 1 }

if (-not $Paths -or $Paths.Count -eq 0) { Fail '入力がありません。' }
$items = @()
foreach($p in $Paths){ if(Test-Path -LiteralPath $p){ $items += (Resolve-Path -LiteralPath $p).Path } }
if ($items.Count -eq 0) { Fail '有効な項目がありません。' }

Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

# ---- 形式・圧縮率の選択フォーム ----
if (-not $Format -or -not $Level) {
  $frm = New-Object System.Windows.Forms.Form
  $frm.Text = 'WinQuickArchiver'
  $frm.ClientSize = New-Object System.Drawing.Size(330, 175)
  $frm.FormBorderStyle = 'FixedDialog'
  $frm.StartPosition = 'CenterScreen'
  $frm.MaximizeBox = $false; $frm.MinimizeBox = $false; $frm.TopMost = $true

  $lblInfo = New-Object System.Windows.Forms.Label
  $lblInfo.Text = ("対象: {0} 項目" -f $items.Count)
  $lblInfo.Location = New-Object System.Drawing.Point(16, 14); $lblInfo.AutoSize = $true
  $frm.Controls.Add($lblInfo)

  $lbl1 = New-Object System.Windows.Forms.Label
  $lbl1.Text = '形式:'; $lbl1.Location = New-Object System.Drawing.Point(16, 48); $lbl1.AutoSize = $true
  $frm.Controls.Add($lbl1)
  $cbFmt = New-Object System.Windows.Forms.ComboBox
  $cbFmt.DropDownStyle = 'DropDownList'
  $cbFmt.Location = New-Object System.Drawing.Point(95, 45); $cbFmt.Width = 210
  [void]$cbFmt.Items.AddRange(@($FORMATS.Keys))
  $cbFmt.SelectedItem = 'tar.zst'
  $frm.Controls.Add($cbFmt)

  $lbl2 = New-Object System.Windows.Forms.Label
  $lbl2.Text = '圧縮率:'; $lbl2.Location = New-Object System.Drawing.Point(16, 85); $lbl2.AutoSize = $true
  $frm.Controls.Add($lbl2)
  $cbLv = New-Object System.Windows.Forms.ComboBox
  $cbLv.DropDownStyle = 'DropDownList'
  $cbLv.Location = New-Object System.Drawing.Point(95, 82); $cbLv.Width = 210
  [void]$cbLv.Items.AddRange(@($LEVELS.Values))
  $cbLv.SelectedItem = $LEVELS['light']
  $frm.Controls.Add($cbLv)

  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = 'OK'; $btnOk.Location = New-Object System.Drawing.Point(135, 132)
  $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $frm.Controls.Add($btnOk); $frm.AcceptButton = $btnOk
  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = 'キャンセル'; $btnCancel.Location = New-Object System.Drawing.Point(220, 132)
  $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $frm.Controls.Add($btnCancel); $frm.CancelButton = $btnCancel

  $res = $frm.ShowDialog()
  if ($res -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Format = [string]$cbFmt.SelectedItem
  $Level  = ($LEVELS.GetEnumerator() | Where-Object { $_.Value -eq $cbLv.SelectedItem }).Key
  $frm.Dispose()
}
if (-not $FORMATS.Contains($Format)) { Fail "不明な形式: $Format" }
if (-not $FORMATS[$Format].lv.ContainsKey($Level)) { $Level = 'light' }

# ---- 保存先(既定=デスクトップ) ----
if (-not $Dest) {
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = 'アーカイブの保存先フォルダを選択'
  $dlg.ShowNewFolderButton = $true
  $dlg.RootFolder   = [System.Environment+SpecialFolder]::Desktop
  $dlg.SelectedPath = [Environment]::GetFolderPath('Desktop')
  if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
  $Dest = $dlg.SelectedPath
}
if (-not (Test-Path -LiteralPath $Dest)) { Fail "保存先がありません: $Dest" }

# ---- 圧縮実行(保存先へ直接書き込み) ----
$fmt  = $FORMATS[$Format]
$L    = $fmt.lv[$Level]
$opts = "$($fmt.mod):compression-level=$L$($fmt.extra)"
Write-Host ("形式: {0}   圧縮率: {1}(lv{2})   保存先: {3}" -f $Format, $Level, $L, $Dest) -ForegroundColor DarkGray

$okCount = 0; $failCount = 0
foreach($it in $items){
  $parent = [System.IO.Path]::GetDirectoryName($it)
  $leaf   = [System.IO.Path]::GetFileName($it)
  $out    = Join-Path $Dest ($leaf + $fmt.ext)
  Write-Host ''
  Write-Host "▶ $leaf  →  $out" -ForegroundColor Cyan
  Write-Host "  圧縮中... (完了までウィンドウは開いたままになります)" -ForegroundColor DarkGray
  Push-Location -LiteralPath $parent
  try {
    & $tar $fmt.sw "--options=$opts" -c -f "$out" -- "$leaf"   # ファイル名は非表示(高速)
    $rc = $LASTEXITCODE
  } finally { Pop-Location }
  if ($rc -eq 0 -and (Test-Path -LiteralPath $out)) {
    $sz = (Get-Item -LiteralPath $out).Length
    Write-Host ("  ✓ 完了  {0:N1} MB" -f ($sz/1MB)) -ForegroundColor Green
    $okCount++
  } else {
    Write-Host "  ✗ 失敗 (code $rc)" -ForegroundColor Red; $failCount++
  }
}
Write-Host ''
Write-Host ("=== 完了: 成功 $okCount / 失敗 $failCount  (保存先: $Dest) ===") -ForegroundColor Yellow
if ($failCount -gt 0) { Read-Host 'Enter を押すと閉じます' } else { Start-Sleep -Seconds 2 }

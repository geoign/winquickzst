# WinQuickArchiver

フォルダを右クリック → 形式と圧縮率を選ぶ → 保存先を選ぶと、その場所へ
アーカイブを **直接** 書き出します（一時ファイルも移動もなし・大容量向き）。

- **エンジン**: Windows 標準の `bsdtar`（libzstd / liblzma / zlib / bz2lib 内蔵）。追加ソフト不要。
- **対応形式**: `tar.zst`（既定）/ `tar.gz` / `tar.bz2` / `zip`
- **圧縮率**: 軽め（既定・高速）/ 標準 / 最大
- tar 系はファイル名を **UTF-8(pax)** で格納 → Linux の `tar` でも文字化けしません。
- zstd は全 CPU コアでマルチスレッド圧縮。

## インストール

`Install.ps1` を右クリック →「PowerShell で実行」。
（管理者不要・HKCU のみ。エクスプローラーを再起動すると確実に反映）

## 使い方

- **1 フォルダ**: 右クリック →「WinQuickArchiver で圧縮…」
  - Windows 11 で最上段に出ないときは「その他のオプションを表示」(Shift+F10) の中。
- **複数選択**: 選択 → 右クリック → **送る** → 「WinQuickArchiver」
- 保存先ダイアログは既定で **デスクトップ** を開きます。

## 既定値の変更

`WinQuickArchiver.ps1` の `$FORMATS` テーブルでレベル値を調整できます
（例: `tar.zst` の `light=2` を別の値へ）。

## Linux 側での展開

```bash
tar --zstd -xf name.tar.zst     # zstd
tar -xzf   name.tar.gz          # gzip
tar -xjf   name.tar.bz2         # bzip2
unzip      name.zip             # zip
```

## アンインストール

`Uninstall.ps1` を実行（右クリック項目と送るを削除）。最後に本フォルダを手動削除。

## 注意

- Windows 側の tar は Unix のパーミッション / 所有者 / シンボリックリンクを完全には
  保存しません。実行ビットや symlink を厳密に再現したい場合は Linux（または WSL）側で
  tar 化してください。データファイルの受け渡しなら問題ありません。
- 本体は OneDrive 配下にあります。OneDrive の「空き容量を増やす（オンラインのみ）」で
  ファイルが実体を持たなくなると右クリックが失敗するため、フォルダを
  「このデバイス上に常に保持する」に設定しておくと安全です。

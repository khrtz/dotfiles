# dotfiles

Windows Terminal と PowerShell 7 の環境です。Claude Code や Codex との対話を前提に、見やすさと使いやすさを重視しています。

- 配色：Catppuccin Mocha（ターミナル、プロンプト、入力のハイライト、fzf、bat、delta のすべてで統一）
- フォント：PlemolJP Console NF（日本語と英数字が 2:1 の幅でそろい、Nerd Font のアイコンも使えます）
- プロンプト：Starship の2行表示（1行目にフォルダ、Git、実行時間、時刻。2行目に `❯`）

## 新しい PC でのセットアップ

前提は Windows 10 / 11 と winget（「アプリ インストーラー」）です。

Windows PowerShell で、Git と GitHub CLI を入れてリポジトリを取得します。

```powershell
winget install -e --id Git.Git
winget install -e --id GitHub.cli
```

ここで PowerShell を開き直してから、続けて実行します。

```powershell
gh auth login
gh repo clone khrtz/dotfiles $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File $HOME\dotfiles\bootstrap.ps1
```

`bootstrap.ps1` は次の処理を行います。何度実行しても安全で、入っているものはスキップします。

1. winget で Windows Terminal、PowerShell 7、CLI ツール類をインストール
2. PlemolJP Console NF を GitHub のリリースからダウンロードして、ユーザー単位でインストール
3. PowerShell モジュール PSFzf をインストール
4. Claude Code と Codex を npm でインストール（Node がなければ Node LTS も入れます）
5. `install.ps1` で設定ファイルを配置

途中の工程を飛ばしたいときは、`-SkipPackages`、`-SkipFont`、`-SkipAI` を付けて実行します。PowerShell 7 のインストール時に、管理者権限の確認画面が出ることがあります。

## 設定を変更したとき

ファイルを編集したら、次のコマンドで反映します。

```powershell
pwsh -File $HOME\dotfiles\install.ps1
```

`install.ps1` が行うこと：

- PowerShell 7 のプロファイル（`$PROFILE`）を、`powershell/profile.ps1` を読み込む1行だけにする
- `windows-terminal/settings.json` を Windows Terminal の設定フォルダにコピー
- Git の差分表示に delta を使うよう設定
- Claude Code の `~/.claude/settings.json` に `"preferredNotifChannel": "terminal_bell"` を追加（他の設定はそのまま）

上書きするファイルは、事前に `*.bak-日時` としてバックアップします。

## 構成

| ファイル | 内容 |
|---|---|
| `bootstrap.ps1` | 新しい PC 用の一括セットアップ |
| `install.ps1` | 設定ファイルの配置 |
| `powershell/profile.ps1` | PowerShell 7 のプロファイル本体 |
| `starship/starship.toml` | プロンプトの設定 |
| `windows-terminal/settings.json` | Windows Terminal の設定 |

## 使い方

| やりたいこと | 操作 |
|---|---|
| 左に Claude、右にシェルの分割画面を開く | `ai`（Codex なら `ai codex`） |
| Claude / Codex の新しいタブを開く | `Alt+Shift+C` / `Alt+Shift+X` |
| 履歴 / ファイルをあいまい検索 | `Ctrl+R` / `Ctrl+T` |
| フォルダへ移動 | `z フォルダ名` |
| 一覧表示（アイコン付き） | `ls` / `ll` / `la` / `lt`（ツリー表示） |
| 入力中に改行 | `Shift+Enter` |
| 予測候補の表示を切り替え | `F2` |
| ドロップダウン表示のターミナル | `Win+半角/全角`（英語キーボードでは `` Win+` ``） |

## メモ

- 起動を速くするため、starship と zoxide の初期化スクリプトを `~/.cache/pwsh` にキャッシュしています。各ツールを更新すると自動で作り直されます。
- `fnm` が入っていれば、Node のバージョンを自動で切り替えます。入っていなければ何もしません。

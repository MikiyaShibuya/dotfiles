- [ ] 各種nvimのバイナリを自動で最新化するスクリプトを作成
- [x] Claudeのglobal設定（.claude/settings.json）のインストールを実装
- [ ] zsh-historyの自動修復機能を実装
  - zshの履歴ファイルが破損した場合に自動で検出・修復する
  - `fc -R` でエラーが発生した際のハンドリング
  - バックアップからの復元や、破損行の除去などを検討

## インストールスクリプトのレビュー

### スクリプト構成

```
install.sh                      # メインインストーラ（root権限必要）
├── shell/setup_diff_highlight.sh  # diff-highlightのセットアップ
├── as_user_install.sh             # ユーザー権限でのセットアップ
└── ~/.tmux/plugins/tpm/scripts/install_plugins.sh  # tmuxプラグイン
```

### 使用方法

| スクリプト | 実行方法 | 備考 |
|-----------|---------|------|
| install.sh | `sudo USER=$USER ./install.sh` | dotfilesディレクトリ内で実行必須 |
| as_user_install.sh | install.shから自動呼び出し | 直接実行不可（$PWD依存） |
| setup_diff_highlight.sh | install.shから自動呼び出し | root権限+USER変数必要 |
| uninstall.sh | `./uninstall.sh` | ユーザー権限で実行 |

### 問題点・改善案

#### install.sh
- [x] 相対パス依存: スクリプト・debファイルを相対パスで参照しているため、dotfilesディレクトリ外からの実行不可
  - `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` でスクリプトディレクトリを取得すべき
- [ ] コマンドライン引数なし: `--dry-run`、`--verbose`、`--help` などのオプションがない
- [ ] Mac/Linux間でNode.jsインストール方法が異なる（brew vs fnm）
- [x] USER環境変数の渡し方が煩雑: `sudo USER=$USER ./install.sh` は分かりにくく忘れやすい
  - `$SUDO_USER` を使えば `sudo ./install.sh` だけで動作可能

#### as_user_install.sh
- [x] `$PWD` 依存: シンボリックリンク作成に$PWDを使用しているため、実行ディレクトリに制約
  - DOTFILES_DIRを使用するように修正済み
- [x] `zsh $HOME/.zshrc` の実行意図が不明（サブシェルでsourceしても親シェルに影響なし）
  - 削除済み
- [x] `python3 -m $PIP_INSTALL_CMD pip` の記法が可読性低い（変数展開でコマンド構築）
  - 直接コマンドを記述するように修正済み

#### shell/setup_diff_highlight.sh
- [x] エラーハンドリング: `set -e` のみ（`set -euo pipefail` ではない）
  - `set -euo pipefail` に修正済み
- [x] `cd` を使用しているがエラー時の復帰考慮なし
  - `pushd`/`popd` を使用するように修正済み

#### uninstall.sh
- [x] エラーハンドリングなし（`set -e` すらない）
  - `set -euo pipefail` を追加済み
- [x] 不整合: as_user_install.shで作成したwezterm、claude設定のunlinkが漏れている
  - wezterm, claude設定のunlinkを追加済み
- [x] 不整合: .gitconfigは `cat >> ` で追記しているのに `unlink` している（ファイル削除になる）
  - 手動編集が必要な旨のメッセージを表示するように修正済み
- [x] 不整合: tmux.confは `~/.config/tmux/tmux.conf` にリンクしているのに `~/.tmux.conf` をunlink
  - 両方のパスに対応済み（新形式とTmux < 3.1のレガシー形式）
- [x] .zshrcは追記方式なのにunlinkしている
  - 手動編集が必要な旨のメッセージを表示するように修正済み

#### 全般
- [x] エラーハンドリングの一貫性なし
  - 全スクリプトで `set -euo pipefail` に統一済み
- [x] スクリプト冒頭の説明コメントがない（使用方法・前提条件）
  - 全スクリプトに説明コメント追加済み
- [x] READMEに「dotfilesディレクトリ内で実行必須」の記載がない
  - SCRIPT_DIR対応により任意のディレクトリから実行可能になった（Manual Installationセクションに記載済み）

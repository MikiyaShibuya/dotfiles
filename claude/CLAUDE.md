# Editor Preference

- **vim を使用すること**
- ファイル編集の例示では常に vim を使用
- sudo での編集: `sudo vim /path/to/file`

# Global Code Review Checklist

## std::function
- 呼び出し前にnullチェック (`if (func)`) があるか
- 引数は値渡し+ムーブを検討（コピーコストを避ける）
- キャプチャのライフタイムは安全か

## シグネチャ変更時
- 引数の渡し方（値/const参照/右辺値参照）は適切か
- ムーブセマンティクスを活用できるか
- 既存の呼び出し元への影響

## スマートポインタ
- 所有権は明確か
- `shared_ptr` vs `unique_ptr` の選択は適切か
- 循環参照の可能性はないか

## 一般
- 防御的プログラミング: 単体で正しく動作するか（現在の呼び出し元だけでなく）
- エラーハンドリング: 失敗ケースは適切に処理されているか

# システム管理の禁止事項

## OEMカーネル/パッケージ
- **OEMカーネル・OEMパッケージは絶対にインストールしない**
- `ubuntu-drivers autoinstall` は使用禁止（OEMパッケージがインストールされる可能性がある）
- `oem-*`, `linux-*-oem*` パッケージは一切インストールしない
- Lenovo OEMリポジトリ (`lenovo.archive.canonical.com`) は追加・有効化しない

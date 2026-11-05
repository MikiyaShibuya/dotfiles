# スライドの自律生成手順（pptx → Google Slides）

Claude がスライドを作る場合の標準手順。図・レイアウト・文章をすべて生成し、
閲覧可能な Google Slides の URL を返すところまでを人手の介在なしで行う。

## 方式の選定理由

pptx を生成して Drive API でアップロードし、その際に Google Slides 形式へ変換させる。
Drive API がサーバ側で変換するため、インポート操作が不要で、
変換後もテキストと図形が編集可能なオブジェクトとして残る。

他の方式を採らない理由は次のとおり。
Slides API による直接構築は要素ごとの API 呼び出しが冗長で、pptx 生成に対する利点が無い。
Marp / reveal.js は生成は速いが GUI でのレイアウト調整ができない。
PDF は編集できない。Canva の公開 API はブランドテンプレートへの autofill が中心で、
任意のレイアウトを一から組み立てられない。

## 前提

- `gcloud auth login --enable-gdrive-access` で drive スコープ付きの認証が済んでいること
- Google Workspace の再認証ポリシーにより一定期間で失効する。
  `gcloud auth print-access-token` が `Reauthentication failed` を返したら
  ユーザーに対話端末での再ログインを依頼する（非対話セッションでは通せない）
- スコープの確認方法（drive が含まれているか）:

```bash
python3 -c "
import sqlite3,re
c=sqlite3.connect('/home/mshibuya/.config/gcloud/credentials.db')
for acct,val in c.execute('select account_id, value from credentials'):
    print(acct)
    for x in sorted(set(re.findall(r'https://www.googleapis.com/auth/[A-Za-z._-]+', val))):
        print('  ',x)
"
```

## 作業ディレクトリと環境

`~/tmp/<deck-name>/` に作る。リポジトリ内に置かない（成果物と中間物でワークツリーを汚さない）。
`~/tmp` は再起動で消えない。

```bash
mkdir -p ~/tmp/<deck-name>
python3 -m venv ~/tmp/<deck-name>/venv
~/tmp/<deck-name>/venv/bin/pip -q install python-pptx
```

システムディレクトリへの pip install は禁止されているため、必ず venv を使う。

## ファイル構成

内容・レイアウト・アップロードを3ファイルに分ける。
文言の手直しが最も頻繁に発生するため、それをレイアウトから独立させる。

| ファイル | 役割 |
|---|---|
| `content.py` | 各ページの文言をデータとして定義する。ここだけ直せば作り直せる |
| `make_deck.py` | レイアウト・配色・図形の生成。`content.py` を import する |
| `upload.sh` | Drive へのアップロードと Google Slides への変換 |

## content.py の書き方

ページごとのタプル（またはdict）のリストにする。未記入箇所は `PLACEHOLDER` 定数を置き、
`make_deck.py` 側でグレー表示に切り替える。出典を先頭コメントに書く。

```python
PLACEHOLDER = "（記入予定）"

ITEMS = [
    ("01", "項目名", "◯", "要件の本文", "評価の本文", "残作業の本文"),
    ("02", "項目名", "NA", "要件の本文", PLACEHOLDER, PLACEHOLDER),
]
```

段落の区切りは本文中の `\n` で表し、`make_deck.py` 側で `split("\n")` して段落に展開する。

## make_deck.py の要点

python-pptx の既定テンプレートを使い、レイアウトは `slide_layouts[6]`（白紙）だけを使う。
プレースホルダ入りのレイアウトは変換時に崩れやすい。

```python
prs = Presentation()
prs.slide_width  = Inches(13.333)   # 16:9
prs.slide_height = Inches(7.5)
slide = prs.slides.add_slide(prs.slide_layouts[6])
```

守る点は次のとおり。

- **フォントは `Noto Sans JP` を明示指定する。** Google Slides に標準で存在し日本語が化けない。
  run ごとに `run.font.name` を設定する（段落レベルの指定は変換時に落ちることがある）
- **図形の影を消す。** `shape.shadow.inherit = False` を入れないと既定の影が付く
- **枠線を消す場合は `shape.line.fill.background()`。** `line.color` を触るだけでは消えない
- **テキストボックスの内部余白をゼロにする。** `margin_left` 等を 0 にしないと
  パネルとの位置合わせがずれる
- **`word_wrap = True` を必ず設定する。** 既定では折り返さず、はみ出す
- SVG は Google Slides が受け付けないため、図は PNG で貼る。
  PowerPoint でしか開かないなら SVG のまま入れて編集可能な図として保持できる
- 社内テンプレートの .pptx があれば `Presentation("template.pptx")` をベースにすると
  フォント・配色・マスターがそのまま効く

判定やステータスを色分けする場合は、記号 → (地色, 文字色, 読み下し) の dict を1箇所に持ち、
バッジとサマリページの両方から引く。色の定義を散らさない。

## upload.sh

```bash
#!/bin/bash
set -euo pipefail

FILE="${1:?pptx path}"
NAME="${2:?slides name}"

TOKEN=$(gcloud auth print-access-token)

META=$(mktemp /tmp/drivemeta.XXXX.json)
printf '{"name":"%s","mimeType":"application/vnd.google-apps.presentation"}' "$NAME" > "$META"

curl -sS -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "metadata=@${META};type=application/json;charset=UTF-8" \
  -F "file=@${FILE};type=application/vnd.openxmlformats-officedocument.presentationml.presentation" \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true&fields=id,name,webViewLink"

rm -f "$META"
```

`mimeType` に `application/vnd.google-apps.presentation` を指定することが変換のトリガー。
これを省くと pptx がそのまま Drive に置かれるだけで Slides にならない。
`metadata` パートに `charset=UTF-8` を付けないと日本語のファイル名が化ける。

既存の Slides を差し替える場合は `PATCH https://www.googleapis.com/upload/drive/v3/files/<id>`
に変える。URL が変わらないので、レビュー中の作り直しはこちらが望ましい。

## 進め方

1. ページ構成（各ページの見出しと要点）を先にテキストで出してレビューを受ける。
   いきなり pptx を作ると手戻りが大きい
2. 分量が多い場合は主要ページだけ埋め、残りは `PLACEHOLDER` にして早くレビューに回す
3. 生成 → アップロード → URL を提示
4. 手直しは Google Slides 上で直接行ってもらう。
   文言の大きな変更は `content.py` を直して再生成し、`PATCH` で同じ URL に上書きする

## 出典の扱い

元になった調査結果やドキュメントがある場合、`content.py` の先頭コメントにパスを書く。
スライドと元ドキュメントで記述が食い違ったとき、どちらが新しいかを追えるようにする。
スライドにだけ書いて元ドキュメントに無い内容が生じたら、その旨をユーザーに伝える。

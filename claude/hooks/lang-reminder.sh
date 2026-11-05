#!/usr/bin/env bash
# compaction 要約・通知・ツール出力が英語だと、直前の自分の英語応答に引きずられて
# 日本語の発言にも英語で返し続ける。返答直前の位置に言語を明示して断ち切る。
prompt=$(jq -r '.prompt // ""')
if printf '%s' "$prompt" | grep -qP '[\p{Hiragana}\p{Katakana}\p{Han}]'; then
  jq -n '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: "ユーザーの直近の発言は日本語。このターンで書くテキストは、ツール実行前の宣言・途中経過・最終回答のすべてを日本語で書く。直前までの自分の応答が英語だった場合、それは言語の誤りなので引き継がない。"}}'
fi
exit 0

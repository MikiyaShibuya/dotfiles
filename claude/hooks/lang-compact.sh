#!/usr/bin/env bash
# compaction 直後はユーザー発言が無いまま英語の要約に続けて書くため、UserPromptSubmit では防げない。
# 要約の直後に会話言語を明示し、最初のテキストから日本語で書かせる。
tp=$(jq -r '.transcript_path // ""')
[ -f "$tp" ] || exit 0
tail -n 5000 "$tp" | jq -rs '
  def texts: (.message.content | if type=="string" then [.] else [.[]? | select(.type=="text") | .text] end);
  ([.[] | select(.type=="user" and (.isMeta|not) and (.isCompactSummary|not))
        | texts | map(select(startswith("<task-notification>") or startswith("<system-reminder>") | not))
        | select(length>0) | join("\n")] | last // "") as $u
  | if ($u | test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")) then
      {hookSpecificOutput: {hookEventName: "SessionStart",
        additionalContext: "会話の言語は日本語。compaction 要約・通知・ツール出力が英語でも、ユーザーの直近の発言は日本語なので、要約直後に書く最初のテキストから日本語で書く。"}}
    else empty end'
exit 0

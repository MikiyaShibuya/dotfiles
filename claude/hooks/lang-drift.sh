#!/usr/bin/env bash
# 途中経過が一度英語になると、ツール出力も英語のため以降も英語のまま進む。
# 直前の自分のテキストが英語になった時だけ、次のテキストの直前で日本語へ戻させる。
# 英文中に「直近」等の日本語語句が混ざっても英語と判定できるよう、文字数比で判定する。
tp=$(jq -r '.transcript_path // ""')
[ -f "$tp" ] || exit 0
tail -n 2000 "$tp" | jq -rs '
  def jpn: [scan("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")] | length;
  def lat: [scan("[A-Za-z]")] | length;
  def prose: gsub("```[\\s\\S]*?```"; "") | gsub("`[^`]*`"; "") | gsub("https?://\\S+"; "") | gsub("<[^>]*>"; "");
  def english: prose as $s | ($s|lat) > 20 and ($s|lat) > 3 * ($s|jpn);
  def texts: (.message.content | if type=="string" then [.] else [.[]? | select(.type=="text") | .text] end);
  ([.[] | select(.type=="user" and (.isMeta|not) and (.isCompactSummary|not))
        | texts | map(select(startswith("<task-notification>")|not)) | select(length>0) | join("\n")] | last // "") as $u
  | ([.[] | select(.type=="assistant") | texts | .[]] | last // "") as $a
  | if ($u | test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")) and ($a | english) then
      {hookSpecificOutput: {hookEventName: "PostToolUse",
        additionalContext: "直前の途中経過を英語で書いてしまっている。ユーザーは日本語で話しているので、次に書くテキストから日本語に戻す。"}}
    else empty end'
exit 0

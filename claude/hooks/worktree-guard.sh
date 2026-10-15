#!/usr/bin/env bash
# PreToolUse(Bash) hook: `git worktree add|move` の作成先を CLAUDE.md「worktree」の置き場に限定する。
# 解釈できないコマンドは通す。誤検知で作業を止める害の方が大きいため。
set -uo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[[ -n "$cmd" && -n "$cwd" ]] || exit 0
grep -Eq '\bworktree[[:space:]]+(add|move)\b' <<<"$cmd" || exit 0

deny() {
  jq -n --arg r "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# 戻り値 1 は「解釈不能」。呼び出し側はそのまま通す。
expand() {
  local t="$1"
  t="${t#[\"\']}"; t="${t%[\"\']}"
  t="${t/#\~/$HOME}"
  t="${t//\$\{HOME\}/$HOME}"
  t="${t//\$HOME/$HOME}"
  [[ "$t" == *'$'* || "$t" == *'`'* ]] && return 1
  printf '%s' "$t"
}

check_segment() {
  local -a toks
  read -ra toks <<<"$1"
  local i=0 n=${#toks[@]} dir="$cwd" t
  while [[ $i -lt $n && "${toks[$i]}" != git ]]; do i=$((i + 1)); done
  i=$((i + 1))
  while [[ $i -lt $n ]]; do
    case "${toks[$i]}" in
      -C) t=$(expand "${toks[$((i + 1))]:-}") || return 0
          [[ "$t" == /* ]] && dir="$t" || dir="$dir/$t"
          i=$((i + 2)) ;;
      -c) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [[ "${toks[$i]:-}" == worktree ]] || return 0
  local sub="${toks[$((i + 1))]:-}"
  [[ "$sub" == add || "$sub" == move ]] || return 0
  i=$((i + 2))

  # move は 2 番目の位置引数が移動先。
  local want=1 pos=0 path="" opts_done=0
  [[ "$sub" == move ]] && want=2
  while [[ $i -lt $n ]]; do
    t="${toks[$i]}"
    if [[ $opts_done -eq 0 ]]; then
      case "$t" in
        --) opts_done=1; i=$((i + 1)); continue ;;
        -b|-B|--reason) i=$((i + 2)); continue ;;
        -*) i=$((i + 1)); continue ;;
      esac
    fi
    pos=$((pos + 1))
    if [[ $pos -eq $want ]]; then path="$t"; break; fi
    i=$((i + 1))
  done
  [[ -n "$path" ]] || return 0
  path=$(expand "$path") || return 0
  [[ "$path" == /* ]] || path="$dir/$path"

  local common top area name expected
  common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
  if [[ $(basename "$common") == .git ]]; then
    top=$(dirname "$common")
    expected="$top/.claude/worktrees"
  elif [[ "$common" == */.git/* ]]; then
    # サブモジュールは最上位リポジトリ側に置く。名前は .git/modules 以下の階層から取る。
    top="${common%%/.git/*}"
    name=$(sed -E 's#^worktrees/[^/]+/##; s#(^|/)modules/#\1#g' <<<"${common#"$top"/.git/}")
    expected="$top/.claude/submodule-worktrees/$name"
  else
    return 0
  fi

  path=$(realpath -m "$path")
  expected=$(realpath -m "$expected")
  [[ "$path" == "$expected"/* ]] && return 0
  deny "worktree の置き場は $expected/<名前>（例: $expected/$(basename "$path")）。CLAUDE.md「worktree」参照"
}

while IFS= read -r seg; do
  [[ "$seg" =~ worktree[[:space:]]+(add|move) ]] && check_segment "$seg"
done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$cmd")
exit 0

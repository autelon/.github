#!/usr/bin/env bash
# 저장소 하나에 Autelon 표준(저장소 설정 + main ruleset)을 적용하고, 적용된 값을 다시 읽어 보여 준다.
# 여러 번 돌려도 같은 결과가 된다. 표준을 바꾸면 이 스크립트를 다시 돌려 각 저장소에 반영한다.
#
# 사용: scripts/setup-repo.sh <owner/repo> [필수 검사 이름 ...]
#   필수 검사 이름을 안 주면 "check" 하나를 쓴다.
#   public 저장소는 머지 큐를 켠다. private 저장소는 Free 조직에서 머지 큐를 못 쓰므로
#   머지 큐 규칙을 빼고 "up to date 필수"(strict)를 켠다.
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "사용: $0 <owner/repo> [필수 검사 이름 ...]" >&2
  exit 1
fi

repo=$1
shift
if [ $# -eq 0 ]; then
  set -- check
fi

dir=$(cd "$(dirname "$0")/.." && pwd)
visibility=$(gh api "repos/$repo" --jq .visibility)

echo "== 저장소 설정 ($repo, $visibility)"
gh api -X PATCH "repos/$repo" \
  -F allow_merge_commit=true \
  -F allow_squash_merge=false \
  -F allow_rebase_merge=false \
  -F allow_auto_merge=true \
  -F allow_update_branch=true \
  -F delete_branch_on_merge=true \
  -f merge_commit_title=PR_TITLE \
  -f merge_commit_message=PR_BODY \
  --jq '{allow_merge_commit, allow_squash_merge, allow_rebase_merge, allow_auto_merge, allow_update_branch, delete_branch_on_merge, merge_commit_title, merge_commit_message}'

checks=$(printf '%s\n' "$@" | jq -R '{context: .}' | jq -s .)
ruleset=$(jq --argjson checks "$checks" --arg visibility "$visibility" '
  .rules |= map(
    if .type == "required_status_checks" then
      .parameters.required_status_checks = $checks
      | .parameters.strict_required_status_checks_policy = ($visibility != "public")
    else . end
  )
  | if $visibility == "public" then . else .rules |= map(select(.type != "merge_queue")) end
' "$dir/rulesets/main.json")

existing=$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "main" and .source_type == "Repository") | .id')

echo "== main ruleset"
if [ -n "$existing" ]; then
  echo "$ruleset" | gh api -X PUT "repos/$repo/rulesets/$existing" --input - --jq '{id, name, enforcement}'
else
  echo "$ruleset" | gh api -X POST "repos/$repo/rulesets" --input - --jq '{id, name, enforcement}'
fi

echo "== 적용된 규칙"
id=$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "main" and .source_type == "Repository") | .id')
gh api "repos/$repo/rulesets/$id" --jq '.rules[] | {type, parameters}'

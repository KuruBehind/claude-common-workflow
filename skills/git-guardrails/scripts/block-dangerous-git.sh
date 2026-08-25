#!/bin/bash
# git push / push --force는 의도적으로 차단 목록에서 제외했습니다.
# 이미 각 프로젝트 .claude/settings.json의 "ask" 권한으로 매번 확인받고 있고,
# push는 정상 업무에서 수시로 필요한 명령이라 하드블록하면 업무가 막힙니다.
# 여기서 막는 건 "정상 업무에서 쓸 일이 거의 없고, 되돌릴 수 없는" 명령어만입니다.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
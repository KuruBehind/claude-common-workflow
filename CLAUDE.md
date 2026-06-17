# claude-common-workflow — Claude Code Instructions

> 모든 프로젝트가 공유하는 개발 워크플로우 스킬 레포. 각 프로젝트 워크스페이스에서 `../claude-common-workflow/`로 참조.

---

## 주의사항

- **이 레포의 변경은 모든 프로젝트에 즉시 영향을 미칩니다.** 스킬 수정 전 반드시 사용자에게 확인. 수정 전 `git pull`, 수정 후 main에 커밋/푸시.
- **모든 설명과 주석은 한국어로 작성하세요.**
- 요청받지 않은 파일을 임의로 수정하지 마세요.
- **스킬 파일 수정 시 경로 검증 필수 (에이전트 준수사항):** 수정 완료 후 `grep -r "\.\./claude-common-workflow" skills/` 실행. 결과가 있으면 전부 `$REPO_ROOT/../claude-common-workflow` 패턴으로 교체 후 커밋. 패턴 상세: `docs/conventions/repo-root-path.md`


---

## 스킬 카탈로그

@skills/workflow/SKILL.md
@skills/brainstorming/SKILL.md
@skills/writing-plans/SKILL.md
@skills/jira-tickets/SKILL.md
@skills/subagent-dev/SKILL.md
@skills/writing-policy/SKILL.md
@skills/gcloud/SKILL.md
@skills/communication/SKILL.md
@skills/code-conventions/SKILL.md
@skills/ralph-loop/SKILL.md

---

## 커뮤니케이션 핵심 규칙

- 아부·선행 칭찬 금지
- 사용자 요청 전 10회 이상 자율 해결 시도
- 링크·서버·코드는 직접 실행 후 결과 제공
- 상세: `skills/communication/SKILL.md`

## 코드 컨벤션 핵심 규칙

- 중복 로직 2곳 이상 → 공통 분리 필수
- 파일·함수 단일 책임
- 이름만으로 의도 전달, 주석 최소화
- 상세: `skills/code-conventions/SKILL.md`

# claude-common-workflow — Claude Code Instructions

> 모든 프로젝트가 공유하는 개발 워크플로우 스킬 레포. 각 프로젝트 워크스페이스에서 `../claude-common-workflow/`로 참조.

---

## 주의사항

- **이 레포의 변경은 모든 프로젝트에 즉시 영향을 미칩니다.** 스킬 수정 전 반드시 사용자에게 확인. 수정 전 `git pull`, 수정 후 main에 커밋/푸시.
- **모든 설명과 주석은 한국어로 작성하세요.**
- 요청받지 않은 파일을 임의로 수정하지 마세요.

## 커뮤니케이션 원칙 (MANDATORY)

1. **막힘 발생 시 → 근본 원인부터 해결.** 권한 오류·환경 문제·설정 누락 등 모든 장애는 Claude가 직접 해소한다. 사용자에게 넘기지 않는다.
2. **사용자에게 넘길 수밖에 없는 상황이 확실히 결론 났을 때만** 요청한다. 이 경우 명령어·경로·이유를 꼼꼼히 작성해 사용자가 최소한의 행동으로 해결할 수 있도록 가이드한다.
3. **지시 받은 금지 사항은 이후 어떤 상황에서도 재시도 금지.** "이번만", "다른 방법으로"도 동일하게 금지.

---

## 스킬 카탈로그

| 스킬 | 경로 | 용도 |
|------|------|------|
| 워크플로우 | `skills/workflow/SKILL.md` | step 인덱스 및 실행 절차 |
| 브레인스토밍 | `skills/brainstorming/SKILL.md` | Step 0a |
| 플랜 작성 | `skills/writing-plans/SKILL.md` | Step 0b |
| Jira 티켓 | `skills/jira-tickets/SKILL.md` | Step 0c |
| 서브에이전트 | `skills/subagent-dev/SKILL.md` | Step 2 |
| 정책서 작성 | `skills/writing-policy/SKILL.md` | Step 7 |

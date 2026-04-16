# claude-common-skills

Claude Code 공통 스킬셋. 서비스 그룹에 관계없이 재사용 가능한 범용 스킬 모음.

## 사용 방법

`~/Desktop/dev/` 아래 clone:

```bash
git clone https://github.com/KuruBehind/claude-common-skills
```

각 서비스 그룹 워크스페이스의 `CLAUDE.md`에서 상대경로로 참조:

```markdown
## 공통 스킬 (`../claude-common-skills/`)
- [브레인스토밍] `../claude-common-skills/brainstorming/SKILL.md`
- [플랜 작성] `../claude-common-skills/writing-plans/SKILL.md`
- ...
```

## 스킬 목록

| 스킬 | 설명 |
|------|------|
| `brainstorming` | Step 0a 설계 수립 프로세스 |
| `writing-plans` | Step 0b 구현 플랜 작성 |
| `writing-policy` | Step 7 기획 정책서 + 개발 독스 작성 |
| `subagent-dev` | Step 2 태스크별 독립 에이전트 실행 |
| `flutter-testing-apps` | Flutter Unit/Widget/Integration 테스트 전략 |
| `flutter-building-forms` | Flutter 폼 유효성 검증 패턴 |
| `firebase` | Firebase CLI/프로젝트 기반 설정 원칙 |

## 업데이트

```bash
cd ~/Desktop/dev/claude-common-skills && git pull
```

# [프로젝트명] — Claude Code Instructions

> **이 파일은 `claude-common-workflow` 기반 템플릿입니다.**
> 새 프로젝트 셋업 시 이 파일을 복사 후 `<!-- TODO -->` 항목을 채워 사용하세요.

---

## 페르소나

- **모든 설명과 코드 내 주석은 한국어(Korean)로 작성하세요.**
- 요청받지 않은 전역 설정 파일을 임의로 수정하지 마세요. 수정이 필요하면 변경 이유를 먼저 제안.
<!-- TODO: 프로젝트별 추가 페르소나 규칙 -->

---

## 프로젝트 구조

```
[workspace]/                   <!-- TODO: 워크스페이스 구조 작성 -->
├── CLAUDE.md
├── skills/                    ← 프로젝트 전용 스킬 (Jira, 환경 등)
└── [서브프로젝트]/             ← 독립 git repo
```

---

## 워크플로우 (IMPORTANT — 반드시 순서대로 수행)

> `1 워크트리 셋업` → `0a 브레인스토밍` → `0b 플랜 작성` → `0c Jira 티켓 생성` → `2 코드 작성` → `3 단위 테스트` → `4 정적 검증` → `5 통합 테스트` → `6 커밋/푸시/PR` → `7 정책서 작성/갱신` → `8 워크트리 정리`

- YOU MUST follow the step sequence strictly. 건너뛰기·순서 변경·자의적 생략 금지. step 전환 시 번호를 명시.
- step 5 실패 시 → step 2로 돌아가 2→3→4→5 반복. **실패 상태에서 step 6 진입 금지.**
- 정적 검증(step 4) 통과는 커밋 전 필수. <!-- TODO: 프로젝트 lint 명령어 명시 -->
- 워크트리 셋업(step 1)은 **대상 서브프로젝트 디렉토리 안에서** 수행.

---

## 코드 작성 규칙

- **기술 용어 UI 노출 금지.** 내부 기술 용어를 사용자 UI에 노출하지 않음. 사용자가 이해할 수 있는 표현으로 대체.
- 디자인/스타일은 요청받지 않은 한 임의 수정 금지. 변경이 필요하면 사용자에게 먼저 질문.
<!-- TODO: 언어/프레임워크 네이밍 컨벤션 -->

---

## PR 규칙

- base 브랜치는 반드시 `dev` (`gh pr create --base dev`)
- `gh auth status`로 인증 확인 → 브랜치 푸시 확인 → 빈 diff 방지 (`git log dev..HEAD`)
- PR 양식은 각 레포의 `.github/PULL_REQUEST_TEMPLATE.md`를 따름
- PR 작업 시 반드시 **대상 서브프로젝트 디렉토리로 이동** 후 git 명령 실행

---

## 기술 스택

<!-- TODO: 서비스 그룹의 기술 스택 작성 -->

---

## 스킬 카탈로그

> `claude-common-workflow`가 `../claude-common-workflow/`에 clone되어 있어야 합니다.
> 없으면: `git clone https://github.com/KuruBehind/claude-common-workflow ../claude-common-workflow`

### 공통 워크플로우 스킬 (`../claude-common-workflow/skills/`)

- **[워크플로우]** `../claude-common-workflow/skills/workflow/SKILL.md` — step 인덱스 및 실행 절차
- **[브레인스토밍]** `../claude-common-workflow/skills/brainstorming/SKILL.md` — Step 0a
- **[플랜 작성]** `../claude-common-workflow/skills/writing-plans/SKILL.md` — Step 0b
- **[서브에이전트]** `../claude-common-workflow/skills/subagent-dev/SKILL.md` — Step 2
- **[정책서 작성]** `../claude-common-workflow/skills/writing-policy/SKILL.md` — Step 7

### 프로젝트 전용 스킬 (`skills/`)

- **[워크플로우 환경]** `skills/workflow-env/SKILL.md` — 실행 환경, PATH, lint 명령어
- **[Jira 티켓]** `skills/jira-tickets/SKILL.md` — Step 0c, 프로젝트 Jira 설정
<!-- TODO: 프로젝트 전용 스킬 추가 -->

### 레포별 고유 스킬

각 서브프로젝트 `.github/skills/`에 배치. 목록은 각 서브프로젝트 CLAUDE.md 참조.

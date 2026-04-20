# 인덱스 레포 패턴 (Index Repo Pattern)

## 1. 개념

여러 독립 git 레포를 하나의 로컬 폴더 안에 나란히 클론하고, 그 폴더 자체를 공통 규칙·스킬 관리용 git 레포로 운영하는 방식입니다.

- git submodule/monorepo **아님** — 서브 레포는 완전히 독립된 git 레포
- 인덱스 레포는 서브 레포 코드를 추적하지 않음 (`.gitignore`로 제외)
- Claude Code의 **CLAUDE.md 계층 로딩**을 활용: 상위 디렉토리의 CLAUDE.md는 하위 세션에서도 자동 로드됨

---

## 2. 폴더 구조 스키마

```
Desktop/dev/
├── claude-common-workflow/        ← 공통 워크플로우 스킬 레포 (KuruBehind/claude-common-workflow)
│   └── skills/
│       ├── workflow/SKILL.md      step 인덱스, 예외 경로
│       ├── brainstorming/SKILL.md
│       ├── writing-plans/SKILL.md
│       ├── jira-tickets/SKILL.md  (템플릿, 자격증명 없음)
│       ├── subagent-dev/SKILL.md
│       └── writing-policy/SKILL.md
│
└── [project]/                     ← 인덱스 레포 (GitHub 레포, git init)
    ├── .git/
    ├── .gitignore                 ← 서브 레포·워크트리 디렉토리 제외
    ├── .claude/
    │   └── settings.json          ← Claude Code 권한 설정
    ├── CLAUDE.md                  ← 공통 규칙 (자동 로드)
    ├── README.md                  ← 워크스페이스 셋업 가이드
    ├── skills/                    ← 프로젝트 전용 스킬 (오버라이드)
    │   ├── README.md              ← 공통 vs 전용 구분 명시
    │   ├── workflow-env/SKILL.md  ← 실행 환경 (PATH, lint 명령어)
    │   ├── jira-tickets/SKILL.md  ← 실 자격증명 오버라이드
    │   └── [기술스택별]/SKILL.md
    ├── [sub-repo-a]/              ← 서브 레포 A (독립 git, .gitignore로 제외)
    └── [sub-repo-b]/              ← 서브 레포 B (독립 git, .gitignore로 제외)
```

**실 프로젝트 대입 예시**

| 인덱스 레포 | 서브 레포 A | 서브 레포 B |
|-----------|-----------|-----------|
| kuru | kuru_mobile (Flutter) | kuru_backoffice (Flutter Web) |
| yamaharu | yamaharu-web (React+TS) | yamaharu-server (Dart Frog) |

---

## 3. 각 파일 역할 및 작성 기준

### 인덱스 레포

| 파일 | 역할 | 작성 기준 |
|------|------|---------|
| `CLAUDE.md` | 공통 페르소나·크로스 레포 협업 규칙, 스킬 경로 | 최소화 — 구조 다이어그램·기술스택 상세 제외. 서브 레포 세부 규칙은 각 레포 CLAUDE.md에 위임 |
| `skills/README.md` | 공통 vs 전용 스킬 참조 구조 | `../claude-common-workflow/skills/`와 `skills/` 역할 명시 |
| `skills/workflow-env/SKILL.md` | 실행 환경 설정 | 머신별 PATH, 서브프로젝트별 lint 명령어 |
| `skills/jira-tickets/SKILL.md` | Jira 설정 오버라이드 | 실 자격증명, 프로젝트 키, 에픽 목록 |
| `.gitignore` | 서브 레포·워크트리 디렉토리, 임시 파일 | 아래 템플릿 참조 |
| `.claude/settings.json` | Claude Code 권한 설정 | 삭제 계열만 ask, 나머지 allow |
| `README.md` | 레포 구성 및 셋업 절차 | `claude-common-workflow` 링크 포함. 실제 org/레포명 기재 |

### 각 서브 레포

```
[sub-repo]/
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── skills/                  ← 레포 전용 스킬 (도메인·기술스택 특화)
│       └── [도메인별 스킬]/SKILL.md
├── .claude/
│   └── settings.json
├── CLAUDE.md                    ← 레포 전용 규칙
└── docs/
    ├── specs/                   ← 브레인스토밍 산출물
    ├── plans/                   ← 플랜 작성 산출물
    ├── api-spec-[도메인].md     ← API 스펙 (서버↔클라 공유)
    └── policy-[기능명].md       ← 정책서
```

> 공통 스킬(brainstorming, writing-plans 등)은 서브 레포에 두지 않습니다.  
> `../claude-common-workflow/skills/`를 참조합니다.

---

## 4. 파일 템플릿

### `.gitignore` (인덱스 레포)

```gitignore
# 서브 레포 (독립 git 레포 — 인덱스에서 추적하지 않음)
[sub-repo-a]/
[sub-repo-b]/

# 워크트리 디렉토리 (네이밍 규칙: [project]-feat-*, [project]-fix-*)
[project]-feat-*/
[project]-fix-*/
[project]-[sub]-feat-*/
[project]-[sub]-fix-*/

# 프로젝트별 임시/소스 파일
*.jpg
*.jpeg
*.png
*.pdf
```

### `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(**)",
      "Edit(**)",
      "Write(**)",
      "Glob(**)",
      "Grep(**)"
    ],
    "ask": [
      "Bash(rm -rf*)",
      "Bash(rm -r*)",
      "Bash(rm *)",
      "Bash(del *)"
    ]
  }
}
```

### `CLAUDE.md` (인덱스 레포 — 최소 구조)

```markdown
# [Project] — Claude Code Instructions

## 페르소나
- 모든 설명과 코드 내 주석은 한국어(Korean)로 작성하세요.
- 요청받지 않은 전역 설정 파일을 임의로 수정하지 마세요.

## 워크플로우
> 순서 및 step별 절차: `../claude-common-workflow/skills/workflow/SKILL.md` 참조

## 크로스 레포 협업 규칙
| 규칙 | 내용 |
|------|------|
| 배포 순서 | 서버 PR → 먼저 머지 → 클라이언트 PR |
| 같은 피처 사이클 | 연동 변경은 동일 PR 사이클 안에서 처리 |
| API 스펙 우선 | 서버 구현 전 docs/에 스펙 초안 작성 |

## 스킬 카탈로그

### 공통 (`../claude-common-workflow/skills/`)
- `workflow/SKILL.md` — step 인덱스 및 예외 경로
- `brainstorming/SKILL.md` — Step 0a
- `writing-plans/SKILL.md` — Step 0b
- `jira-tickets/SKILL.md` — Step 0c 템플릿
- `subagent-dev/SKILL.md` — Step 2
- `writing-policy/SKILL.md` — Step 7

### 프로젝트 전용 (`skills/`)
- `workflow-env/SKILL.md` — 실행 환경 (PATH, lint 명령어)
- `jira-tickets/SKILL.md` — Step 0c 실행 (실 자격증명)
- [기술스택별 스킬]

### 레포별 고유 스킬
각 서브프로젝트 `.github/skills/` 참조.
```

---

## 5. 신규 프로젝트 적용 절차

```bash
# 0. claude-common-workflow 클론 (최초 1회)
git clone git@github.com:KuruBehind/claude-common-workflow.git ~/Desktop/dev/claude-common-workflow

# 1. 인덱스 폴더 생성 및 파일 작성
mkdir ~/Desktop/dev/[project] && cd ~/Desktop/dev/[project]
# CLAUDE.md, README.md, .gitignore, .claude/settings.json 작성
# skills/workflow-env/SKILL.md, skills/jira-tickets/SKILL.md 작성
# skills/README.md 작성 (공통 vs 전용 구분)

# 2. git 초기화 및 초기 커밋
git init
git add CLAUDE.md README.md .gitignore .claude/ skills/
git branch -M main
git commit -m "chore: [project] 인덱스 레포 초기 셋업"

# 3. GitHub 레포 생성 및 push
gh repo create KuruBehind/[project] --private --description "[설명]"
git remote add origin git@github.com:KuruBehind/[project].git
git push -u origin main

# 4. 서브 레포 클론 (인덱스 폴더 안으로)
git clone git@github.com:KuruBehind/[sub-repo-a].git [sub-repo-a]
git clone git@github.com:KuruBehind/[sub-repo-b].git [sub-repo-b]
```

---

## 6. 크로스 레포 워크플로우 요약

### 단독 작업 (서브 레포 단일 변경)

해당 레포의 `CLAUDE.md` 및 `.github/skills/`를 따릅니다.  
공통 스킬은 `../claude-common-workflow/skills/`에서 자동 참조.

### 동시 작업 (서브 레포 2개 이상 동시 변경)

```
[인덱스 루트에서]
Step 1   워크트리 셋업 (웹·서버 각각)
Step 0a  브레인스토밍 — API 경계 먼저 확정, 스펙 문서 초안
Step 0b  플랜 작성 — 레포별 플랜 분리, EnterPlanMode → 승인
Step 0c  Jira 티켓 생성
Step 2   서버 구현
Step 3   서버 단위 테스트
Step 4   서버 정적 검증
Step 2   웹 구현 (API 스펙 기준)
Step 3   웹 단위 테스트
Step 4   웹 정적 검증
Step 5   웹 통합 테스트
Step 6   서버 PR → 머지 확인 → 웹 PR
Step 7   정책서 작성
Step 8   워크트리 정리
```

**핵심 불변 원칙:**
- 서버 PR은 항상 웹 PR보다 먼저 머지
- PR base 브랜치는 반드시 `dev`
- 워크트리 명령은 인덱스 루트에서 실행
- `git checkout dev` 절대 금지 (워크트리 생성으로 대체)

---

## 7. Claude Code 동작 원리 (참고)

Claude Code는 현재 작업 디렉토리에서 루트 방향으로 CLAUDE.md를 모두 탐색해 로드합니다.

```
yamaharu/CLAUDE.md               ← 자동 로드 (공통 규칙)
yamaharu/yamaharu-web/CLAUDE.md  ← 자동 로드 (레포 전용 규칙)
```

즉, `yamaharu-web/` 세션에서도 상위 `yamaharu/CLAUDE.md`가 항상 적용됩니다.

스킬 파일은 CLAUDE.md에 경로를 명시하면 필요 시 로드됩니다.  
`../claude-common-workflow/skills/`의 스킬도 동일하게 상대경로로 참조 가능합니다.

---

## 8. 적용 프로젝트 현황

| 인덱스 레포 | GitHub | 서브 레포 |
|-----------|--------|---------|
| kuru | [KuruBehind/kuru](https://github.com/KuruBehind/kuru) | kuru_mobile, kuru_backoffice, kuru_landing, kuru_asp_server |
| yamaharu | [KuruBehind/yamaharu](https://github.com/KuruBehind/yamaharu) | yamaharu_client (웹), ai_agent_flow (서버) |

**공통 스킬 레포**

| 레포 | GitHub | 역할 |
|------|--------|------|
| claude-common-workflow | [KuruBehind/claude-common-workflow](https://github.com/KuruBehind/claude-common-workflow) | 모든 인덱스 레포가 공유하는 워크플로우 스킬 원본 |

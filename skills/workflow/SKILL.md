---
name: workflow
description: "개발 워크플로우 — 항상 활성. step 순서, 진입 조건, 예외 경로를 정의합니다."
---

# 개발 워크플로우

## 레포 구조 전제

모든 프로젝트는 인덱스 레포와 서브 레포가 **같은 경로에 나란히** 위치합니다:

```
[workspace]/
├── claude-common-workflow/
├── [index-repo]/
├── [sub-repo-a]/          ← 없으면 git clone 후 진행
└── [sub-repo-a]-feat-[x]/ ← 워크트리
```

서브 레포가 없으면: `git clone git@github.com:{org}/{sub-repo}.git ../{sub-repo}`
레포명 불확실하면 사용자에게 확인.

### 경로 규칙

- **모든 상대경로는 인덱스 레포 루트 기준** (`../sub-repo`, `../sub-repo-feat-x`)
- `git -C <path> worktree add <target>` 에서 `<target>`은 `git -C`와 무관하게 **셸의 현재 CWD 기준**으로 해석됨
- 혼동 방지를 위해 크로스 레포 작업 시 `cd ../sub-repo && git worktree add` 패턴 사용

---

## 실행 순서

```
Step 1  셋업      공통 최신화 + 서버 정리 + 워크트리 생성
Step 2  설계      브레인스토밍 → 스펙 문서 (HARD GATE)
Step 3  플랜      구현 계획 작성
Step 4  Jira      에픽/중복 확인 후 티켓 생성 — ExitPlanMode
Step 5  구현+검증  코드 → 단위테스트 → 정적검증 루프
Step 6  PR+확인   커밋/PR → 개발 서버 실행 → 사용자 결과 확인
Step 7  마무리    Jira 업데이트 → [정책서?] → 서버종료/워크트리 정리 확인
```

**규칙:**
- step 전환 시 번호 명시. 건너뛰기·자의적 생략 금지.
- Step 5 검증 실패 → 코드 수정 후 재검증. 실패 상태에서 Step 6 진입 금지.
- 실행 환경(PATH, lint 명령어)은 `skills/workflow-env/SKILL.md` 참조.

---

## Step 1. 셋업

```bash
# 1. 공통 워크플로우 최신화
git -C ../claude-common-workflow pull

# 2. 잔존 서버 프로세스 확인·종료
lsof -i :{port}                                            # macOS — 포트는 서브 레포 CLAUDE.md 참조
netstat -ano | findstr :{port}                             # Windows
kill -9 {PID} / taskkill /PID {PID} /F

# 3. 워크트리 생성 — 반드시 서브프로젝트 디렉토리 안에서 실행
pwd  # 확인: .../kuru_mart_backoffice 처럼 서브프로젝트 루트여야 함
git pull
git fetch origin dev
git worktree add ../{project}-feat-{feature} -b feat/{feature} origin/dev
cd ../{project}-feat-{feature}
# 의존성 설치: flutter pub get / npm install
```

> `git checkout dev` 절대 금지.

---

## Step 2. 설계 (HARD GATE)

**REQUIRED SKILL:** `brainstorming`

아래 조건을 모두 충족해야 Step 3 진입 가능:
- [ ] 브레인스토밍 스킬 체크리스트 완료
- [ ] 스펙 문서 저장: `[워크트리]/docs/superpowers/specs/YYYY-MM-DD-<주제>.md`
- [ ] 사용자 스펙 승인

"단순한 작업"이라도 생략 불가. 스펙이 짧아질 뿐 프로세스는 동일.

---

## Step 3. 플랜

**REQUIRED SKILL:** `writing-plans`

플랜 저장: `[워크트리]/docs/superpowers/plans/YYYY-MM-DD-<기능명>.md`

---

## Step 4. Jira 티켓

**REQUIRED SKILL:** `jira-tickets`

`tickets.md` 없으면 생략. 있으면:

1. 활성 에픽 목록 조회 → "어느 에픽에 연결할까요?" 사용자 확인
2. 키워드로 중복 티켓 조회 → 결과 보고
3. 사용자 승인 후 생성 (`##` → Task, `###` → Sub-task)

**Step 4 완료 후 ExitPlanMode. 사용자 승인 후 Step 5 진입.**

---

## Step 5. 구현 + 검증

코드 작성 후 아래 순서로 검증. 실패 시 코드 수정 후 재실행.

```bash
# 단위 테스트
flutter test / npm test / dotnet test

# 정적 검증 (error 0개 필수 — Claude가 직접 실행, 사용자에게 떠넘기지 말 것)
flutter analyze / npm run lint / dotnet build
```

서브에이전트 모드: **REQUIRED SKILL:** `subagent-dev`

---

## Step 6. PR + 결과 확인

```bash
git fetch origin dev && git merge origin/dev --no-edit  # 충돌 시 → 예외 C

# PR 중복 확인
gh pr list --head $(git branch --show-current) --state all
```

| 결과 | 조치 |
|------|------|
| 없음 | `gh pr create --base dev` |
| OPEN | 생성 금지, 기존 PR에 푸시만 |
| MERGED / CLOSED | 사용자 확인 후 결정 |

**PR 생성 후 — 클라이언트(UI) 프로젝트는 필수, 서버 전용은 선택:**

개발 서버를 직접 실행해 사용자에게 결과물 제공. 실행 명령어는 서브 레포 `CLAUDE.md` → "개발 서버 실행" 섹션 참조.
사용자가 결과 확인 완료 의사를 밝히면 Step 7로 진입.

---

## Step 7. 마무리

**순서대로 진행:**

**1. Jira 티켓 업데이트** (티켓이 있는 경우)

```bash
source ../claude-common-workflow/.env.local
# 상태 Done 전환 + 구현 내용 코멘트 추가 (PR 링크 포함)
# transition-id는 프로젝트 skills/jira-tickets/SKILL.md 참조
```

**2. 정책서** (사용자에게 확인)

> "정책서 작성이 필요한가요?" — 필요하면 **REQUIRED SKILL:** `writing-policy`

**3. 서버 종료 + 워크트리 정리** (사용자에게 확인)

> "개발 서버를 종료하고 워크트리를 정리할까요?"

```bash
kill -9 {PID} / taskkill /PID {PID} /F
git worktree remove ../{project}-feat-{feature}
```

나중에 하겠다고 하면 그대로 두고 종료.

---

## 예외 경로

| 예외 | 조건 | 처리 |
|------|------|------|
| A. 경량 사이클 | 코드 변경 없는 설정·문서 수정 (사용자 확인 필수) | Step 2·3 생략. 정적 검증은 필수 |
| B. dev 직접 푸시 | 경량 사이클 + 사용자 명시 요청 | 워크트리 없이 직접 커밋 가능 |
| C. 머지 충돌 | `git merge` 충돌 | 충돌 해결 + 재검증 후 Step 6 재진입 |
| D. 세션 재개 | PR URL·브랜치명으로 작업 재개 요청 | 아래 절차 |

**예외 D — 세션 재개:**

환경 변경 가능성이 높으므로 항상 새 워크트리 구성:

```bash
gh pr view {PR_URL}                          # 브랜치명·상태 확인
git worktree list                            # 기존 워크트리 확인
git worktree remove ../{project}-feat-{x}   # 있으면 제거

# 인덱스 루트에서 실행 — 경로 기준: 인덱스 루트
cd ../{sub-repo}
git fetch origin feat/{x}
git worktree add ../{project}-feat-{x} origin/feat/{x}
cd ../{project}-feat-{x} && git pull
# 의존성 재설치

git log --oneline -5 && git diff origin/dev...HEAD --stat  # 상태 보고
```

상태 보고 후 사용자 확인을 받고 이어갈 step 결정.

---
name: workflow
description: "개발 워크플로우 — 항상 활성. 각 step의 진입 조건과 담당 스킬을 인덱싱합니다."
---

# 개발 워크플로우

> step 순서, 회귀 루프, analyze 필수 규칙은 프로젝트 `CLAUDE.md` 참조.

## 실행 환경

> 프로젝트별 실행 환경(PATH, SDK 경로 등)은 워크스페이스의 `skills/workflow-env/SKILL.md` 에 정의합니다.
> 없으면 CLAUDE.md 또는 시스템 PATH 기반으로 실행.

---

## 페이즈 구분

| 페이즈 | 스텝 | 모드 |
|--------|------|------|
| 설계 | Step 0a, 0b, 0c | 플랜 모드 |
| 워크트리 | Step 1 | 일반 |
| 실행 | Step 2~8 | 일반 |

> 진입 순서: 작업 요청 → Step 1 → `EnterPlanMode` → Step 0a~0c → `ExitPlanMode` 승인 → Step 2~

---

## Step 1. 워크트리 셋업

> **대상 서브프로젝트 디렉토리** 안에서 수행 (루트 워크스페이스가 아님).

```bash
git fetch origin dev
git worktree add ../{project}-feat-{feature} -b feat/{feature} origin/dev
cd ../{project}-feat-{feature}
# 프로젝트별 의존성 설치 (예: flutter pub get / npm install)
```

기존 브랜치 재개 시:

```bash
git fetch origin feat/{feature}
git worktree add ../{project}-feat-{feature} origin/feat/{feature}
cd ../{project}-feat-{feature} && git checkout feat/{feature} && git pull
```

> `git checkout dev` 절대 금지

---

## Step 0a. 브레인스토밍

**REQUIRED SKILL:** `brainstorming`

- 파일 탐색만 허용, 코드 작성 금지
- 스펙 저장: `[워크트리]/docs/superpowers/specs/YYYY-MM-DD-<주제>.md`

## Step 0b. 플랜 작성

**REQUIRED SKILL:** `writing-plans`

- 플랜 저장: `[워크트리]/docs/superpowers/plans/YYYY-MM-DD-<기능명>.md`
- 완료 후 실행 모드 선택 → 서브에이전트(권장) 또는 인라인

## Step 0c. Jira 티켓 생성

**REQUIRED SKILL:** `jira-tickets`

- `tickets.md` 가 있는 경우에만 실행
- `##` → Task, `###` → Sub-task, 에픽은 기존 키 사용

---

## Step 2. 코드 작성

- 서브에이전트 모드: **REQUIRED SKILL:** `subagent-dev`
- 인라인 모드: 플랜 태스크 순서대로 직접 실행

## Step 3. 단위 테스트

프로젝트별 단위 테스트 명령어를 실행합니다.

```bash
# Flutter
flutter test
# Node/React
npm test
# C#
dotnet test
```

## Step 4. 정적 검증

> Claude가 직접 실행하여 결과 보고. 명령어를 사용자에게 전달하지 말 것.
> error 0개 필수, 통과 전 커밋 불가.

```bash
# Flutter
flutter analyze
# Node/React
npm run lint
# C#
dotnet build
```

## Step 5. 통합 테스트

**REQUIRED SKILL:** `flutter-testing-apps` (Flutter 프로젝트) 또는 프로젝트 고유 스킬

> Claude가 직접 실행하여 결과 보고.

## Step 6. 커밋 및 PR

```bash
git fetch origin dev && git merge origin/dev --no-edit  # 충돌 시 → 예외 C
# 요약 보고 → 승인 후 커밋/푸시
```

**PR 생성 전 반드시 확인:**

```bash
gh pr list --head $(git branch --show-current) --state all
```

| 결과 | 조치 |
|------|------|
| 출력 없음 | `gh pr create --base dev` 진행 |
| `OPEN` | 이미 PR 존재 — 생성 금지, 기존 PR에 푸시만 |
| `MERGED` | 이미 머지됨 — 브랜치 재사용 여부 사용자에게 확인 후 결정 |
| `CLOSED` | 닫힌 PR — 사용자에게 사유 확인 후 재생성 여부 결정 |

## Step 7. 정책서 작성/갱신

**REQUIRED SKILL:** `writing-policy`

### Step 7-c. 루트 워크스페이스 변경 PR

트리거: `CLAUDE.md` 또는 `skills/` 수정 시

```bash
git add [수정된 파일만 개별 지정]
# 커밋 후 푸시
gh pr create --base main
```

> 워크트리 디렉토리(`*-feat-*`)는 절대 스테이징 금지.

## Step 8. 워크트리 정리 (사용자 요청 시에만)

```bash
# CWD를 원본 저장소로 복귀 후
git worktree remove ../{project}-feat-{feature}
```

---

## 예외 경로

| 예외 | 조건 | 생략 가능 step |
|------|------|--------------|
| A. 경량 사이클 | 설정/문서 변경 (사용자 확인 필수) | 0, 3, 5 생략. 4는 필수 |
| B. dev 직접 푸시 | 설정/문서 + 사용자 명시 요청 + 정적 검증 통과 | — |
| C. 머지 충돌 | `git merge` 충돌 발생 | 빌드 재검증 후 step 6 재진입 |
| D. 세션 재개 | 세션 중단 후 복귀 | `git worktree list && git status && git log --oneline -5` 진단 후 보고 |

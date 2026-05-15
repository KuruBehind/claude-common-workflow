---
name: workflow
description: "개발 워크플로우 — 항상 활성. 각 step의 진입 조건과 담당 스킬을 인덱싱합니다."
---

# 개발 워크플로우

## 실행 순서

```
Step 1  워크트리 셋업
Step 2  브레인스토밍       ← EnterPlanMode
Step 3  플랜 작성
Step 4  Jira 티켓 생성     ← ExitPlanMode 승인 후
Step 5  코드 작성
Step 6  단위 테스트
Step 7  정적 검증
Step 8  통합 테스트
Step 9  커밋/PR
Step 10 정책서 작성 + Jira 티켓 업데이트
Step 11 워크트리 정리
```

- YOU MUST follow the step sequence strictly. 건너뛰기·순서 변경·자의적 생략 금지.
- step 전환 시 번호를 명시할 것.
- step 8 실패 시 → step 5로 돌아가 5→6→7→8 반복. **실패 상태에서 step 9 진입 금지.**

---

## 실행 환경

프로젝트별 실행 환경(PATH, SDK 경로 등)은 워크스페이스의 `skills/workflow-env/SKILL.md` 에 정의합니다.
없으면 CLAUDE.md 또는 시스템 PATH 기반으로 실행.

---

## 커뮤니케이션 원칙 (MANDATORY)

1. **막힘 발생 시 → 근본 원인부터 해결.** 권한 오류·환경 문제·설정 누락 등 모든 장애는 Claude가 직접 해소한다. 사용자에게 넘기지 않는다.
2. **사용자에게 넘길 수밖에 없는 상황이 확실히 결론 났을 때만** 요청한다. 이 경우 명령어·경로·이유를 꼼꼼히 작성해 사용자가 최소한의 행동으로 해결할 수 있도록 가이드한다.
3. **지시 받은 금지 사항은 이후 어떤 상황에서도 재시도 금지.** "이번만", "다른 방법으로"도 동일하게 금지.
4. **완료 선언 전 목적 달성 여부를 직접 검증한다.** 행위(파일 수정, 명령 실행)가 아닌 결과(동작, 적용, 충족)를 기준으로 완료를 판단한다. 검증 불가 시 불확실 상태임을 명시하고 사용자에게 떠넘기지 않는다.

---

## 레포 구조 (MANDATORY — 항상 이 구조를 전제)

모든 프로젝트는 **인덱스 레포와 서브 레포가 같은 경로에 나란히** 위치합니다:

```
[workspace]/
├── claude-common-workflow/   ← 공통 워크플로우 스킬 레포
├── [index-repo]/             ← 인덱스 레포 (CLAUDE.md, skills/ 포함)
├── [sub-repo-a]/             ← 서브 레포 A (독립 git)
├── [sub-repo-b]/             ← 서브 레포 B (독립 git)
└── [sub-repo-a]-feat-[x]/   ← 워크트리 (작업 중 생성)
```

**서브 레포가 로컬에 없는 경우 — 클론 후 진행**

사용자가 요청한 레포가 로컬에 없으면 작업 전에 클론합니다:

```bash
# 인덱스 레포 위치에서
ls ../  # 서브 레포 존재 여부 확인
git clone git@github.com:{org}/{sub-repo}.git ../{sub-repo}
```

> 클론 대상 org/레포명은 인덱스 레포 CLAUDE.md의 서브프로젝트 목록을 참조.
> 확인이 안 되면 사용자에게 GitHub 레포명을 물어볼 것.

---

## Step 1. 워크트리 셋업

**워크플로우 시작 전 — 인덱스 레포 최신화 (MANDATORY)**

```bash
git -C ../claude-common-workflow pull
```

**기존 개발 서버 프로세스 정리 (MANDATORY)**

새 작업 시작 전 이전 작업에서 남은 서버 프로세스를 확인하고 종료합니다:

```bash
# 프로젝트별 포트 점유 확인
lsof -i :{port}        # macOS/Linux
netstat -ano | findstr :{port}  # Windows

# 프로세스 종료
kill -9 {PID}          # macOS/Linux
taskkill /PID {PID} /F # Windows
```

> 실행 중인 서버가 있으면 종료 후 워크트리를 생성합니다.
> 프로젝트별 포트는 `skills/workflow-env/SKILL.md` 참조.

**워크트리 생성 위치 확인 (MANDATORY)**

워크트리는 **반드시 대상 서브프로젝트 디렉토리 안에서** 생성합니다:

```bash
pwd  # 반드시 서브프로젝트 루트여야 함 (예: .../kuru_mart_backoffice)
     # 인덱스 루트나 상위 디렉토리에서 실행하면 워크트리 위치가 잘못됨
```

```bash
git pull
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

## Step 2. 브레인스토밍

**REQUIRED SKILL:** `brainstorming`

**HARD GATE: Step 2 완료 조건을 충족하지 않으면 Step 3 진입 금지.**

Step 2 완료 조건:
- [ ] 브레인스토밍 스킬 체크리스트 전체 완료
- [ ] 스펙 문서가 `[워크트리]/docs/superpowers/specs/YYYY-MM-DD-<주제>.md` 에 저장됨
- [ ] 사용자가 스펙 문서를 검토하고 승인함

> 파일 탐색만 허용, 코드 작성 금지.
> "이 작업은 단순하다"는 이유로 브레인스토밍을 생략하는 것은 금지. 단순한 작업일수록 스펙이 짧아질 뿐, 프로세스는 동일하게 적용.

## Step 3. 플랜 작성

**REQUIRED SKILL:** `writing-plans`

- 플랜 저장: `[워크트리]/docs/superpowers/plans/YYYY-MM-DD-<기능명>.md`
- 완료 후 실행 모드 선택 → 서브에이전트(권장) 또는 인라인

## Step 4. Jira 티켓 생성

**REQUIRED SKILL:** `jira-tickets`

- `tickets.md` 가 없으면 이 step 전체 생략.

**HARD GATE: 티켓 생성 전 반드시 사용자 확인.**

생성 전 아래 두 가지를 사용자에게 보고하고 승인받습니다:

1. **에픽 확인** — 활성 에픽 목록을 조회해 "이 작업을 어느 에픽에 연결할까요?" 질문
2. **중복 티켓 확인** — 동일하거나 유사한 티켓이 이미 존재하는지 조회 후 결과 보고

```bash
source ../claude-common-workflow/.env.local

# 유사 티켓 검색 (작업 키워드로 조회)
curl -s -u "$JIRA_AUTH" -H "Accept: application/json" \
  "$JIRA_BASE/search/jql" \
  -X POST -H "Content-Type: application/json" \
  -d '{"jql":"project=<PROJECT> AND summary ~ \"<키워드>\" ORDER BY created DESC","fields":["summary","status","assignee"],"maxResults":5}'
```

사용자가 에픽을 지정하고 중복 없음을 확인한 후에만 티켓 생성 진행.

- `##` → Task, `###` → Sub-task

> Step 4 완료 후 ExitPlanMode 승인을 받고 Step 5 진입.

---

## Step 5. 코드 작성

- 서브에이전트 모드: **REQUIRED SKILL:** `subagent-dev`
- 인라인 모드: 플랜 태스크 순서대로 직접 실행

## Step 6. 단위 테스트

프로젝트별 단위 테스트 명령어를 실행합니다.

```bash
# Flutter
flutter test
# Node/React
npm test
# C#
dotnet test
```

## Step 7. 정적 검증

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

## Step 8. 통합 테스트

**REQUIRED SKILL:** `flutter-testing-apps` (Flutter 프로젝트) 또는 프로젝트 고유 스킬

> Claude가 직접 실행하여 결과 보고.

## Step 9. 커밋 및 PR

```bash
git fetch origin dev && git merge origin/dev --no-edit  # 충돌 시 → 예외 C
# 요약 보고 → 승인 후 커밋/푸시
```

**PR base 브랜치는 반드시 `dev`.**

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

## Step 9.5. 개발 서버 실행 + 결과 확인

**클라이언트(UI) 프로젝트는 필수. 서버 전용 작업은 선택.**
**Step 10 진입 전 완료. 사용자에게 직접 셋업을 요구하지 말 것.**

PR 완료 후 개발 서버를 직접 실행해 사용자가 결과물을 확인할 수 있도록 제공합니다:

1. 실행 명령어는 해당 **서브 레포의 `CLAUDE.md` → "개발 서버 실행" 섹션** 참조 — 명령어를 사용자에게 전달하는 것으로 끝내지 말 것
2. Claude가 직접 실행 후 접속 URL 제공
3. 구현한 기능의 동작을 직접 확인하고 결과 보고
4. 사용자가 확인 완료 의사를 밝히면 Step 10으로 진입

> 이 단계에서 띄운 서버는 Step 11(워크트리 정리) 전에 반드시 종료합니다.

## Step 10. 정책서 작성 + Jira 티켓 업데이트

**REQUIRED SKILL:** `writing-policy`

**Step 10 없이 Step 11 진입 금지.**

### 정책서

기획 정책서(7-a)와 개발 독스(7-b)를 작성하거나 갱신합니다. 자세한 작성 기준은 `writing-policy` 스킬 참조.

### Jira 티켓 업데이트

PR 머지 후 연결된 Jira 티켓을 업데이트합니다:

```bash
source ../claude-common-workflow/.env.local

# 티켓 상태를 Done으로 전환
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  "$JIRA_BASE/issue/{TICKET_KEY}/transitions" \
  -d '{"transition": {"id": "<done-transition-id>"}}'

# 구현 내용 코멘트 추가 (변경사항 요약 + PR 링크)
cat > /tmp/comment.json << 'EOF'
{
  "body": {
    "type": "doc", "version": 1,
    "content": [{"type": "paragraph", "content": [{"type": "text", "text": "구현 완료. PR: <PR URL>\n변경 내용: <요약>"}]}]
  }
}
EOF
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Accept: application/json" -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue/{TICKET_KEY}/comment" --data-binary @/tmp/comment.json
```

> transition-id는 프로젝트별로 다릅니다. 프로젝트 오버라이드 파일(`skills/jira-tickets/SKILL.md`)에 명시된 값을 사용하세요.

### Step 10-c. 루트 워크스페이스 변경 PR

트리거: `CLAUDE.md` 또는 `skills/` 수정 시

```bash
git add [수정된 파일만 개별 지정]
# 커밋 후 푸시
gh pr create --base main
```

> 워크트리 디렉토리(`*-feat-*`)는 절대 스테이징 금지.

## Step 11. 워크트리 정리 (사용자 요청 시에만)

```bash
# 1. 실행 중인 개발 서버 종료
lsof -i :{port} | awk 'NR>1 {print $2}' | xargs kill -9  # macOS/Linux
taskkill /PID {PID} /F                                     # Windows

# 2. CWD를 원본 저장소로 복귀 후 워크트리 제거
git worktree remove ../{project}-feat-{feature}
```

---

## 예외 경로 D 상세 — 세션 재개

작업 환경이 변경됐을 가능성이 높으므로, 기존 워크트리 유무와 관계없이 **항상 새 워크트리를 구성**합니다.

```bash
# 1. PR 정보 파악
gh pr view {PR_URL}  # 브랜치명·상태·최근 커밋 확인

# 2. 기존 워크트리 정리 (있는 경우)
git worktree list
git worktree remove ../{project}-feat-{feature}  # 있으면 제거

# 3. 새 워크트리 구성
git -C ../{sub-repo} fetch origin feat/{feature}
git -C ../{sub-repo} worktree add ../{project}-feat-{feature} origin/feat/{feature}
cd ../{project}-feat-{feature} && git checkout feat/{feature} && git pull

# 4. 의존성 재설치
# flutter pub get / npm install 등

# 5. 현재 상태 보고
git log --oneline -5
git status
git diff origin/dev...HEAD --stat
```

상태 보고 후 사용자 확인을 받고 이어서 진행할 step을 결정합니다.

---

## 예외 경로

| 예외 | 조건 | 생략 가능 step |
|------|------|--------------|
| A. 경량 사이클 | 설정·문서만 변경 (코드 변경 없음, 사용자 명시 확인 필수) | 2, 3, 6, 8 생략 가능. 7은 필수 |
| B. dev 직접 푸시 | 경량 사이클 + 사용자 명시 요청 + 정적 검증(7) 통과 | 워크트리 없이 직접 커밋 가능 |
| C. 머지 충돌 | `git merge` 충돌 발생 | 빌드 재검증 후 step 9 재진입 |
| D. 세션 재개 | PR URL 또는 브랜치명으로 작업 재개 요청 | 아래 절차 참조 |

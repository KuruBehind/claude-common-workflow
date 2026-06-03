---
name: jira-tickets
description: "Jira 티켓 생성 절차 — tickets.md를 Jira Task/Sub-task로 변환. 자격증명(.env.local), 프로젝트 매핑, curl 생성 방법 포함."
---

# Jira 티켓 생성

## 티켓 작업 의도별 동사

| 의도 | 동작 | 주요 사용 시점 |
|------|------|--------------|
| `get` | 티켓 정보 조회, context.md 생성 | Step 0, 세션 재개 |
| `work` | 티켓 상태 In Progress 전환, 작업 시작 코멘트 | Step 1 셋업 완료 후 |
| `qa` | 구현 내용 코멘트, PR 연결 | Step 6 PR 생성 후 |
| `act` | 티켓 상태 Done 전환, 종결 코멘트 | Step 8 종결 |

---

## 티켓 품질 리뷰 (Step 0 — 게이트)

티켓 URL 또는 키를 받으면 아래 체크리스트를 실행. 미흡 항목은 Jira 코멘트 + 작성자 멘션으로 보완 요청.

### 공통 체크리스트
- [ ] 목적/배경 — 왜 이 작업이 필요한지 명시되어 있는가
- [ ] 완료 기준 (AC) — 언제 Done으로 볼 수 있는지 명시되어 있는가
- [ ] 기술 범위 — FE / BE / 인프라 중 어느 레이어를 건드리는지 명시되어 있는가

> 프로젝트별 추가 항목은 각 워크스페이스 `skills/jira-tickets/SKILL.md`에서 오버라이드.

### 미흡 시 처리 — 판단 기준

| 상황 | 처리 |
|------|------|
| 티켓 내용으로 **명확히 추론 가능**한 경우 | 에이전트가 직접 보완 → 사용자 검토 요청 |
| **비즈니스 판단**이 필요한 경우 (범위·우선순위 결정 등) | 작성자 멘션 + 코멘트로 보완 요청 |

**직접 보완 시 — description 업데이트:**

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"
export JIRA_AUTH="$JIRA_EMAIL:$JIRA_API_TOKEN"
export JIRA_BASE="$JIRA_URL/rest/api/3"

cat > /tmp/description.json << 'EOF'
{
  "fields": {
    "description": {
      "type": "doc", "version": 1,
      "content": [
        {"type": "paragraph", "content": [{"type": "text", "text": "<보완된 내용>"}]}
      ]
    }
  }
}
EOF
curl -s -u "$JIRA_AUTH" -X PUT \
  -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue/<TICKET-KEY>" --data-binary @/tmp/description.json
```

보완 후 사용자에게 검토 요청: "description에 AC를 추가했습니다. 확인 후 진행할까요?"

**작성자 멘션 코멘트 시:**

```bash
cat > /tmp/review-comment.json << 'EOF'
{
  "body": {
    "type": "doc", "version": 1,
    "content": [{
      "type": "paragraph",
      "content": [
        {"type": "mention", "attrs": {"id": "<작성자-accountId>"}},
        {"type": "text", "text": " 아래 항목 보완 부탁드립니다:\n- <미흡 항목 목록>"}
      ]
    }]
  }
}
EOF
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue/<TICKET-KEY>/comment" --data-binary @/tmp/review-comment.json
```

---

## 사전 확인

### 1. 자격증명 확인

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"
export JIRA_AUTH="$JIRA_EMAIL:$JIRA_API_TOKEN"
export JIRA_BASE="$JIRA_URL/rest/api/3"
```

> `.env.local`은 `JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`을 정의함.
> `JIRA_AUTH`, `JIRA_BASE`는 위 두 줄로 직접 조합해야 사용 가능.

없으면 `.env.example`을 복사해 생성:

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
cp "$REPO_ROOT/../claude-common-workflow/.env.example" "$REPO_ROOT/../claude-common-workflow/.env.local"
# .env.local을 열어 실제 값으로 채울 것
```

### 2. 에픽 확인 (사용자 승인 필수)

활성 에픽 목록을 조회해 사용자에게 보여주고, **어느 에픽에 연결할지 확인받습니다.**

> 에픽 목록은 프로젝트 오버라이드 파일(`skills/jira-tickets/SKILL.md`)을 우선 참조.
> 최신 목록이 필요하면 아래 명령어로 조회.

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"
PROJECT="<PROJECT_KEY>"
EPIC_TYPE_ID="<epic-issuetype-id>"

curl -s -u "$JIRA_AUTH" -H "Accept: application/json" \
  "$JIRA_BASE/search/jql" \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jql\":\"project=$PROJECT AND issuetype=$EPIC_TYPE_ID ORDER BY created DESC\",\"fields\":[\"summary\"],\"maxResults\":20}"
```

### 3. 중복 티켓 확인 (사용자 승인 필수)

작업 키워드로 기존 티켓을 조회해 결과를 사용자에게 보고합니다.
유사 티켓이 있으면 새로 만들지 재사용할지 사용자에게 확인받습니다.

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"

curl -s -u "$JIRA_AUTH" -H "Accept: application/json" \
  "$JIRA_BASE/search/jql" \
  -X POST -H "Content-Type: application/json" \
  -d '{"jql":"project=<PROJECT> AND summary ~ \"<키워드>\" AND statusCategory != Done ORDER BY created DESC","fields":["summary","status","assignee"],"maxResults":5}'
```

위 두 확인을 마치고 사용자가 에픽과 생성 여부를 승인한 후에만 아래 생성 단계로 진행합니다.

---

## 티켓 계층 구조

| tickets.md 단위 | Jira 타입 | 비고 |
|----------------|---------|------|
| `## [섹션명]` | **작업(Task)** | 에픽 하위 |
| `### KURU-XXX-NNN` | **하위 작업(Sub-task)** | Task 하위 |

## 우선순위 매핑

| tickets.md | Jira |
|-----------|------|
| P0 | `Highest` |
| P1 | `Medium` |
| P2 | `Low` |
| 미표기 | `Highest` |

---

## 네이밍 컨벤션

### 에픽
기능/목표 중심 명사구, 짧고 명확하게.
> `가맹화`, `서버 레이어 마이그레이션`, `디자인 시스템 구축 & UI 개선`

### 작업(Task)
`[태그] 기능 내용` 형식. 태그는 선택.

| 태그 | 용도 |
|------|------|
| `[BUG]` | 버그 수정 |
| `[개선]` | 기존 기능 개선 |
| `[체크]` | 검토/확인 항목 |

> `[BUG] 로그인 불안정 — 됐다 안 됐다 반복`  
> `Firebase RTDB 보안 규칙 변경`

### 하위 작업(Sub-task)
`[태그] 구체적 작업 내용` 형식. 태그로 담당 레이어 구분.

| 태그 | 용도 |
|------|------|
| `[FE]` | 프론트엔드 |
| `[BE]` | 백엔드 서버 |
| `[INF]` | 인프라 (Firebase Rules, GCP, CI/CD 등) |
| `[BUG]` | 버그 수정 |
| `[QA]` | 테스트/검증 |

> `[FE] 원가 표시 경로 변경`  
> `[BE] POST /Shop/GetItemsHQ 신규 엔드포인트`  
> `[INF] Firebase Security Rules HQ 권한 추가`

**주의:** summary에 P레벨(`— P0`) 표기 금지. 우선순위는 Jira priority 필드로 관리.

---

## 생성 방법

> **한국어 포함 시 반드시 파일로 작성 후 `--data-binary @file` 사용.**  
> curl `-d` 인라인은 UTF-8 파싱 오류 발생.

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"
PROJECT_KEY="<KEY>"
TASK_TYPE_ID="<task-issuetype-id>"
SUBTASK_TYPE_ID="<subtask-issuetype-id>"
EPIC_KEY="<KEY-N>"

# 0. 담당자 accountId 조회
curl -s -u "$JIRA_AUTH" "$JIRA_BASE/myself" | grep -o '"accountId":"[^"]*"'
# → "accountId":"xxxxx"

# 1. Task 생성 (## 섹션) → 반환된 key를 Sub-task parent로 사용
cat > /tmp/issue.json << 'EOF'
{
  "fields": {
    "project": {"key": "PROJECT_KEY"},
    "summary": "[섹션명]",
    "issuetype": {"id": "TASK_TYPE_ID"},
    "parent": {"key": "EPIC_KEY"},
    "priority": {"name": "Highest"},
    "assignee": {"accountId": "<accountId>"},
    "description": {
      "type": "doc", "version": 1,
      "content": [{"type": "paragraph", "content": [{"type": "text", "text": "← 아래 Description 작성 가이드에서 타입 선택 후 해당 템플릿 적용"}]}]
    }
  }
}
EOF
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Accept: application/json" -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue" --data-binary @/tmp/issue.json
# → {"key":"KEY-XX"}

# 2. Sub-task 생성 (### 항목)
cat > /tmp/issue.json << 'EOF'
{
  "fields": {
    "project": {"key": "PROJECT_KEY"},
    "summary": "[FE] 항목 제목",
    "issuetype": {"id": "SUBTASK_TYPE_ID"},
    "parent": {"key": "KEY-XX"},
    "priority": {"name": "Highest"},
    "assignee": {"accountId": "<accountId>"}
  }
}
EOF
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Accept: application/json" -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue" --data-binary @/tmp/issue.json

# 3. PR 연결 (Task에 GitHub PR 원격 링크 추가)
curl -s -u "$JIRA_AUTH" -X POST \
  -H "Accept: application/json" -H "Content-Type: application/json; charset=utf-8" \
  "$JIRA_BASE/issue/KEY-XX/remotelink" \
  -d "{\"object\":{\"url\":\"https://github.com/<org>/<repo>/pull/<pr_number>\",\"title\":\"PR #<pr_number>: <PR 제목>\",\"icon\":{\"url16x16\":\"https://github.com/favicon.ico\",\"title\":\"GitHub\"}}}"
```

---

## Description 작성 가이드

티켓 타입에 따라 아래 템플릿 중 하나를 선택. 섹션 순서는 유지하되, 해당 없는 항목은 생략 가능.

### 타입 A — 기능 개발 / 개선

```
목적
왜 이 기능이 필요한가. 사용자 관점에서 한두 문장으로.
예) 유저가 키워드를 입력해 상품을 검색할 때 Shop/GetItems 결과를 검색 페이지에 표시한다.

상세
- [ ] 작업 항목 1 (레이어/담당 명시)
- [ ] 작업 항목 2
- [ ] 작업 항목 3

참고
- 컨플루언스: <링크>
- API 문서: <링크>
- 디자인(Figma): <링크>
- PR: <링크>
```

### 타입 B — 앱/UI 버그 리포트

```
테스트 정보
버전 :
플랫폼 : (iOS / Android / Web)

케이스
[사진 및 영상]

case1 인 상황에서 발생
case2 인 상황에서는 정상 동작함

참고
- 관련 티켓: <KEY-XX>
- PR: <링크>
```

### 타입 C — 인프라 / 운영 이슈

```
현상
언제, 어떤 증상이 발생하는가. 알림 내용, 빈도, 영향 범위 포함.
예) 매일 새벽 1시 Cloud Scheduler 실패 알림 2건 수신. 운영 체감 이슈는 없었으나 Scheduler 기준 매일 실패 상태.

원인 분석
로그/코드 분석으로 확인한 근본 원인 체인. 타임라인 형식 권장.
- [HH:MM] 이벤트 A 발생
- [HH:MM] 이벤트 B → 이벤트 A의 결과
- 결론: 핵심 원인 한 줄 요약

조치 내용
변경한 내용과 이유. 명령어·코드·설정값은 코드블록으로.
1. 항목명 — 변경 전 → 변경 후
   이유: 왜 이 값으로 변경했는가.
   ```
   실행 명령어 또는 코드
   ```

검증 방법
언제, 어떻게 정상 여부를 확인할지.
- 확인 시점: 예) 익일 새벽 1시 이후
- 확인 방법: 예) GCP Scheduler 콘솔에서 SUCCESS 상태 확인

잔여 검토 항목 (선택)
이번 범위 밖이지만 후속 대응이 필요한 항목.
- 항목 A — 담당/일정 미정
- 항목 B — 별도 티켓 권장

참고
- PR: <링크>
- 관련 로그 쿼리: <링크>
- 관련 티켓: <KEY-XX>
```

### 공통 규칙

- **참고 섹션은 항상 마지막.** PR, 문서, 관련 티켓 링크를 모은다.
- **PR이 생성된 경우** description 참고 섹션에 링크 추가 + Jira 원격 링크(`remotelink`) API로도 연결:
  ```bash
  curl -s -u "$JIRA_AUTH" -X POST \
    -H "Content-Type: application/json" \
    "$JIRA_BASE/issue/<KEY>/remotelink" \
    -d "{\"object\":{\"url\":\"<PR_URL>\",\"title\":\"PR #<N>: <제목>\",\"icon\":{\"url16x16\":\"https://github.com/favicon.ico\",\"title\":\"GitHub\"}}}"
  ```
- **첨부 문서(Confluence 등)가 있는 경우** 참고 섹션에 URL 추가.
- 섹션 제목은 한국어로 통일. 코드블록·명령어는 영어 그대로.

---

## context.md 생성 (Step 1 워크트리 생성 직후)

워크트리 루트에 `context.md` 생성. 수동 편집 금지. 세션 재개 시 재생성.

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | xargs dirname)
source "$REPO_ROOT/../claude-common-workflow/.env.local"
export JIRA_AUTH="$JIRA_EMAIL:$JIRA_API_TOKEN"
export JIRA_BASE="$JIRA_URL/rest/api/3"

TICKET_KEY="<TICKET-KEY>"
SUMMARY=$(curl -s -u "$JIRA_AUTH" "$JIRA_BASE/issue/$TICKET_KEY?fields=summary,issuetype,priority,parent" \
  | grep -o '"summary":"[^"]*"' | head -1 | cut -d'"' -f4)
ISSUE_TYPE=$(curl -s -u "$JIRA_AUTH" "$JIRA_BASE/issue/$TICKET_KEY?fields=issuetype" \
  | grep -o '"issuetype":{[^}]*}' | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
PRIORITY=$(curl -s -u "$JIRA_AUTH" "$JIRA_BASE/issue/$TICKET_KEY?fields=priority" \
  | grep -o '"priority":{[^}]*}' | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
EPIC=$(curl -s -u "$JIRA_AUTH" "$JIRA_BASE/issue/$TICKET_KEY?fields=parent" \
  | grep -o '"parent":{[^}]*}' | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

cat > context.md << EOF
# $TICKET_KEY $SUMMARY

## 티켓 정보
- 타입: $ISSUE_TYPE
- 우선순위: $PRIORITY
- 에픽: $EPIC

## 확정 결정
<!-- 브레인스토밍·설계 중 확정된 결정을 여기에 기록. 변경 시 이유 한 줄 포함. -->

## 연결된 PR
<!-- PR 생성 후 여기에 추가 -->
EOF
```

---

## 완료 기준

- [ ] `.env.local` 존재 확인 — `REPO_ROOT` 패턴으로 로드 (경로 규칙은 `docs/conventions/repo-root-path.md` 참조)
- [ ] 대상 에픽 키 확인
- [ ] `## 섹션` 수만큼 Task 생성 + 에픽 하위 연결
- [ ] `### 항목` 수만큼 Sub-task 생성 + Task 하위 연결
- [ ] 우선순위 매핑 확인
- [ ] 담당자(assignee) 지정 — `GET /myself`로 accountId 조회 후 설정
- [ ] Task에 description 작성 — 타입 A(기능)/B(버그)/C(인프라) 중 해당 템플릿 적용
- [ ] PR 또는 문서가 있는 경우 description 참고 섹션 + remotelink API 두 곳 모두 연결

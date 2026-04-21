---
name: jira-tickets
description: "Jira 티켓 생성 절차 — tickets.md를 Jira Task/Sub-task로 변환. 자격증명(.env.local), 프로젝트 매핑, curl 생성 방법 포함."
---

# Jira 티켓 생성

## 사전 확인

### 자격증명 확인

```bash
source ../claude-common-workflow/.env.local
# JIRA_AUTH, JIRA_BASE 환경변수가 설정됨
```

없으면 `.env.example`을 복사해 생성:

```bash
cp ../claude-common-workflow/.env.example ../claude-common-workflow/.env.local
# .env.local을 열어 실제 값으로 채울 것
```

### 활성 에픽 목록

| 프로젝트 | 에픽 키 | 제목 |
|---------|--------|------|
| <!-- KEY --> | <!-- KEY-N --> | <!-- 에픽 제목 --> |

에픽 목록 최신화:

```bash
source .env.local
PROJECT="<PROJECT_KEY>"
EPIC_TYPE_ID="<epic-issuetype-id>"

curl -s -u "$JIRA_AUTH" -H "Accept: application/json" \
  "$JIRA_BASE/search/jql" \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jql\":\"project=$PROJECT AND issuetype=$EPIC_TYPE_ID ORDER BY created DESC\",\"fields\":[\"summary\"],\"maxResults\":20}"
```

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
source ../claude-common-workflow/.env.local
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
      "content": [{"type": "paragraph", "content": [{"type": "text", "text": "작업 배경 및 내용 요약"}]}]
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

## 완료 기준

- [ ] `.env.local` 존재 확인 (`source ../claude-common-workflow/.env.local`)
- [ ] 대상 에픽 키 확인
- [ ] `## 섹션` 수만큼 Task 생성 + 에픽 하위 연결
- [ ] `### 항목` 수만큼 Sub-task 생성 + Task 하위 연결
- [ ] 우선순위 매핑 확인
- [ ] 담당자(assignee) 지정 — `GET /myself`로 accountId 조회 후 설정
- [ ] Task에 작업 배경/내용 description 작성 (ADF 형식)
- [ ] Task에 PR 원격 링크 연결 — 여러 Sub-task가 하나의 PR인 경우 상위 Task에만 연결

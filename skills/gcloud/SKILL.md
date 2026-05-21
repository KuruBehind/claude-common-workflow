---
name: gcloud
description: "GCP CLI(gcloud) 사용 가이드 — 로그 조회, Cloud Functions, Cloud Scheduler 설정 변경. 프로젝트별 PATH·프로젝트ID는 각 프로젝트 workflow-env 스킬 참조."
---

# gcloud CLI

## GCP 로그 분석 요청 시 진입 절차

사용자가 "GCP 로그 확인해줘", "에러 원인 분석해줘" 등을 요청할 때 아래 순서로 진행:

1. **PATH 설정** — 프로젝트 전용 `workflow-env` 스킬의 gcloud PATH export 실행
2. **인증 확인** — `gcloud auth list`로 활성 계정 확인. 로그인 안 된 경우 사용자에게 안내
3. **프로젝트 설정** — `gcloud config set project <PROJECT_ID>`
4. **로그 조회** — 아래 로그 조회 섹션 참고. 시간대는 UTC 기준으로 변환해서 조회
5. **분석 보고** — 현상 → 원인 체인 → 조치 방향 순으로 보고

> 로그를 직접 조회할 수 있는 경우 사용자가 붙여넣은 로그에만 의존하지 말고 직접 확인할 것.

---

## 인증 및 프로젝트 설정

```bash
gcloud auth list                          # 현재 인증 계정 확인
gcloud config set project <PROJECT_ID>    # 프로젝트 설정
gcloud config get-value project           # 현재 프로젝트 확인
```

---

## Cloud Functions

```bash
# 함수 목록
gcloud functions list --project=<PROJECT_ID> --format="table(name,status,region)"

# 함수 설정 확인 (메모리·타임아웃·소스 경로·서비스 계정 등)
gcloud functions describe <FUNCTION_NAME> --region=<REGION> --project=<PROJECT_ID> --format=json
```

### Gen2 함수 설정 변경 (코드 없이 인프라만)

소스 코드 없이 메모리·타임아웃 등 설정만 변경할 때:

```bash
# 1) 현재 소스 경로 확인: describe 결과의 buildConfig.source.storageSource
gcloud functions describe <FUNCTION_NAME> --region=<REGION> --project=<PROJECT_ID> \
  --format="value(buildConfig.source.storageSource.bucket, buildConfig.source.storageSource.object)"

# 2) 기존 소스 그대로 재배포 (메모리·CPU만 변경)
gcloud functions deploy <FUNCTION_NAME> \
  --memory=512MB --cpu=1 \
  --region=<REGION> --gen2 --runtime=<RUNTIME> \
  --source=gs://<BUCKET>/<OBJECT_PATH> \
  --entry-point=<FUNCTION_NAME> --trigger-http --allow-unauthenticated \
  --project=<PROJECT_ID>
```

> Gen2 함수는 Cloud Run 기반. concurrency > 1이면 CPU < 1 불가 → `--cpu=1` 필수.

---

## Cloud Scheduler

```bash
# job 목록
gcloud scheduler jobs list --location=<LOCATION> --project=<PROJECT_ID>

# job 설정 확인
gcloud scheduler jobs describe <JOB_NAME> --location=<LOCATION> --project=<PROJECT_ID>

# attemptDeadline 변경 (함수 실행 시간보다 길게 설정)
gcloud scheduler jobs update http <JOB_NAME> \
  --location=<LOCATION> \
  --attempt-deadline=<SECONDS>s \
  --project=<PROJECT_ID>
```

> `attemptDeadline` 기본값 180s. 함수 실행 시간이 이보다 길면 DEADLINE_EXCEEDED로 실패 처리됨.

---

## 로그 조회

### Gen1 vs Gen2 리소스 타입 (중요)

| 함수 세대 | 로그 리소스 타입 | 비고 |
|----------|----------------|------|
| Gen1 | `cloud_function` | |
| Gen2 | `cloud_run_revision` | service_name = 함수명 소문자·하이픈 |

> Gen2 함수에 `cloud_function`으로 조회하면 실행 로그(stdout)가 나오지 않음. 반드시 `cloud_run_revision` 사용.

```bash
# Gen1 함수 로그
gcloud logging read \
  'resource.type="cloud_function" AND resource.labels.function_name="<FUNCTION_NAME>" AND severity=ERROR AND timestamp>="<ISO_TIME>"' \
  --project=<PROJECT_ID> --limit=100 --format=json

# Gen2 함수 로그 (stdout 포함)
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="<function-name-lowercase>" AND timestamp>="<ISO_TIME>"' \
  --project=<PROJECT_ID> --limit=100 --format=json

# Cloud Scheduler 실행 결과
gcloud logging read \
  'resource.type="cloud_scheduler_job" AND severity=ERROR AND timestamp>="<ISO_TIME>"' \
  --project=<PROJECT_ID> --limit=20 --format=json
```

### 로그 파싱

python/python3가 없는 환경에서는 `--format=json` 대신 테이블 형식 사용:

```bash
# 테이블로 바로 출력
gcloud logging read '...' \
  --format="table(timestamp,severity,textPayload,jsonPayload.message)"

# json에서 특정 필드만 grep
gcloud logging read '...' --format=json | grep -o '"message":"[^"]*"'
```

---
name: ralph-loop
description: "Step 4 자동 검증 루프 — 명확한 완료 조건이 있는 반복 작업에서 Ralph Loop 플러그인으로 자동화"
---

# Ralph Loop — 자동 반복 루프

> **선택적 스킬.** 명확한 완료 조건이 있는 구간에서만 사용.
> 사용자 승인 게이트가 있는 Step 2(브레인스토밍)·Step 5(코드 리뷰)·Step 7(피드백 반영)에는 사용 금지.

## 언제 사용하나

- Step 4에서 **정적 검증 통과**처럼 완료 조건이 정량적으로 명확할 때
- 반복 수정이 예상되는 lint/type-check/빌드 오류 수정 사이클
- 테스트 실패 → 수정 → 재실행 루프를 자동화하고 싶을 때

## 사용 금지 구간

| 단계 | 이유 |
|------|------|
| Step 2 브레인스토밍 | 사용자 승인 게이트 필수 |
| Step 5 코드 리뷰 | 서브에이전트 리뷰 결과를 사용자가 확인해야 함 |
| Step 7 피드백 반영 | 사용자 피드백 기반 — 자동화 불가 |

## 기본 사용법

```
/ralph-loop "[작업 설명]" --max-iterations 10 --completion-promise "[완료 조건]"
```

| 파라미터 | 설명 |
|---------|------|
| `--max-iterations` | 최대 반복 횟수 — 무한 루프 방지용으로 반드시 지정 |
| `--completion-promise` | 이 문자열을 Claude가 출력하면 루프 종료 |

중단: `/cancel-ralph`

## Step 4 적용 예시

```
/ralph-loop "flutter analyze 에러를 모두 수정해줘" \
  --max-iterations 15 \
  --completion-promise "ANALYZE_CLEAN"
```

```
/ralph-loop "dotnet build 에러 0개 달성해줘" \
  --max-iterations 10 \
  --completion-promise "BUILD_SUCCESS"
```

## 주의사항

- 완료 조건이 모호하면 엉뚱한 방향으로 반복될 수 있음 — **완료 조건은 구체적이고 검증 가능하게** 작성
- 루프 중 예상치 못한 코드 구조 변경이 감지되면 즉시 `/cancel-ralph` 후 사용자 확인
- 반복 간 파일 수정·git 히스토리는 유지됨 — 루프 시작 전 커밋 상태 확인 권장

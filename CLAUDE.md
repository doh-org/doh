# Travel App
지도 기반 여행 계획 공유 Android 앱.

## Communication
모든 상호작용과 커밋 메시지에서 극도로 간결하게,
문법보다 간결함을 우선시해라.

## Stack
- Backend: Go 1.25.8, Gin, gorilla/websocket
- Mobile: Flutter 3.41.9 (FVM으로 관리)
- Map: flutter_naver_map
- 외부 앱 연동: 티맵 (차량), 네이버맵 (도보/대중교통/자전거)
- DB: Supabase (PostgreSQL + PostGIS)
- 인증: JWT + 카카오 소셜 로그인
- 실시간: WebSocket (마커/경로 동기화)

## Structure
- `/backend`: Go API 서버
  - `/cmd`: 엔트리포인트
  - `/internal`: 비즈니스 로직
- `/mobile`: Flutter 앱
  - `/lib/features`: 기능별 폴더
- `/docs`: API 스펙, DB 스키마, 설계 문서

## Commands

### Flutter
```
fvm flutter pub get          # install dependencies
fvm flutter run              # run on connected device/emulator
fvm flutter test             # run all tests
fvm flutter test <file>      # run a single test file
fvm flutter build apk        # build android APK release
fvm flutter analyze          # lint
```

### Go (backend)
```
go mod tidy                            # sync dependencies
cd backend && go run cmd/main.go       # run the server
go test ./...                          # run all tests
go test ./pkg/foo/...                  # run tests in a specific package
go build ./...                         # build
go vet ./...                           # lint
```

## GitHub
GitHub와 상호작용할 때 GitHub CLI를 주요 수단으로 사용

## Git
- Strategy: Git Flow
- Commit format: `type(scope): description` (극도로 간결하게)
- Types: feat, fix, refactor, docs, test, chore
- Tag prefix: v (예: v1.0.0)

## PR
- PR 제목 형식: `type(scope): description`
- PR 머지 전 체크리스트 모두 완료
- 관련 이슈 반드시 연결 (closes #)

## Environment
- 로컬: .env 파일 사용
- 배포: GitHub Actions Secrets

## Plans
계획 마지막에 미해결 질문 목록 추가.
극도로 간결하게, 문법보다 간결함 우선.

## Architecture Rules
- Go: handler → service → repository 레이어 구분
- Flutter: feature-based 폴더 구조
- WebSocket: 마커/경로 변경만 실시간 동기화
- API 변경 시 docs/api.md 먼저 업데이트

## Never Do
- NEVER use `flutter` directly; use `fvm flutter`
- NEVER call map SDK directly from business logic
- NEVER use bare except in Go handlers

## code
- 다음 지침을 commit 전에 검토
- 상태관리: Riverpod만 사용 (Provider, Bloc 혼용 금지)
- 과잉 추상화 금지: 현재 필요한 것만 구현
- Null Safety 적극 활용
- async/await 중첩 금지
- Supabase: Supabase.instance.client 패턴 사용
- Naver Maps Client ID: dart-define으로 주입
- Directions API: Flutter에서 직접 호출 금지, Go 백엔드 경유

## flow
문제 정의 → 작고 안전한 변경 → 변경 리뷰 → 리팩터링 — 이 루프를 반복한다.

## 필수 규칙 (Mandatory Rules)
무엇이든 변경하기 전에, 호출/참조 경로를 포함하여 관련 파일을 처음부터 끝까지 읽는다.
작업, 커밋, PR을 작게 유지한다.
가정을 했다면 Issue/PR/ADR에 기록한다.
비밀값을 커밋하거나 로그에 남기지 않는다; 모든 입력을 검증하고 출력은 인코딩/정규화한다.
섣부른 추상화를 피하고 의도를 드러내는 이름을 사용한다.
결정하기 전에 최소 두 가지 대안을 비교한다.

## 마인드셋 (Mindset)
시니어 엔지니어처럼 생각한다.
추측으로 뛰어들거나 성급히 결론내리지 않는다.
항상 여러 접근을 평가하고, 장점/단점/위험을 각각 한 줄로 적은 뒤 가장 단순한 해법을 선택한다.
코드 및 파일 참조 규칙 (Code & File Reference Rules)
파일은 처음부터 끝까지 철저히 읽는다(부분 읽기 금지).
코드를 변경하기 전에 정의, 참조, 호출 지점, 관련 테스트, 문서/설정/플래그를 찾아 읽는다.
파일 전체를 읽지 않았다면 코드를 변경하지 않는다.
심볼을 수정하기 전에 전역 검색으로 사전/사후 조건을 파악하고, 영향도를 1–3줄로 남긴다.

## 필수 코딩 규칙 (Required Coding Rules)
코딩 전에 Problem 1-Pager: 배경 / 문제 / 목표 / 비목표 / 제약을 작성한다.
제한을 준수한다: 파일 ≤ 300 LOC, 함수 ≤ 50 LOC, 매개변수 ≤ 5, 순환 복잡도 ≤ 10. 초과 시 분리/리팩터링한다.
명시적인 코드를 선호한다; 숨겨진 “매직” 금지.
DRY를 따르되, 섣부른 추상화는 피한다.
부수효과(I/O, 네트워크, 전역 상태)는 경계층으로 격리한다.
구체적인 예외만 처리하고, 사용자에게 명확한 메시지를 제공한다.
구조화된 로깅을 사용하고 민감한 데이터를 기록하지 않는다(가능하면 요청/상관관계 ID를 전파한다).
시간대와 DST를 고려한다.

## 테스트 규칙 (Testing Rules)
새 코드에는 새 테스트를 추가한다; 버그 수정에는 회귀 테스트를 반드시 포함한다(먼저 실패하도록 작성).
테스트는 결정적이고 독립적이어야 하며, 외부 시스템은 가짜/계약(컨트랙트) 테스트로 대체한다.
E2E 테스트에는 ≥1개의 성공 경로와 ≥1개의 실패 경로를 포함한다.
동시성/락/재시도에서 비롯될 위험(중복, 데드락 등)을 선제적으로 평가한다.
보안 규칙 (Security Rules)
코드/로그/티켓에 비밀값을 절대 남기지 않는다.
입력을 검증·정규화·인코딩하고, 파라미터화된 접근을 사용한다.
최소 권한 원칙을 적용한다.

## 클린 코드 규칙 (Clean Code Rules)
의도를 드러내는 이름을 사용한다.
각 함수는 한 가지 일만 한다.
부수효과는 경계층으로 격리한다.
가드절을 우선 사용한다.
상수는 항상 심볼화한다(하드코딩 금지).
코드를 입력 → 처리 → 반환 구조로 구성한다.
실패는 구체적인 오류/메시지로 보고한다.
테스트는 사용 예제로도 동작하게 하고, 경계/실패 사례를 포함한다.

## 안티 패턴 규칙 (Anti-Pattern Rules)
전체 문맥을 읽지 않고 코드를 수정하지 않는다.
비밀값을 노출하지 않는다.
실패나 경고를 무시하지 않는다.
근거 없는 최적화나 추상화를 도입하지 않는다.
광범위한 예외를 남용하지 않는다.
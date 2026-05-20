# Travel App
지도 기반 여행 계획 공유 Android 앱.

## Communication
모든 상호작용과 커밋 메시지에서 극도로 간결하게,
문법보다 간결함을 우선시해라.

## Stack
- Backend: Go 1.25.8, Gin, gorilla/websocket
- Mobile: Flutter 3.41.9 (FVM으로 관리)
- Map: Google Maps Flutter
- 외부 앱 연동: 티맵 (차량), 카카오맵 (도보/대중교통)
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
- Branch 규칙: `{type}/{side}-{feature}`
  - side: `front` (Flutter) | `back` (Go) | 생략 가능 (양쪽 공통)
  - 예시: `feature/back-users`, `feature/front-folders`, `fix/back-auth`

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
파일 위치: `docs/plan/`
파일명 규칙: `{side}-{branch}-plan.md`
- side: `front` (Flutter) | `back` (Go)
- branch: 브랜치명 기능 부분 (예: `users`, `folder`)
- 예시: `back-users-plan.md`, `front-folder-plan.md`

## Architecture Rules
- Go: handler → service → repository 레이어 구분
- Flutter: feature-based 폴더 구조
- WebSocket: 마커/경로 변경만 실시간 동기화
- API 변경 시 docs/api.md 먼저 업데이트

## Never Do
- NEVER use `flutter` directly; use `fvm flutter`
- NEVER call map SDK directly from business logic
- NEVER use bare except in Go handlers

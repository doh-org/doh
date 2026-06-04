# API 명세

Base URL: `http://localhost:8080/api/v1`

---

## Auth

### 회원가입

| | |
|---|---|
| Method | `POST` |
| URL | `http://localhost:8080/api/v1/auth/signup` |
| Body | `raw` / `JSON` |

```json
{
  "email": "test@example.com",
  "password": "Test1234",
  "nickname": "테스트",
  "captcha_token": "test"
}
```

**Response** `201`
```json
{
  "access_token": "eyJ...",
  "refresh_token": "...",
  "user": {
    "user_id": "uuid",
    "email": "test@example.com",
    "nickname": "테스트",
    "created_at": "2026-05-19T00:00:00Z"
  }
}
```

| 코드 | 조건 |
|------|------|
| 201 | 성공 |
| 400 | 입력 검증 실패 (이메일 형식, 비밀번호 정책, 닉네임) |
| 422 | CAPTCHA 실패 |
| 401 | 이미 가입된 이메일 등 인증 실패 |
| 429 | Rate limit 초과 (IP 기준 분당 10회) |

---

### 로그인

| | |
|---|---|
| Method | `POST` |
| URL | `http://localhost:8080/api/v1/auth/login` |
| Body | `raw` / `JSON` |

```json
{
  "email": "test@example.com",
  "password": "Test1234",
  "captcha_token": "test"
}
```

**Response** `200`
```json
{
  "access_token": "eyJ...",
  "refresh_token": "...",
  "user": {
    "user_id": "uuid",
    "email": "test@example.com",
    "nickname": "테스트",
    "created_at": "2026-05-19T00:00:00Z"
  }
}
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 400 | 입력 검증 실패 |
| 422 | CAPTCHA 실패 |
| 401 | 이메일/비밀번호 불일치 |
| 429 | Rate limit 초과 |

---

### 로그아웃

| | |
|---|---|
| Method | `POST` |
| URL | `http://localhost:8080/api/v1/auth/logout` |
| Auth | `Bearer Token` (Postman → Authorization 탭 → Type: Bearer Token) |
| Body | 없음 |

**Postman Authorization 탭 설정**
```
Type   : Bearer Token
Token  : <로그인/회원가입 응답의 access_token 값 붙여넣기>
```

**Response** `204` (body 없음)

| 코드 | 조건 |
|------|------|
| 204 | 성공 |
| 401 | 토큰 없음, 만료, 서명 불일치 |

---

### 내 프로필 조회

| | |
|---|---|
| Method | `GET` |
| URL | `http://localhost:8080/api/v1/auth/me` |
| Auth | `Bearer Token` (Postman → Authorization 탭 → Type: Bearer Token) |
| Body | 없음 |

**Postman Authorization 탭 설정**
```
Type   : Bearer Token
Token  : <로그인/회원가입 응답의 access_token 값 붙여넣기>
```

**Response** `200`
```json
{
  "user_id": "uuid",
  "email": "test@example.com",
  "nickname": "테스트",
  "created_at": "2026-05-19T00:00:00Z"
}
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 401 | 토큰 없음 또는 만료 |

---

## 공통

**비밀번호 정책**: 8자 이상, 대문자·소문자·숫자 각 1자 이상 (signup만 적용)

**에러 응답 형식**
```json
{ "error": "메시지" }
```

**인증 (Trips 이하 모든 엔드포인트)**
```
Authorization: Bearer {access_token}
```
Postman: Authorization 탭 → Type: Bearer Token → 로그인 응답의 `access_token` 입력.

---

## Trips

### `POST /api/v1/trips/add` — 완료

여행 폴더 생성.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "title": "제주도 여행",
  "description": "3박 4일",
  "destination": "제주도",
  "start_date": "2026-07-01",
  "end_date": "2026-07-04"
}
```

필수: `title`  
선택: `description`, `destination`, `start_date`, `end_date`  
추후 지원 (DB 컬럼 추가 필요): `color`

**검증**
- `title`: trim 후 1자 이상, 50자 이하
- `end_date >= start_date` (둘 다 전달 시)

**Response 201**: 생성된 trip 전체 필드

| 코드 | 조건 |
|------|------|
| 201 | 성공 |
| 400 | 검증 실패 |
| 401 | 인증 실패 |

---

### `GET /api/v1/trips` — 완료

내가 멤버인 여행 목록. 최신 생성순 반환.

| | |
|---|---|
| Auth | Bearer Token |

**Response 200**
```json
[
  {
    "id": "uuid",
    "owner_id": "uuid",
    "title": "제주도 여행",
    "description": "3박 4일",
    "destination": "제주도",
    "start_date": "2026-07-01",
    "end_date": "2026-07-04",
    "deleted_at": null,
    "created_at": "2026-05-25T00:00:00Z"
  }
]
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 (빈 배열 가능) |
| 401 | 인증 실패 |

---

### `GET /api/v1/trips/:tripId` — 완료

단건 조회.

| | |
|---|---|
| Auth | Bearer Token |

**Response 200**
```json
{
  "id": "uuid",
  "owner_id": "uuid",
  "title": "제주도 여행",
  "description": "3박 4일",
  "destination": "제주도",
  "start_date": "2026-07-01",
  "end_date": "2026-07-04",
  "deleted_at": null,
  "created_at": "2026-05-25T00:00:00Z"
}
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |
| 404 | trip 없음 또는 삭제됨 |

---

### `PATCH /api/v1/trips/:tripId` — 완료

수정. 전달된 필드만 변경. owner만 가능.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "title": "제주도 여름 여행",
  "destination": "제주 서귀포"
}
```

모든 필드 선택. 검증은 POST와 동일.

**Response 200**: 수정된 trip 전체 필드

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 400 | 검증 실패 |
| 401 | 인증 실패 |
| 403 | owner 아님 |
| 404 | trip 없음 또는 삭제됨 |

---

### `DELETE /api/v1/trips/:tripId` — 완료

soft delete. owner만 가능.

| | |
|---|---|
| Auth | Bearer Token |

**Response 204**: body 없음

| 코드 | 조건 |
|------|------|
| 204 | 성공 |
| 401 | 인증 실패 |
| 403 | owner 아님 |
| 404 | trip 없음 또는 삭제됨 |

---

## Markers

### `GET /api/v1/trips/:tripId/markers` — 미완

여행 폴더의 장소 목록 조회. `route_waypoints."order"` 오름차순 반환.

| | |
|---|---|
| Auth | Bearer Token |

**Query params** (모두 선택, 조합 가능)
- `q`: 장소명 키워드 검색 (ILIKE `%q%`) — 생략 시 전체
- `category_id`: 카테고리 UUID 필터 — `null` 전달 시 카테고리 미지정 마커만 반환

**Response 200**
```json
[
  {
    "id": "uuid",
    "trip_id": "uuid",
    "category_id": "uuid",
    "created_by": "uuid",
    "name": "투썸플레이스 강남점",
    "latitude": 37.5264,
    "longitude": 126.8977,
    "address": "서울 강남구 테헤란로 ...",
    "memo": null,
    "detail": { "phone": "02-1234-5678", "opening_hours": "09:00-22:00" },
    "source": "search",
    "visit_days": [1, 3],
    "created_at": "2026-05-25T00:00:00Z"
  }
]
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 (빈 배열 가능) |
| 401 | 인증 실패 |
| 404 | trip 없음 또는 멤버 아님 |

---

### `GET /api/v1/trips/:tripId/markers/:markerId` — 미완

마커 단건 조회.

| | |
|---|---|
| Auth | Bearer Token |

**Response 200**
```json
{
  "id": "uuid",
  "trip_id": "uuid",
  "category_id": "uuid",
  "created_by": "uuid",
  "name": "투썸플레이스 강남점",
  "latitude": 37.5264,
  "longitude": 126.8977,
  "address": "서울 강남구 테헤란로 ...",
  "memo": null,
  "detail": { "phone": "02-1234-5678", "opening_hours": "09:00-22:00" },
  "source": "search",
  "visit_days": [1, 3],
  "created_at": "2026-05-25T00:00:00Z"
}
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 401 | 인증 실패 |
| 404 | 마커 없음 또는 trip 멤버 아님 |

---

### `POST /api/v1/trips/:tripId/markers/add` — 미완

장소 추가. 검색·롱탭 공용. 마커 생성 후 `route_waypoints` 마지막 순서로 자동 추가.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "name": "투썸플레이스 강남점",
  "latitude": 37.5264,
  "longitude": 126.8977,
  "source": "search",
  "category_id": "uuid",
  "address": "서울 강남구 테헤란로 ...",
  "detail": { "phone": "02-1234-5678", "opening_hours": "09:00-22:00" },
  "visit_days": [1, 3]
}
```

필수: `name`, `latitude`, `longitude`, `source`  
선택: `category_id`, `address`, `detail`, `visit_days`  
v1 예정: `memo`

**검증**
- `name`: trim 후 1자 이상, 100자 이하
- `source`: `search` | `longpress` | `share` 외 400
- `latitude`: -90 ~ 90
- `longitude`: -180 ~ 180

**Response 201**: 생성된 마커 전체 필드

| 코드 | 조건 |
|------|------|
| 201 | 성공 |
| 400 | 필수 필드 누락, 검증 실패 |
| 401 | 인증 실패 |
| 404 | trip 없음 또는 멤버 아님 |

---

### `PATCH /api/v1/trips/:tripId/markers/:markerId` — 미완

장소 수정. 전달된 필드만 변경 (partial update). trip 멤버 전체 허용.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "name": "메가커피 강남역점",
  "latitude": 37.5264,
  "longitude": 126.8977,
  "address": "서울 강남구 테헤란로 ...",
  "category_id": "uuid",
  "visit_days": [2]
}
```

모든 필드 선택. `category_id: null`로 보내면 카테고리 해제. `visit_days: []`로 보내면 전체 해제.  
`visit_days` 미전달 시 기존 값 유지. v1 예정: `memo`

**검증**
- `name`: 전달 시 trim 후 1자 이상, 100자 이하
- `latitude`/`longitude`: 한 쪽만 전달 시 400 (둘 다 전달하거나 둘 다 생략)

**Response 200**: 수정된 마커 전체 필드

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 400 | 검증 실패 |
| 401 | 인증 실패 |
| 404 | 마커 없음 또는 trip 멤버 아님 |

---

### `DELETE /api/v1/trips/:tripId/markers/:markerId` — 미완

장소 삭제 (hard delete). `route_waypoints`에서 해당 마커 레코드도 함께 삭제.

| | |
|---|---|
| Auth | Bearer Token |

**Response 204**: body 없음

| 코드 | 조건 |
|------|------|
| 204 | 성공 |
| 401 | 인증 실패 |
| 404 | 마커 없음 또는 trip 멤버 아님 |

---

## Routes

### `PATCH /api/v1/trips/:tripId/route/reorder` — 미완

마커 순서 변경. 원하는 순서대로 marker_id 배열 전달 → `route_waypoints."order"` 재인덱싱.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "marker_ids": ["uuid-a", "uuid-b", "uuid-c"]
}
```

- 배열 = 새 순서 (index 0이 첫 번째)
- trip에 속한 마커 전체를 포함해야 함 (누락 시 400)

**Response 200**
```json
{
  "reordered": 3
}
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 400 | 배열 누락, trip 소속이 아닌 marker_id 포함, 마커 수 불일치 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |

---

## Categories

### `GET /api/v1/trips/:tripId/categories` — 미완

카테고리 목록 조회.

| | |
|---|---|
| Auth | Bearer Token |

**Response 200**
```json
[
  { "id": "uuid", "trip_id": "uuid", "name": "음식", "color": "#FF6B6B", "created_at": "..." },
  { "id": "uuid", "trip_id": "uuid", "name": "카페", "color": "#FFB347", "created_at": "..." },
  { "id": "uuid", "trip_id": "uuid", "name": "관광", "color": "#4ECDC4", "created_at": "..." },
  { "id": "uuid", "trip_id": "uuid", "name": "숙소", "color": "#5DADE2", "created_at": "..." },
  { "id": "uuid", "trip_id": "uuid", "name": "기타", "color": "#95A5A6", "created_at": "..." }
]
```

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |

---

### `POST /api/v1/trips/:tripId/categories` (v1) — 미완

카테고리 추가.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "name": "쇼핑",
  "color": "#A29BFE"
}
```

필수: `name`, `color`

**검증**
- `name`: trim 후 1자 이상, 50자 이하. trip 내 중복 불허
- `color`: `#RRGGBB` 형식

**Response 201**: 생성된 카테고리 전체 필드

| 코드 | 조건 |
|------|------|
| 201 | 성공 |
| 400 | 검증 실패, 이름 중복 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |

---

### `PATCH /api/v1/trips/:tripId/categories/:categoryId` (v1) — 미완

카테고리 수정.

| | |
|---|---|
| Auth | Bearer Token |
| Body | `raw` / `JSON` |

**Request**
```json
{
  "name": "쇼핑몰",
  "color": "#6C5CE7"
}
```

모든 필드 선택.

**Response 200**: 수정된 카테고리 전체 필드

| 코드 | 조건 |
|------|------|
| 200 | 성공 |
| 400 | 검증 실패 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |
| 404 | 카테고리 없음 |

---

### `DELETE /api/v1/trips/:tripId/categories/:categoryId` (v1) — 미완

카테고리 삭제. 연결된 `markers.category_id`는 DB FK SET NULL으로 자동 처리.

| | |
|---|---|
| Auth | Bearer Token |

**Response 204**: body 없음

| 코드 | 조건 |
|------|------|
| 204 | 성공 |
| 401 | 인증 실패 |
| 403 | trip 멤버 아님 |
| 404 | 카테고리 없음 |

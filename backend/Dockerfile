# 1단계: Go 빌드 전용 이미지 (결과물만 다음 단계로 넘김)
FROM golang:1.25-alpine AS build
WORKDIR /app

# 의존성 먼저 복사 → 코드만 바뀌면 모듈 다운로드 캐시 재사용
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# CGO 끄고 정적 빌드 → C 라이브러리 없는 최소 이미지에서도 실행 가능
RUN CGO_ENABLED=0 go build -o /server ./cmd

# 2단계: 실행 전용 최소 이미지 (쉘도 없음, CA 인증서는 포함 → HTTPS 호출 가능)
FROM gcr.io/distroless/static-debian12
COPY --from=build /server /server
EXPOSE 8080
CMD ["/server"]

# ---- build ----
FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api

# ---- runtime ----
FROM alpine:3.20
RUN addgroup -S momo && adduser -S -G momo momo
COPY --from=build /out/api /usr/local/bin/api
USER momo
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/api"]

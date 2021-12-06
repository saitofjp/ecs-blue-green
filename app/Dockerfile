FROM golang:1.17.4-alpine AS build

WORKDIR /go/src/app

COPY go.mod ./
RUN go mod download

COPY main.go ./
RUN go build -o /app

FROM alpine:3.15.0

WORKDIR /

COPY --from=build /app ./

EXPOSE 8080

RUN addgroup -S app && adduser -S app -G app
USER app:app

CMD ["/app"]

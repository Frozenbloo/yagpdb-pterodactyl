# ---- build stage: compile YAGPDB from source (there are no official binaries) ----
FROM golang:1.26-alpine AS build
ENV GOTOOLCHAIN=auto
ARG YAGPDB_VERSION=master
RUN apk add --no-cache git
RUN git clone --depth 1 --branch ${YAGPDB_VERSION} https://github.com/botlabs-gg/yagpdb.git /src
WORKDIR /src/cmd/yagpdb
# Static binary (frontend assets are embedded via go:embed), runs on musl with no libc.
RUN CGO_ENABLED=0 go build -mod=mod -o /yagpdb .

# ---- runtime stage: Postgres + Redis + Supervisor + the bot, all in one image ----
FROM alpine:3.22
RUN apk add --no-cache \
    ca-certificates tzdata \
    postgresql16 postgresql16-contrib \
    redis supervisor nss_wrapper

RUN adduser -D -h /home/container container

COPY --from=build /yagpdb /app/yagpdb
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /app/yagpdb /entrypoint.sh

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
CMD ["sh", "/entrypoint.sh"]

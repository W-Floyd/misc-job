FROM golang:1-alpine

WORKDIR /build

COPY builder/ .

RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build go build -o builder .

FROM alpine:latest

RUN apk add --update --no-cache wget bash fontconfig

ENV TECTONIC_VERSION=0.15.0
ENV TERM xterm-256color

RUN wget "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic@${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-x86_64-unknown-linux-musl.tar.gz" -O 'tectonic.tar.gz' && \
    tar -xf 'tectonic.tar.gz' && \
    rm 'tectonic.tar.gz' && \
    mv 'tectonic' '/usr/bin/tectonic'

COPY ./builder /builder
COPY --from=0 /build/builder /builder/builder

ENTRYPOINT ["bash", "/builder/build.sh"]

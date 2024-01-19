FROM golang:1-alpine

WORKDIR /build

COPY builder/ .

RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build go build -o main .

FROM alpine:latest

WORKDIR /build/

ENV TECTONIC_VERSION=0.14.1
ENV TERM xterm-256color

RUN apk add --update --no-cache bash wget

RUN wget "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic@${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-x86_64-unknown-linux-musl.tar.gz" -O 'tectonic.tar.gz'
RUN tar -xf 'tectonic.tar.gz'
RUN rm 'tectonic.tar.gz'
RUN mv 'tectonic' '/usr/bin/tectonic'

COPY ./builder ./builder
COPY --from=0 /build/main ./builder/builder

ENTRYPOINT ["bash", "./builder/build.sh"]

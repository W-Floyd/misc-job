FROM alpine:latest

ENV TECTONIC_VERSION=0.14.1

WORKDIR /build/

RUN apk add --update --no-cache bash wget

RUN wget "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic@${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-x86_64-unknown-linux-musl.tar.gz" -O 'tectonic.tar.gz'
RUN tar -xf 'tectonic.tar.gz'
RUN rm 'tectonic.tar.gz'
RUN mv 'tectonic' '/usr/bin/tectonic'

WORKDIR /build/

ENV TERM xterm-256color

ENTRYPOINT ["bash", "build.sh"]

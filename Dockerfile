FROM alpine:latest

WORKDIR /build/

RUN apk add --update --no-cache bash

# Install python/pip
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 sed && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

RUN pip install j2cli[yaml]

COPY docker/ /build/docker/

RUN apk add --update --no-cache wget

RUN wget 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic@0.8.0/tectonic-0.8.0-x86_64-unknown-linux-musl.tar.gz' -O 'tectonic.tar.gz'
RUN tar -xf 'tectonic.tar.gz'
RUN rm 'tectonic.tar.gz'
RUN mv 'tectonic' '/usr/bin/tectonic'

WORKDIR /build/

ENV TERM xterm-256color

ENTRYPOINT ["bash", "build.sh"]

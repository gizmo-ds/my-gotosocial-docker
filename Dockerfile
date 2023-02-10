FROM quay.io/goswagger/swagger:v0.30.0 AS swagger
WORKDIR /gotosocial
COPY gotosocial/go.mod go.mod
COPY gotosocial/go.sum go.sum
COPY gotosocial/cmd cmd
COPY gotosocial/internal internal
RUN swagger generate spec -o swagger.yaml --scan-models

FROM docker.io/library/node:16.15.1-alpine3.15 AS bundler
COPY gotosocial/web /web
RUN yarn install --cwd web/source && \
    BUDO_BUILD=1 node web/source  && \
    rm -r web/source

FROM docker.io/library/golang:1.20-alpine AS builder
WORKDIR /gotosocial
COPY gotosocial /gotosocial
ENV CGO_ENABLED=0
ARG version=development
RUN go mod download && \
    go build -trimpath -tags timetzdata \
    -tags "netgo osusergo static_build" \
    -o gotosocial \
    -ldflags "-s -w -X main.Version=$version" \
    ./cmd/gotosocial

FROM docker.io/library/alpine:latest
RUN apk add ffmpeg
USER 1000:1000
WORKDIR /gotosocial/storage
WORKDIR /gotosocial
COPY --from=bundler --chown=1000:1000 /web /gotosocial/web
COPY --from=builder --chown=1000:1000 /gotosocial/gotosocial /gotosocial/gotosocial
COPY --from=swagger --chown=1000:1000 /gotosocial/swagger.yaml /gotosocial/swagger.yaml
VOLUME [ "/gotosocial/storage" ]
ENTRYPOINT [ "/gotosocial/gotosocial", "server", "start" ]

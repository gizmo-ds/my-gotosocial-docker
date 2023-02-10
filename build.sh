#!/bin/bash
docker build --build-arg version=$(git --git-dir=.git/modules/gotosocial describe --tags --always) -t ghcr.io/gizmo-ds/gotosocial:latest -f Dockerfile .

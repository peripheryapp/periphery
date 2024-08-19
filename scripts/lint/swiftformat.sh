#!/usr/bin/env bash

VERSION="0.54.3"
INSTALLED_VERSION=$(swiftformat --version)

if [[ "$INSTALLED_VERSION" != "$VERSION" ]]; then
  echo "ERROR: SwiftFormat ${VERSION} is required, installed version is ${INSTALLED_VERSION}."
  exit 1
fi

swiftformat --quiet .
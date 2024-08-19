#!/usr/bin/env bash

VERSION="0.56.1"
INSTALLED_VERSION=$(swiftlint --version)

if [[ "$INSTALLED_VERSION" != "$VERSION" ]]; then
  echo "ERROR: SwiftLint ${VERSION} is required, installed version is ${INSTALLED_VERSION}."
  exit 1
fi

swiftlint lint --quiet
#!/bin/bash

set -e

LAUNCH_WORKING_DIRECTORY=$(pwd)

if test "${BUILD_WORKING_DIRECTORY+x}"; then
  cd $BUILD_WORKING_DIRECTORY
fi

$LAUNCH_WORKING_DIRECTORY/Sources/Frontend "${@:1}"
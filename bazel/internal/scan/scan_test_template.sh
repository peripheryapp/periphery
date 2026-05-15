#!/bin/bash
set -eo pipefail
cd "${TEST_SRCDIR}/${TEST_WORKSPACE}"
if [ -n "%config_path%" ]; then
    exec "%periphery_path%" scan --strict --disable-update-check --project-root "$(pwd)" --config "%config_path%" --generic-project-config "%project_config_path%"
else
    exec "%periphery_path%" scan --strict --disable-update-check --project-root "$(pwd)" --generic-project-config "%project_config_path%"
fi

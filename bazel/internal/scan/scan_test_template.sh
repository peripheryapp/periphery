#!/bin/bash
set -euo pipefail
cd "${TEST_SRCDIR}/${TEST_WORKSPACE}"
exec "%periphery_path%" scan --strict --disable-update-check --project-root "$(pwd)" --config "%config_path%" --generic-project-config "%project_config_path%"

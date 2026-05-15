#!/bin/bash
set -eo pipefail
if [ -n "%config_path%" ]; then
    exec "%periphery_path%" scan --config "%config_path%" --generic-project-config "%project_config_path%"
else
    exec "%periphery_path%" scan --generic-project-config "%project_config_path%"
fi

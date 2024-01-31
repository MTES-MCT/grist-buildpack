#!/bin/sh

export PYTHON_VERSION_ON_CREATION=3
export GRIST_SINGLE_PORT=true
export GRIST_SERVE_SAME_ORIGIN=true
export GVISOR_FLAGS="-unprivileged -ignore-cgroups"
export GRIST_SANDBOX_FLAVOR=unsandboxed
export GRIST_HOST=0.0.0.0
export GRIST_INST_DIR=/tmp/persist
export GRIST_DATA_DIR=$GRIST_INST_DIR/docs
export PATH=/app/nodejs/bin:/app/yarn/bin:$PATH
/app/yarn/bin/yarn start
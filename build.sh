#!/bin/bash -x
set -euo pipefail

(

cd linux
cat tools/testing/selftests/bpf/config tools/testing/selftests/bpf/config.x86_64 > .config

make -j -l8 olddefconfig all
)

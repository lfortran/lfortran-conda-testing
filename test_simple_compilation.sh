#! shell

set -ex

export PATH="$CONDA_PREFIX\\bin:$ORIGINAL_PATH"

cd lfortran/examples
lfortran expr2.f90

#!/usr/bin/env bash
# Build and run the Fortran Parallel Research Kernels (PRK) with LFortran.
#
# Usage: ci/test_prk.sh <serial|stdpar|metal|coarray>
#
#   serial  - serial kernels on the CPU
#   stdpar  - `do concurrent` kernels on the CPU
#   metal   - `do concurrent` kernels offloaded to the Apple Metal GPU
#   coarray - coarray kernels, linked against Caffeine (needs CAFFEINE_PREFIX)
#
# Every kernel verifies its own result and prints "Solution validates".
set -euo pipefail

MODE="${1:?usage: $0 <serial|stdpar|metal|coarray>}"
FC="${FC:-lfortran}"
PRK_COMMIT=870a0a9a9b3be5904e5e01ad071c90a870a3f6cd

if [[ ! -d prk ]]; then
    git clone https://github.com/ParRes/Kernels.git prk
fi
cd prk
git checkout -q "$PRK_COMMIT"
cd FORTRAN

BUILD="build-$MODE"
rm -rf "$BUILD"
mkdir "$BUILD"
FFLAGS=(--cpp -DRADIUS=2 -DSTAR --no-style-suggestions --no-warnings)
EXTRA=()
RUN=()
case "$MODE" in
    serial)
        # dgemm.F90's tiled path reads B(kt:kt+tile_size, ...), one element
        # too many (caught by LFortran's runtime checks), so run it untiled.
        KERNELS="nstream transpose stencil p2p pic dgemm"
        ;;
    stdpar)
        KERNELS="nstream-stdpar transpose-stdpar stencil-stdpar dgemm-stdpar"
        ;;
    metal)
        KERNELS="nstream-stdpar transpose-stdpar stencil-stdpar dgemm-stdpar"
        # The kernels compute in real(8) with integer(8) indices, which Metal
        # does not support, so every loop currently falls back to the CPU
        # with a warning. This checks that the --gpu=metal pipeline handles
        # the code and gives correct results; Formal and Fiats exercise the
        # actual GPU offload.
        EXTRA=(--gpu=metal --gpu-allow-cpu-fallback)
        ;;
    coarray)
        : "${CAFFEINE_PREFIX:?CAFFEINE_PREFIX must point to the Caffeine install}"
        # Not tested yet due to LFortran bugs:
        #   nstream-coarray:   coarray allocate ignores stat= (lfortran/lfortran#14114)
        #   transpose-coarray: crash on coindexed array section (lfortran/lfortran#14115)
        #   stencil-coarray:   this_image(coarray) unsupported (lfortran/lfortran#14116)
        # gasnetrun_smp exits with 0 even on `error stop` (lfortran/lfortran#12326),
        # so success is checked via the "Solution validates" output below.
        KERNELS="p2p-coarray"
        EXTRA=(--coarray -L"$CAFFEINE_PREFIX/lib" -lcaffeine -lgasnet-smp-seq)
        RUN=("$CAFFEINE_PREFIX/bin/gasnetrun_smp" -n "${CAF_IMAGES:-4}")
        ;;
    *)
        echo "Unknown mode: $MODE" >&2
        exit 1
        ;;
esac

kernel_args() {
    case "$1" in
        nstream*)   echo "10 1000000" ;;
        transpose*) echo "10 512 32" ;;
        stencil*)   echo "10 500" ;;
        p2p*)       echo "10 512 512" ;;
        pic*)       echo "10 1000 1000 1 2 GEOMETRIC 0.99" ;;
        dgemm-*)    echo "5 128" ;;
        dgemm)      echo "5 128 0" ;;
    esac
}

# Module files go to the current directory, so build each mode in its own
# directory to keep them separate.
cp prk_mod.F90 "$BUILD/"
cd "$BUILD"
set -x
$FC "${FFLAGS[@]}" -c prk_mod.F90 -o prk_mod.o
for k in $KERNELS; do
    $FC "${FFLAGS[@]}" "../$k.F90" prk_mod.o -o "$k" ${EXTRA[@]+"${EXTRA[@]}"}
    ${RUN[@]+"${RUN[@]}"} "./$k" $(kernel_args "$k") | tee "$k.out"
    # nstream prints "Solution validate", the others "Solution validates"
    grep -q "Solution validate" "$k.out"
done
set +x
echo "PRK ($MODE): all kernels validated"

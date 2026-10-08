# lfortran-conda-testing
 Repository for testing conda lfortran package

The CI installs the `lfortran` package from conda-forge (version set by
`LFORTRAN_VERSION` in `.github/workflows/CI.yml`) and tests it on:

* LFortran's own integration, reference and LSP tests (Linux, macOS)
* Third-party codes, all pinned to a fixed commit (Linux, macOS):
  * Standalone: Modern Minpack, dftatom, fastGPT, stdlib, SNAP, POT3D, PRIMA,
    Reference-LAPACK (smoke tests, Linux only)
  * fpm packages: fpm, Julienne, Assert, neural-fortran, toml-f,
    fortran-regex, fortran-shlex
  * `do concurrent` and GPU: Formal, Fiats and the Parallel Research Kernels,
    on the CPU and on the Apple Metal GPU (macOS)
  * Coarrays: Caffeine (built with LFortran, unit and multi-image tests) and
    the Parallel Research Kernels coarray kernels, run with Caffeine
* Third-party codes on Windows (MSVC linker): Modern Minpack, fortran-regex,
  fortran-shlex, toml-f, Assert, the Parallel Research Kernels (serial),
  SNAP and stdlib
* WASM backends (Linux)

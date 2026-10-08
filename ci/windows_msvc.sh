# Put MSVC's link.exe first on PATH. LFortran links Windows executables by
# running `link`, which in Git Bash would otherwise resolve to the coreutils
# `link` from /usr/bin. Source this at the start of every Windows bash step.
if [[ -z "${VCToolsInstallDir:-}" ]]; then
    echo "ERROR: MSVC environment is not set up (VCToolsInstallDir is empty)" >&2
    return 1
fi
export PATH="$(cygpath -u "$VCToolsInstallDir")bin/Hostx64/x64:$PATH"

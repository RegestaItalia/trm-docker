#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TRM_STATE_DIR:-/var/lib/trm}"

fatal() { echo "ERROR: $*" >&2; exit 1; }
info()  { echo "[first-run] $*"; }

: "${INSTALLDATA:?INSTALLDATA env var is required on first run (e.g. -e INSTALLDATA=/installdata)}"

if [[ ! -d "$INSTALLDATA" ]]; then
  fatal "INSTALLDATA='$INSTALLDATA' is not a directory (did you mount it?)"
fi

shopt -s nullglob
libicudata_files=( "$INSTALLDATA"/libicudata[0-9]*.so )
libicui18n_files=( "$INSTALLDATA"/libicui18n[0-9]*.so )
libicuuc_files=( "$INSTALLDATA"/libicuuc[0-9]*.so )
shopt -u nullglob

# r3trans mandatory files directly in INSTALLDATA
[[ -f "$INSTALLDATA/R3trans" ]] || fatal "Missing mandatory file '$INSTALLDATA/R3trans'"
(( ${#libicudata_files[@]} > 0 )) || fatal "Missing mandatory file matching '$INSTALLDATA/libicudata##.so'"
(( ${#libicui18n_files[@]} > 0 )) || fatal "Missing mandatory file matching '$INSTALLDATA/libicui18n##.so'"
(( ${#libicuuc_files[@]} > 0 )) || fatal "Missing mandatory file matching '$INSTALLDATA/libicuuc##.so'"

info "Persisting r3trans files into volume: ${STATE_DIR}/r3trans"
mkdir -p "${STATE_DIR}/r3trans"
cp -a "$INSTALLDATA/R3trans" "${STATE_DIR}/r3trans/"
cp -a "${libicudata_files[@]}" "${STATE_DIR}/r3trans/"
cp -a "${libicui18n_files[@]}" "${STATE_DIR}/r3trans/"
cp -a "${libicuuc_files[@]}" "${STATE_DIR}/r3trans/"

# optional nwrfcsdk files directly in INSTALLDATA
if [[ -f "$INSTALLDATA/rfcexec" ]] \
  && [[ -f "$INSTALLDATA/startrfc" ]] \
  && [[ -f "$INSTALLDATA/libsapnwrfc.so" ]] \
  && [[ -f "$INSTALLDATA/libsapucum.so" ]]; then

  info "Persisting nwrfcsdk files into volume: ${STATE_DIR}/nwrfcsdk"
  mkdir -p "${STATE_DIR}/nwrfcsdk"
  mkdir -p "${STATE_DIR}/nwrfcsdk/bin"
  mkdir -p "${STATE_DIR}/nwrfcsdk/lib"

  cp -a "$INSTALLDATA/rfcexec" "${STATE_DIR}/nwrfcsdk/bin/"
  cp -a "$INSTALLDATA/startrfc" "${STATE_DIR}/nwrfcsdk/bin/"
  cp -a "$INSTALLDATA/libsapnwrfc.so" "${STATE_DIR}/nwrfcsdk/lib/"
  cp -a "$INSTALLDATA/libsapucum.so" "${STATE_DIR}/nwrfcsdk/lib/"
  cp -a "${libicudata_files[@]}" "${STATE_DIR}/nwrfcsdk/lib/"
  cp -a "${libicui18n_files[@]}" "${STATE_DIR}/nwrfcsdk/lib/"
  cp -a "${libicuuc_files[@]}" "${STATE_DIR}/nwrfcsdk/lib/"

  # needed to install node-rfc
  mkdir -p /usr/local/sap
  ln -sfn "${STATE_DIR}/nwrfcsdk" /usr/local/sap/nwrfcsdk
  echo "/usr/local/sap/nwrfcsdk/lib" > /etc/ld.so.conf.d/nwrfcsdk.conf
  ldconfig || true

  # install node-rfc
  info "Installing node-rfc"
  npm i -g node-rfc@latest --silent
fi

info "Installing trm-client"
npm i -g trm-client@latest --silent

info "Installing trm-plugin-btp-dest"
npm i -g trm-plugin-btp-dest@latest --silent

info "First-run completed"
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TRM_STATE_DIR:-/var/lib/trm}"
MARKER="${STATE_DIR}/.initialized"

fatal() { echo "ERROR: $*" >&2; exit 1; }
info()  { echo "[entrypoint] $*"; }

# Require the persistent volume
if ! mountpoint -q "$STATE_DIR"; then
  fatal "State dir '$STATE_DIR' must be a mounted volume/bind. Example: -v trm_state:$STATE_DIR"
fi

# Must be writable
touch "${STATE_DIR}/.write_test" 2>/dev/null || fatal "State dir '$STATE_DIR' is not writable."
rm -f "${STATE_DIR}/.write_test"

# Persist npm "global" installs in the mounted state volume
export NPM_CONFIG_PREFIX="${STATE_DIR}/npm-global"
export NPM_CONFIG_CACHE="${STATE_DIR}/npm-cache"
mkdir -p "${NPM_CONFIG_PREFIX}/bin" "${NPM_CONFIG_PREFIX}/lib" "${NPM_CONFIG_CACHE}"
export PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"

# First run?
if [[ ! -f "$MARKER" ]]; then
  info "First run detected, running init..."
  /usr/local/bin/first-run-init.sh
  date -Iseconds > "$MARKER"
  info "Initialization done!"
fi

# Always recreate symlinks
if [[ -d "${STATE_DIR}/r3trans" ]]; then
  ln -sfn "${STATE_DIR}/r3trans" /r3trans
  if [[ -f /r3trans/R3trans ]]; then chmod +x /r3trans/R3trans || true; fi
fi
if [[ -d "${STATE_DIR}/nwrfcsdk" ]]; then
  mkdir -p /usr/local/sap
  ln -sfn "${STATE_DIR}/nwrfcsdk" /usr/local/sap/nwrfcsdk
  echo "/usr/local/sap/nwrfcsdk/lib" > /etc/ld.so.conf.d/nwrfcsdk.conf
  ldconfig || true
fi

exec "$@"
#!/usr/bin/env bash
# verify-demos-on-emulator.sh — Build, install, launch, and verify demo APKs on an emulator/device.
#
# Usage:
#   .github/scripts/verify-demos-on-emulator.sh [--serial <adb-serial>] [--output <dir>] [--no-build]

set -euo pipefail

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "• $*"; }

SERIAL=""
OUTPUT_DIR=""
NO_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial)   SERIAL="$2"; shift 2 ;;
    --output)   OUTPUT_DIR="$2"; shift 2 ;;
    --no-build) NO_BUILD=1; shift ;;
    -*)         die "Unknown option: $1" ;;
    *)          die "Unexpected argument: $1" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$APP_ROOT}"
BUILD_SCRIPT="$APP_ROOT/.github/scripts/build-apk.sh"

[[ -x "$BUILD_SCRIPT" ]] || die "Build script not found or not executable: $BUILD_SCRIPT"
[[ -d "$APP_ROOT/tests/demos" ]] || die "Demo directory not found: $APP_ROOT/tests/demos"

command -v adb >/dev/null 2>&1 || die "adb not found in PATH"

if [[ -z "$SERIAL" ]]; then
  DEVICES=()
  while IFS= read -r device; do
    DEVICES+=("$device")
  done < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  [[ ${#DEVICES[@]} -gt 0 ]] || die "No adb devices in 'device' state"
  SERIAL="${DEVICES[0]}"
fi

ADB=(adb -s "$SERIAL")
info "Using device: $SERIAL"

base_pkg() {
  grep -oE 'namespace\s*=\s*"[^"]+"' "$APP_ROOT/app/build.gradle.kts" \
    | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

base_name() {
  sed -nE 's/.*<string name="app_name">(.*)<\/string>.*/\1/p' \
    "$APP_ROOT/app/src/main/res/values/strings.xml" | head -1
}

cfg_get() {
  local demo_dir="$1" key="$2" default="$3" val=""
  if [[ -f "$demo_dir/config.yml" ]]; then
    val=$(grep -E "^${key}:" "$demo_dir/config.yml" 2>/dev/null | head -1 \
      | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//' || true)
  fi
  echo "${val:-$default}"
}

resolve_component() {
  local pkg="$1" resolved component
  resolved="$(${ADB[@]} shell cmd package resolve-activity --brief "$pkg" 2>/dev/null | tr -d '\r' | tail -n1 || true)"
  [[ -n "$resolved" ]] || return 1
  component=$(echo "$resolved" | awk '{print $NF}')
  [[ "$component" == */* ]] || return 1
  echo "$component"
}

find_pid() {
  local pkg="$1" pid
  pid="$(${ADB[@]} shell pidof -s "$pkg" 2>/dev/null | tr -d '\r' || true)"
  if [[ -n "$pid" ]]; then
    echo "$pid"
    return 0
  fi
  pid="$(${ADB[@]} shell ps -A 2>/dev/null | tr -d '\r' | awk -v p="$pkg" '$NF==p {print $2; exit}' || true)"
  [[ -n "$pid" ]] || return 1
  echo "$pid"
}

BASE_PKG="$(base_pkg)"
BASE_NAME="$(base_name)"
[[ -n "$BASE_PKG" ]] || die "Could not detect base package"
[[ -n "$BASE_NAME" ]] || die "Could not detect base app name"

DEMOS=()
while IFS= read -r demo; do
  DEMOS+=("$demo")
done < <(find "$APP_ROOT/tests/demos" -mindepth 1 -maxdepth 1 -type d | sort)
[[ ${#DEMOS[@]} -gt 0 ]] || die "No demos found under $APP_ROOT/tests/demos"

if [[ "$NO_BUILD" -eq 0 ]]; then
  info "Building demo APKs"
  for demo in "${DEMOS[@]}"; do
    info "Build demo: $(basename "$demo")"
    "$BUILD_SCRIPT" "$demo" --output "$OUTPUT_DIR"
  done
else
  info "Skipping build step (--no-build)"
fi

printf '\nVerification Results\n'
printf '%s\n' "--------------------------------------------------------------------------------"

FAIL=0
for demo in "${DEMOS[@]}"; do
  demo_name="$(basename "$demo")"
  pkg="$(cfg_get "$demo" package "$BASE_PKG")"
  app_name="$(cfg_get "$demo" app-name "$BASE_NAME")"
  apk="$OUTPUT_DIR/${app_name}.apk"

  echo "demo=$demo_name"
  echo "apk=$apk"
  echo "package=$pkg"

  if [[ ! -f "$apk" ]]; then
    echo "install=FAIL (apk not found)"
    echo "launch=SKIPPED"
    echo "running=NO"
    echo "pid=-"
    echo "--------------------------------------------------------------------------------"
    FAIL=1
    continue
  fi

  install_out="$(${ADB[@]} install -r "$apk" 2>&1 | tr -d '\r' || true)"
  if echo "$install_out" | grep -q "Success"; then
    echo "install=OK"
  else
    echo "install=FAIL"
    echo "install_output=$install_out"
    echo "launch=SKIPPED"
    echo "running=NO"
    echo "pid=-"
    echo "--------------------------------------------------------------------------------"
    FAIL=1
    continue
  fi

  component="$(resolve_component "$pkg" || true)"
  if [[ -z "$component" ]]; then
    echo "launch=FAIL (could not resolve launcher activity)"
    echo "component=-"
    echo "running=NO"
    echo "pid=-"
    echo "--------------------------------------------------------------------------------"
    FAIL=1
    continue
  fi

  launch_out="$(${ADB[@]} shell am start -W -n "$component" 2>&1 | tr -d '\r' || true)"
  if echo "$launch_out" | grep -Eq 'Status:\s*ok|cmp='; then
    echo "launch=OK"
  else
    echo "launch=FAIL"
    echo "launch_output=$launch_out"
    echo "component=$component"
    echo "running=NO"
    echo "pid=-"
    echo "--------------------------------------------------------------------------------"
    FAIL=1
    continue
  fi

  pid="$(find_pid "$pkg" || true)"
  if [[ -n "$pid" ]]; then
    echo "component=$component"
    echo "running=YES"
    echo "pid=$pid"
  else
    echo "component=$component"
    echo "running=NO"
    echo "pid=-"
    FAIL=1
  fi

  echo "--------------------------------------------------------------------------------"
done

if [[ "$FAIL" -ne 0 ]]; then
  die "One or more demos failed verification"
fi

info "All demos installed, launched, and verified running with PID"
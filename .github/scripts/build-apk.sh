#!/usr/bin/env bash
# build-apk.sh — Build a customised APK from a demo folder.
#
# Usage:
#   .github/scripts/build-apk.sh <demo-folder> [--output <dir>]
#
# The original repo is NEVER modified — all work happens in a temp copy.

set -euo pipefail

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "• $*"; }

# ── parse arguments ─────────────────────────────────────────────────────────
DEMO_DIR="" OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    -*)       die "Unknown option: $1" ;;
    *)        DEMO_DIR="$1"; shift ;;
  esac
done

[[ -n "$DEMO_DIR" ]] || die "Usage: $0 <demo-folder> [--output <dir>]"
[[ -d "$DEMO_DIR" ]] || die "Demo directory not found: $DEMO_DIR"
DEMO_DIR="$(cd "$DEMO_DIR" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[[ -f "$APP_ROOT/gradlew" ]] || die "Cannot find gradlew in $APP_ROOT"

OUTPUT_DIR="${OUTPUT_DIR:-$PWD}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# ── read config ─────────────────────────────────────────────────────────────
cfg_get() {                        # $1=key  $2=default
  local val=""
  if [[ -f "$DEMO_DIR/config.yml" ]]; then
    val=$(grep -E "^${1}:" "$DEMO_DIR/config.yml" 2>/dev/null | head -1 \
      | sed "s/^${1}:[[:space:]]*//" | sed 's/[[:space:]]*$//' || true)
  fi
  echo "${val:-$2}"
}

BASE_PKG=$(grep -oE 'namespace\s*=\s*"[^"]+"' "$APP_ROOT/app/build.gradle.kts" \
  | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
BASE_NAME=$(sed -nE 's/.*<string name="app_name">(.*)<\/string>.*/\1/p' \
  "$APP_ROOT/app/src/main/res/values/strings.xml" | head -1)
[[ -n "$BASE_PKG" ]]  || die "Could not detect package"
[[ -n "$BASE_NAME" ]] || die "Could not detect app name"

PACKAGE=$(cfg_get "package"  "$BASE_PKG")
APP_NAME=$(cfg_get "app-name" "$BASE_NAME")

info "Demo     : $DEMO_DIR"
info "Package  : $PACKAGE"
info "App name : $APP_NAME"

# ── disposable working copy (repo is never touched) ────────────────────────
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

rsync -a --exclude='.git' --exclude='build' --exclude='*.apk' \
  --exclude='.gradle' --exclude='tests' "$APP_ROOT/" "$WORK/"

W_GRADLE="$WORK/app/build.gradle.kts"
W_STRINGS="$WORK/app/src/main/res/values/strings.xml"
W_MANIFEST="$WORK/app/src/main/AndroidManifest.xml"
W_XML="$WORK/app/src/main/res/xml"
W_JAVA="$WORK/app/src/main/java/$(echo "$BASE_PKG" | tr '.' '/')"

# ── package rename ──────────────────────────────────────────────────────────
if [[ "$PACKAGE" != "$BASE_PKG" ]]; then
  NEW_JAVA="$WORK/app/src/main/java/$(echo "$PACKAGE" | tr '.' '/')"
  info "Rewriting package → $PACKAGE"
  sed -i.bak -e "s|namespace = \"$BASE_PKG\"|namespace = \"$PACKAGE\"|" \
             -e "s|applicationId = \"$BASE_PKG\"|applicationId = \"$PACKAGE\"|" "$W_GRADLE"
  rm -f "$W_GRADLE.bak"
  # Copy via external temp to avoid recursion when NEW_JAVA is inside W_JAVA
  TMP_PKG=$(mktemp -d)
  cp -a "$W_JAVA/." "$TMP_PKG/"
  rm -rf "$W_JAVA"
  mkdir -p "$NEW_JAVA"
  cp -a "$TMP_PKG/." "$NEW_JAVA/"
  rm -rf "$TMP_PKG"
  find "$NEW_JAVA" -name '*.kt' -exec sed -i.bak \
    -e "s|package $BASE_PKG|package $PACKAGE|g" \
    -e "s|import $BASE_PKG|import $PACKAGE|g" {} +
  find "$NEW_JAVA" -name '*.bak' -delete
  W_JAVA="$NEW_JAVA"
fi

# ── app-name override ──────────────────────────────────────────────────────
if [[ "$APP_NAME" != "$BASE_NAME" ]]; then
  info "Setting app name → $APP_NAME"
  sed -i.bak "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">$APP_NAME</string>|" "$W_STRINGS"
  rm -f "$W_STRINGS.bak"
fi

# ── overlay demo files ──────────────────────────────────────────────────────
overlay() {
  [[ -f "$1" ]] || return 0
  mkdir -p "$(dirname "$2")"
  cp -f "$1" "$2"
  if [[ "$PACKAGE" != "$BASE_PKG" && "$1" == *.kt ]]; then
    sed -i.bak -e "s|package $BASE_PKG|package $PACKAGE|g" \
               -e "s|import $BASE_PKG|import $PACKAGE|g" "$2"
    rm -f "$2.bak"
  fi
  info "Copied $(basename "$1")"
}

overlay "$DEMO_DIR/MastgTest.kt"               "$W_JAVA/MastgTest.kt"
overlay "$DEMO_DIR/MainActivity.kt"             "$W_JAVA/MainActivity.kt"
overlay "$DEMO_DIR/MastgTestWebView.kt"         "$W_JAVA/MastgTestWebView.kt"
overlay "$DEMO_DIR/AndroidManifest.xml"          "$W_MANIFEST"
overlay "$DEMO_DIR/filepaths.xml"                "$W_XML/filepaths.xml"
overlay "$DEMO_DIR/network_security_config.xml"  "$W_XML/network_security_config.xml"
overlay "$DEMO_DIR/backup_rules.xml"             "$W_XML/backup_rules.xml"
overlay "$DEMO_DIR/data_extraction_rules.xml"    "$W_XML/data_extraction_rules.xml"

# .proto files
shopt -s nullglob
for pf in "$DEMO_DIR"/*.proto; do
  mkdir -p "$WORK/app/src/main/proto"
  cp -f "$pf" "$WORK/app/src/main/proto/"
  info "Copied $(basename "$pf")"
done
shopt -u nullglob

# build.gradle.kts fragments
for kind in plugins sections libs; do
  frag="$DEMO_DIR/build.gradle.kts.$kind"
  [[ -f "$frag" ]] || continue
  marker="// ADD_$(echo "$kind" | tr '[:lower:]' '[:upper:]')_HERE"
  awk -v m="$marker" -v c="$(cat "$frag")" '$0 ~ m {print c; next} {print}' \
    "$W_GRADLE" > "$W_GRADLE.tmp" && mv "$W_GRADLE.tmp" "$W_GRADLE"
  info "Inserted build.gradle.kts.$kind"
done

# ── build ────────────────────────────────────────────────────────────────────
info "Building APK…"
cd "$WORK"
grep -q 'org.gradle.caching=true' gradle.properties 2>/dev/null || \
  printf '\norg.gradle.caching=true\norg.gradle.configuration-cache=true\n' >> gradle.properties
./gradlew assembleDebug --stacktrace

APK="$WORK/app/build/outputs/apk/debug/app-debug.apk"
[[ -f "$APK" ]] || die "APK not found"

OUTPUT_APK="$OUTPUT_DIR/${APP_NAME}.apk"
cp "$APK" "$OUTPUT_APK"
info "APK ready → $OUTPUT_APK"

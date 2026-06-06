#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage:
  $0 <demo-folder> [--output <dir>]

Builds a customised debug APK from a demo folder without modifying the repo.

Arguments:
  <demo-folder>       Demo folder containing optional override files.

Options:
  --output <dir>      Directory where the APK will be written.
  -h, --help          Show this help message.

Supported demo files:
  config.yml
  MastgTest.kt
  MainActivity.kt
  MastgTestWebView.kt
  AndroidManifest.xml
  filepaths.xml
  network_security_config.xml
  backup_rules.xml
  data_extraction_rules.xml
  proguard-rules.pro
  icon.png
  *.proto
  build.gradle.kts.plugins
  build.gradle.kts.sections
  build.gradle.kts.libs
  build.gradle.kts.build

config.yml keys:
  package:            Override application package.
  app-name:           Override launcher app name.
EOF
}
die()   { usage; echo "ERROR: $*" >&2; exit 1; }
info()  { echo "• $*"; }

if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi

# ── parse arguments ─────────────────────────────────────────────────────────
DEMO_DIR="" OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --output) [[ $# -ge 2 ]] || die "Missing value for --output"; OUTPUT_DIR="$2"; shift 2 ;;
    -*)       die "Unknown option: $1" ;;
    *)        DEMO_DIR="$1"; shift ;;
  esac
done

[[ -n "$DEMO_DIR" ]] || die "Missing demo folder"
[[ -d "$DEMO_DIR" ]] || die "Demo directory not found: $DEMO_DIR"
DEMO_DIR="$(realpath "$DEMO_DIR")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
[[ -f "$APP_ROOT/gradlew" ]] || die "Cannot find gradlew in $APP_ROOT"

OUTPUT_DIR="${OUTPUT_DIR:-$PWD}"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"
mkdir -p "$OUTPUT_DIR"

# ── read config ─────────────────────────────────────────────────────────────
# `cfg_get()`:
# When you call `cfg_get "package" "$BASE_PKG"`, it reads the YAML config file for the line 
# starting with `package:`, and if not found, returns `$BASE_PKG` instead.

cfg_get() {
  local config_key="$1"
  local default_value="$2"
  local val=""
  if [[ -f "$DEMO_DIR/config.yml" ]]; then
      val=$(grep -E "^${config_key}:" "$DEMO_DIR/config.yml" 2>/dev/null | head -1 \
        | sed "s/^${config_key}:[[:space:]]*//" | sed 's/[[:space:]]*$//' || true)
  fi
  echo "${val:-${default_value}}"
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
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_PKG"' EXIT
WORK_DIR="$TMP_DIR/work"
mkdir -p "$WORK_DIR"

rsync -a --exclude='.git' --exclude='build' --exclude='*.apk' \
  --exclude='.gradle' --exclude='tests' "$APP_ROOT/" "$WORK_DIR/"

W_GRADLE="$WORK_DIR/app/build.gradle.kts"
W_STRINGS="$WORK_DIR/app/src/main/res/values/strings.xml"
W_MANIFEST="$WORK_DIR/app/src/main/AndroidManifest.xml"
W_XML="$WORK_DIR/app/src/main/res/xml"
W_JAVA="$WORK_DIR/app/src/main/java/$(echo "$BASE_PKG" | tr '.' '/')"
W_DRAWABLE="$WORK_DIR/app/src/main/res/drawable"

# ── package rename ──────────────────────────────────────────────────────────
if [[ "$PACKAGE" != "$BASE_PKG" ]]; then
  NEW_JAVA="$WORK_DIR/app/src/main/java/$(echo "$PACKAGE" | tr '.' '/')"
  info "Rewriting package → $PACKAGE"
  "${SED_INPLACE[@]}" -e "s|namespace = \"$BASE_PKG\"|namespace = \"$PACKAGE\"|" \
            -e "s|applicationId = \"$BASE_PKG\"|applicationId = \"$PACKAGE\"|" "$W_GRADLE"
  # Copy via external temp to avoid recursion when NEW_JAVA is inside W_JAVA
  TMP_PKG=$(TMPDIR="$TMP_DIR" mktemp -d)
  cp -a "$W_JAVA/." "$TMP_PKG/"
  rm -rf "$W_JAVA"
  mkdir -p "$NEW_JAVA"
  cp -a "$TMP_PKG/." "$NEW_JAVA/"
  rm -rf "$TMP_PKG"
  find "$NEW_JAVA" -name '*.kt' -exec "${SED_INPLACE[@]}" \
    -e "s|package $BASE_PKG|package $PACKAGE|g" \
    -e "s|import $BASE_PKG|import $PACKAGE|g" {} +
  W_JAVA="$NEW_JAVA"
fi

# ── app-name override ──────────────────────────────────────────────────────
if [[ "$APP_NAME" != "$BASE_NAME" ]]; then
  info "Setting app name → $APP_NAME"
  "${SED_INPLACE[@]}" "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">$APP_NAME</string>|" "$W_STRINGS"
fi

# ── overlay demo files ──────────────────────────────────────────────────────
overlay() {
  local source="$1"
  local destination="$2"
  [[ -f "${source}" ]] || return 0
  mkdir -p "$(dirname "${destination}")"
  cp -f "${source}" "${destination}"
  if [[ "$PACKAGE" != "$BASE_PKG" ]]; then
    if [[ "${source}" == *.kt ]]; then
      "${SED_INPLACE[@]}" -e "s|package $BASE_PKG|package $PACKAGE|g" \
                 -e "s|import $BASE_PKG|import $PACKAGE|g" "${destination}"
    elif [[ "${source}" == *.pro ]]; then
      "${SED_INPLACE[@]}" "s|${BASE_PKG}|${PACKAGE}|g" "${destination}"
    fi
  fi
  info "Overlayed $(basename "$1")"
}

overlay "$DEMO_DIR/MastgTest.kt"               "$W_JAVA/MastgTest.kt"
overlay "$DEMO_DIR/MainActivity.kt"             "$W_JAVA/MainActivity.kt"
overlay "$DEMO_DIR/MastgTestWebView.kt"         "$W_JAVA/MastgTestWebView.kt"
overlay "$DEMO_DIR/AndroidManifest.xml"          "$W_MANIFEST"
overlay "$DEMO_DIR/filepaths.xml"                "$W_XML/filepaths.xml"
overlay "$DEMO_DIR/network_security_config.xml"  "$W_XML/network_security_config.xml"
overlay "$DEMO_DIR/backup_rules.xml"             "$W_XML/backup_rules.xml"
overlay "$DEMO_DIR/data_extraction_rules.xml"    "$W_XML/data_extraction_rules.xml"
overlay "$DEMO_DIR/proguard-rules.pro"           "$WORK_DIR/app/proguard-rules.pro"

# app icon ── icon.png (optional)
# Drop one PNG in the demo folder. The base app's mipmap-anydpi-v26/ic_launcher*.xml
# already references @drawable/ic_launcher_icon_fg with an 18dp safe-zone inset.
# The script just swaps that drawable to the supplied PNG; no XML writing needed.
# minSdk 29 guarantees the anydpi adaptive icon always wins over density buckets.
if [[ -f "$DEMO_DIR/icon.png" ]]; then
  info "Using icon.png for launcher icon"
  mkdir -p "$W_DRAWABLE"
  rm -f "$W_DRAWABLE/ic_launcher_icon_fg.xml"
  cp -f "$DEMO_DIR/icon.png" "$W_DRAWABLE/ic_launcher_icon_fg.png"
fi

# .proto files
shopt -s nullglob
for pf in "$DEMO_DIR"/*.proto; do
  mkdir -p "$WORK_DIR/app/src/main/proto"
  cp -f "$pf" "$WORK_DIR/app/src/main/proto/"
  info "Copied $(basename "$pf")"
done
shopt -u nullglob

# build.gradle.kts fragments
for kind in plugins sections libs build; do
  frag="$DEMO_DIR/build.gradle.kts.$kind"
  [[ -f "$frag" ]] || continue
  marker="// ADD_$(echo "$kind" | tr '[:lower:]' '[:upper:]')_HERE"
  # Use getline to read fragment file directly — avoids BSD awk's ban on
  # newlines inside -v variable assignments (multiline fragments would silently
  # disappear with the -v approach on macOS).
  awk -v m="$marker" -v f="$frag" '
    $0 ~ m {
      while ((getline line < f) > 0) print line
      close(f)
      next
    }
    { print }
  ' "$W_GRADLE" > "$W_GRADLE.tmp" && mv "$W_GRADLE.tmp" "$W_GRADLE"
  info "Inserted build.gradle.kts.$kind"
done

# ── build ────────────────────────────────────────────────────────────────────
info "Building APK…"
cd "$WORK_DIR"
grep -q 'org.gradle.caching=true' gradle.properties 2>/dev/null || \
  printf '\norg.gradle.caching=true\norg.gradle.configuration-cache=true\n' >> gradle.properties
./gradlew assembleDebug --stacktrace

APK="$WORK_DIR/app/build/outputs/apk/debug/app-debug.apk"
[[ -f "$APK" ]] || die "APK not found"

OUTPUT_APK="$OUTPUT_DIR/${APP_NAME}.apk"
cp -f "$APK" "$OUTPUT_APK"
info "APK ready → $OUTPUT_APK"

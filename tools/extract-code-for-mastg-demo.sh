#!/bin/bash

pushd "$(dirname "$0")/.." > /dev/null || exit

CLASS_NAMES=("org.owasp.mastestapp.MastgTest" "org.owasp.mastestapp.MastgTestWebView" "org.owasp.mastestapp.MainActivityKt")
OUTPUT_DIR="output"
TEMP_APKTOOL_DIR="$OUTPUT_DIR/temp_apktool_output"
TEMP_APK="$OUTPUT_DIR/temp_base.apk"
# APK_BUILD_PATH="./app/build/outputs/apk/debug/app-debug.apk"

# Create a temporary directory for jadx output
TEMP_JADX_OUTPUT_DIR="$OUTPUT_DIR/temp_jadx_output"

# Build Android Studio project (uses APK_BUILD_PATH)
# gradle assembleDebug

# Create temporary directories for output
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_APKTOOL_DIR"
mkdir -p "$TEMP_JADX_OUTPUT_DIR"

# Copy the APK to the temporary location
# cp "$APK_BUILD_PATH" "$TEMP_APK"

# Get the APK path from the device
APK_PATH=$(adb shell pm path org.owasp.mastestapp | sed 's/package://')

# Pull the APK to a temporary location
adb pull "$APK_PATH" "$TEMP_APK"

# Use apktool to extract the AndroidManifest.xml
apktool d -s -f -p "$TEMP_APKTOOL_DIR/cache" -o "$TEMP_APKTOOL_DIR" "$TEMP_APK"

for CLASS_NAME in "${CLASS_NAMES[@]}"; do

    # Run jadx on the specific class
    jadx --single-class "$CLASS_NAME" -d "$TEMP_JADX_OUTPUT_DIR" "$TEMP_APK"

    # Get the simple class name without package
    SIMPLE_CLASS_NAME=$(echo "$CLASS_NAME" | sed 's/.*\.//')

    # Copy the specific class file to the output directory
    JAVA_FILE="$TEMP_JADX_OUTPUT_DIR/sources/org/owasp/mastestapp/${SIMPLE_CLASS_NAME}.java"
    if [ -f "$JAVA_FILE" ]; then
        cp "$JAVA_FILE" "$OUTPUT_DIR/${SIMPLE_CLASS_NAME}_reversed.java"
        echo "Copied $JAVA_FILE to $OUTPUT_DIR"
    else
        echo "File $JAVA_FILE not found!"
    fi

    # We must rename the MainActivityKt to MainActivity because the class is named MainActivityKt in the decompiled code
    if [ "$SIMPLE_CLASS_NAME" == "MainActivityKt" ]; then
        SIMPLE_CLASS_NAME="MainActivity"
    fi

    cp app/src/main/java/org/owasp/mastestapp/${SIMPLE_CLASS_NAME}.kt "$OUTPUT_DIR/${SIMPLE_CLASS_NAME}.kt"

done

# Use jadx to extract the AndroidManifest.xml
jadx --no-src -d "$TEMP_JADX_OUTPUT_DIR" "$TEMP_APK"

# Copy the AndroidManifest.xml to the output directory and rename it
MANIFEST_FILE="$TEMP_JADX_OUTPUT_DIR/resources/AndroidManifest.xml"
if [ -f "$MANIFEST_FILE" ]; then
    cp "$MANIFEST_FILE" "$OUTPUT_DIR/AndroidManifest_reversed.xml"
    echo "Copied $MANIFEST_FILE to $OUTPUT_DIR/AndroidManifest_reversed.xml"
else
    echo "File $MANIFEST_FILE not found!"
fi

# Copy the original AndroidManifest.xml and MastgTest.kt to the output directory
cp app/src/main/AndroidManifest.xml "$OUTPUT_DIR/AndroidManifest.xml"

# Clean up temporary files
rm -rf "$TEMP_JADX_OUTPUT_DIR" "$TEMP_APKTOOL_DIR"

popd > /dev/null || exit

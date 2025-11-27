# MASTestApp for Android

## Overview

**MASTestApp** is an Android application written in Kotlin. Contributors can easily create and test new MASTG demos, ensuring that the static and dynamic analysis processes are properly documented and reproducible.

The app is intentionally simple, offering three essential files:
1. `MainActivity.kt` - Contains the default UI, which should not be modified.
2. `AndroidManifest.xml` - Contains placeholders for additional things that may be needed.
3. `MastgTest.kt` - Contains one function. This file is intended to be modified by users to create new MASTG demos but should not be modified in the original repository.

Contributors must copy the final modified `MastgTest.kt` file to their demo folder in the OWASP MASTG repository under the corresponding `demos/MASTG-DEMO-XXXX`.

## Instructions

### Create a New Demo in the MASTG

Create a new folder in the MASTG repository under the corresponding `demos/MASTG-DEMO-XXXX` following the [guidelines](https://docs.google.com/document/d/1EMsVdfrDBAu0gmjWAUEs60q-fWaOmDB5oecY9d9pOlg/edit#heading=h.y294y561hx14)

### Clone the MASTestApp Repository

Clone the app repository and open it in Android Studio.

```sh
git clone https://github.com/cpholguera/MASTestApp-Android.git
```

### Add Your Demo Code

- Edit `MastgTest.kt` to implement your demo.
- If applicable, modify the `AndroidManifest.xml` to add necessary permissions or components.
- Build the app and **test it** on the Android emulator or a physical device

### Customize Build Configuration (Optional)

Demos may include additional files to customize the `build.gradle.kts` configuration. The automation will merge these into the mas-app-android `app/build.gradle.kts` file:

- **`build.gradle.kts.libs`**: Add dependencies to the `dependencies` block. The content will be inserted at the `// ADD_LIBS_HERE` placeholder.
- **`build.gradle.kts.plugins`**: Add plugins to the `plugins` block. The content will be inserted at the `// ADD_PLUGINS_HERE` placeholder.
- **`build.gradle.kts.sections`**: Add custom sections (e.g., `protobuf {}` configuration). The content will be inserted at the `// ADD_SECTIONS_HERE` placeholder.

### Include Proto Files (Optional)

If your demo requires Protocol Buffer files, include `.proto` files in your demo folder. The automation will copy them to `app/src/main/proto/*.proto`.

### Run the Extraction Script

Install **jadx** and **apktool** and ensure they're available in your path.

Launch the app in the emulator and run the provided script:

```sh
./tools/extract-code-for-mastg-demo.sh
```

The output will be:

```sh
output/
├── MastgTest.kt
├── MastgTest_reversed.java
├── AndroidManifest.xml
└── AndroidManifest_reversed.xml
```

### If Your Demo Requires Static Analysis (Reverse Engineering)

Run your SAST rules on the `_reversed` files and ensure they work as expected.

### If Your Demo Requires Dynamic Analysis

Use the Android emulator or a physical device and run your dynamic scripts.

## Finalize Your Demo

Once everything works fine, copy the relevant files from the output folder to the demo folder in the MASTG repository. It should look like this:

```sh
owasp-mastg/demos/MASTG-DEMO-XXXX/
├── MastgTest.kt
├── MastgTest_reversed.java
├── AndroidManifest.xml
├── AndroidManifest_reversed.xml
├── MASTG-DEMO-XXXX.md
├── output.txt
├── run.sh
├── build.gradle.kts.libs      # (optional) dependencies to add
├── build.gradle.kts.plugins   # (optional) plugins to add
├── build.gradle.kts.sections  # (optional) custom sections to add
└── *.proto                    # (optional) Protocol Buffer files
```

Finalize your demo by adding a `MASTG-DEMO-XXXX.md` file, tweaking the `run.sh` script, and adding the relevant output files.

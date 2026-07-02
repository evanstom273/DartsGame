# Android setup

Use these local paths in Godot:

- Android SDK Path: `C:\Users\evans\AppData\Local\Android\Sdk`
- Java SDK Path: `C:\Program Files\Java\jdk-17`

Godot setup:

1. Open `Editor > Editor Settings > Export > Android`.
2. Set the Android SDK and Java SDK paths above.
3. Open `Editor > Manage Export Templates` and install the matching export templates for your Godot version.
4. Open `Project > Export`, select the Android preset, and export to `build/android/darts-game.apk`.

Android Studio setup:

1. Open `Android Studio > SDK Manager > SDK Tools`.
2. Install `Android SDK Command-line Tools (latest)` if it is not already installed.
3. Make sure `Android SDK Platform-Tools` is installed for `adb`.

Optional PowerShell environment setup:

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")
```

After changing environment variables, restart PowerShell, Godot, and Android Studio.

## Reliable rebuild command

Windows can lock the previous APK while Android tools, Explorer, or device install are still touching it. If Godot exports to the same filename again, `apksigner` can fail when it tries to replace that file.

Use the export helper to generate a fresh timestamped APK every time:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\tools\export_android.ps1
```

To export and install to a connected phone:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\tools\export_android.ps1 -Install
```

Output APKs go to `builds\android\exports\`.

# Building Shield Tools

Install JDK 17, Android SDK 35, Gradle, and Apktool. Obtain Rootfan's Shield Tools 1.4 APK from the linked XDA thread, then run:

```powershell
.\scripts\build-app.ps1 -BaseApk .\Shield_Tools_V1_4.apk -OutputApk .\Shield-Tools-1.5-unsigned.apk
```

Use `-Gradle path\to\gradle` if Gradle is not on `PATH`. The script builds the Java overlay from source, applies the tracked base-APK patch, and creates an unsigned APK. Sign it with your own Android signing key.

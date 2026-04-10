# Update the app launcher icons
Write-Host "Generating App Icons..."
& "C:\Users\samee\Downloads\flutter_windows_3.41.4-stable\flutter\bin\flutter.bat" pub run flutter_launcher_icons

# Build the release APK
Write-Host "Building Release APK..."
& "C:\Users\samee\Downloads\flutter_windows_3.41.4-stable\flutter\bin\flutter.bat" build apk --release

# Check if the APK was generated successfully
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    # Move to Desktop
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $destination = Join-Path $desktopPath "congrowing.apk"
    Move-Item -Path $apkPath -Destination $destination -Force
    Write-Host "Successfully built and copied the APK to your Desktop at: $destination"
} else {
    Write-Host "Failed to build the APK."
}

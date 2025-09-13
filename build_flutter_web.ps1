$AppSrc = "app_source"
$AppDst = "app"

# 1. Delete old build
if (Test-Path $AppDst) {
    Remove-Item $AppDst -Recurse -Force
}

# 2. Build Flutter
Set-Location $AppSrc
flutter clean
flutter pub get
flutter build web --base-href /app/ --pwa-strategy=none
Set-Location ..

# 3. Copy new build
New-Item -ItemType Directory -Force -Path $AppDst | Out-Null
Copy-Item "$AppSrc\build\web\*" $AppDst -Recurse -Force

Write-Host "✅ Flutter web app built and deployed to /app/"

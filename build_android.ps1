# 百物語 Android AABビルドスクリプト
# 実行: powershell -ExecutionPolicy Bypass -File O:\Hyaku\build_android.ps1

$flutter = "C:\Users\ryoba\flutter\bin\flutter.bat"
$appDir = "O:\Hyaku\app"

Write-Host "=== 百物語 Android Release Build ===" -ForegroundColor Cyan

# 依存関係の更新
Write-Host "`n[1/3] pub get..." -ForegroundColor Yellow
& $flutter pub get --directory $appDir

# AABビルド
Write-Host "`n[2/3] Building AAB..." -ForegroundColor Yellow
& $flutter build appbundle --release --directory $appDir

# 出力確認
$aabPath = "$appDir\build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aabPath) {
    $size = (Get-Item $aabPath).Length / 1MB
    Write-Host "`n[3/3] Build SUCCESS!" -ForegroundColor Green
    Write-Host "AAB: $aabPath" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($size, 1)) MB" -ForegroundColor Green
    Write-Host "`n次のステップ: Google Play Console にアップロード" -ForegroundColor Cyan
} else {
    Write-Host "`n[ERROR] AABが見つかりません" -ForegroundColor Red
}

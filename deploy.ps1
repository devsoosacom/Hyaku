# 百物語 Deploy + Regression Test
# 使い方: .\deploy.ps1            (ビルド→デプロイ→テスト)
#         .\deploy.ps1 -SkipBuild  (デプロイ→テスト のみ)
#         .\deploy.ps1 -SkipTests  (ビルド→デプロイ のみ)

param(
    [switch]$SkipBuild,
    [switch]$SkipTests
)

$NODE    = 'O:\ai_stock\venv\Lib\site-packages\playwright\driver\node.exe'
$FIREBASE = 'O:\Program Files (x86)\Nodist\bin\node_modules\firebase-tools\lib\bin\firebase.js'
$FLUTTER  = 'C:\Users\ryoba\flutter\bin\flutter.bat'
$PYTHON   = 'C:\Users\ryoba\Python312\python.exe'
$APP_DIR  = 'O:\Hyaku\app'
$TEST     = 'O:\Hyaku\tests\regression.py'

Set-Location $APP_DIR

# ---- Sitemap ----
Write-Host "`n[0/3] サイトマップ生成中..." -ForegroundColor Cyan
& $PYTHON 'O:\Hyaku\generate_sitemap.py'
if ($LASTEXITCODE -ne 0) {
    Write-Host "サイトマップ生成失敗（続行）" -ForegroundColor Yellow
}

# ---- Build ----
if (-not $SkipBuild) {
    Write-Host "`n[1/3] Flutter ビルド中..." -ForegroundColor Cyan
    & $FLUTTER build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ビルド失敗" -ForegroundColor Red
        exit 1
    }
    Write-Host "ビルド完了" -ForegroundColor Green
}

# ---- Deploy ----
Write-Host "`n[2/3] Firebase デプロイ中..." -ForegroundColor Cyan
& $NODE $FIREBASE deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "デプロイ失敗" -ForegroundColor Red
    exit 1
}
Write-Host "デプロイ完了" -ForegroundColor Green

# ---- Regression Tests ----
if (-not $SkipTests) {
    Write-Host "`n[3/3] CDN反映待機 (10秒)..." -ForegroundColor Cyan
    Start-Sleep 10

    Write-Host "リグレッションテスト実行中..." -ForegroundColor Cyan
    & $PYTHON $TEST
    $code = $LASTEXITCODE

    if ($code -eq 0) {
        Write-Host "`n全テスト PASSED" -ForegroundColor Green
    } else {
        Write-Host "`n一部テスト FAILED" -ForegroundColor Red
    }
    exit $code
}

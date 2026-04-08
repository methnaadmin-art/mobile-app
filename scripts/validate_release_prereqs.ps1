$ErrorActionPreference = 'Stop'

Write-Host 'Validating release prerequisites...' -ForegroundColor Cyan

$repoRoot = Split-Path -Parent $PSScriptRoot
$androidKeyProps = Join-Path $repoRoot 'android\key.properties'
$releaseEnv = Join-Path $repoRoot 'env\release.json'
$podfile = Join-Path $repoRoot 'ios\Podfile'

$failed = $false

if (-not (Test-Path $androidKeyProps)) {
    Write-Host 'ERROR: Missing android/key.properties' -ForegroundColor Red
    $failed = $true
} else {
    $content = Get-Content $androidKeyProps -Raw
    foreach ($required in @('storePassword=', 'keyPassword=', 'keyAlias=', 'storeFile=')) {
        if ($content -notmatch [Regex]::Escape($required)) {
            Write-Host "ERROR: android/key.properties missing $required" -ForegroundColor Red
            $failed = $true
        }
    }
}

if (-not (Test-Path $releaseEnv)) {
    Write-Host 'ERROR: Missing env/release.json (copy from env/release.example.json)' -ForegroundColor Red
    $failed = $true
} else {
    $json = Get-Content $releaseEnv -Raw | ConvertFrom-Json
    foreach ($k in @(
        'API_BASE_URL',
        'SOCKET_URL',
        'STRIPE_PUBLISHABLE_KEY',
        'STRIPE_MERCHANT_IDENTIFIER',
        'STRIPE_MERCHANT_COUNTRY_CODE',
        'STRIPE_CURRENCY_CODE',
        'STRIPE_TEST_MODE'
    )) {
        if (-not $json.$k) {
            Write-Host "ERROR: env/release.json missing key '$k'" -ForegroundColor Red
            $failed = $true
        }
    }
}

if (-not (Test-Path $podfile)) {
    Write-Host 'ERROR: Missing ios/Podfile' -ForegroundColor Red
    $failed = $true
}

if ($failed) {
    Write-Host 'Release prerequisite validation failed.' -ForegroundColor Red
    exit 1
}

Write-Host 'Release prerequisites look good.' -ForegroundColor Green
exit 0

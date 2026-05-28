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
        'WEBSITE_URL',
        'PRIVACY_POLICY_URL',
        'TERMS_URL',
        'SUPPORT_EMAIL'
    )) {
        if (-not $json.$k) {
            Write-Host "ERROR: env/release.json missing key '$k'" -ForegroundColor Red
            $failed = $true
        }
    }

    $playBillingKeys = @(
        'PLAY_BILLING_PREMIUM',
        'PLAY_BILLING_PREMIUM_MONTHLY',
        'PLAY_BILLING_PREMIUM_YEARLY',
        'PLAY_BILLING_GOLD'
    )
    $configuredPlayBillingProducts = @(
        $playBillingKeys |
            ForEach-Object {
                $value = $json.$_
                if ($value) { $value }
            }
    ) | Where-Object { $_ }

    if (-not $configuredPlayBillingProducts.Count) {
        Write-Host 'WARNING: No Play Billing product IDs were found in env/release.json.' -ForegroundColor Yellow
        Write-Host '         Android premium plans must come from backend plan metadata or these release keys before publishing.' -ForegroundColor Yellow
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

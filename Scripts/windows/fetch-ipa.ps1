param(
    [string]$Repo = "",
    [string]$ArtifactName = "conduit-iOS-device-unsigned",
    [string]$OutDir = (Join-Path (Get-Location) "artifacts")
)

$ErrorActionPreference = "Stop"

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing command '$name'. Install GitHub CLI from https://cli.github.com and run 'gh auth login'."
    }
}

function Find-Ipa($root) {
    $preferred = Get-ChildItem -Path $root -Recurse -Filter "conduit-unsigned.ipa" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($preferred) { return $preferred }

    $legacy = Get-ChildItem -Path $root -Recurse -Filter "ProductivityTracker-unsigned.ipa" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($legacy) {
        Write-Host "Note: using legacy IPA name ProductivityTracker-unsigned.ipa (conduit-unsigned.ipa not found)."
        return $legacy
    }

    return $null
}

Require-Command gh

if (-not $Repo) {
    $Repo = (gh repo view --json nameWithOwner --jq .nameWithOwner)
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Looking up latest successful workflow run for $Repo ..."
$runId = gh run list --repo $Repo --workflow "iOS CI" --status success --limit 1 --json databaseId --jq ".[0].databaseId"
if (-not $runId) {
    throw "No successful iOS CI run found."
}

Write-Host "Downloading artifact $ArtifactName from run $runId ..."
try {
    gh run download $runId --repo $Repo --name $ArtifactName --dir $OutDir
} catch {
    if ($ArtifactName -eq "conduit-iOS-device-unsigned") {
        Write-Host "Artifact conduit-iOS-device-unsigned not found; trying legacy ProductivityTracker-iOS-device-unsigned ..."
        gh run download $runId --repo $Repo --name "ProductivityTracker-iOS-device-unsigned" --dir $OutDir
    } else {
        throw
    }
}

$ipa = Find-Ipa $OutDir
if (-not $ipa) {
    throw "IPA not found in artifact (expected conduit-unsigned.ipa or ProductivityTracker-unsigned.ipa)."
}

$sumFile = Get-ChildItem -Path $OutDir -Recurse -Filter "SHA256SUMS.txt" | Select-Object -First 1
$actual = (Get-FileHash -Algorithm SHA256 $ipa.FullName).Hash.ToLower()
Write-Host "IPA: $($ipa.FullName)"
Write-Host "SHA-256: $actual"

if ($sumFile) {
    $expected = ((Get-Content $sumFile.FullName | Select-Object -First 1) -split "\s+")[0].ToLower()
    if ($expected -and $expected -ne $actual) {
        throw "Checksum mismatch. Expected $expected"
    }
    Write-Host "Checksum OK."
}

Write-Host ""
Write-Host "Next (Sideloadly UI only; this script does not accept Apple credentials):"
Write-Host "1. Connect iPhone and trust the computer"
Write-Host "2. Open Sideloadly"
Write-Host "3. Select the iPhone"
Write-Host "4. Drag $($ipa.Name) into Sideloadly"
Write-Host "5. Sign in with your Apple Account locally and complete 2FA locally"
Write-Host "6. Install, then trust the developer profile on iPhone if asked"
Write-Host "7. Launch Conduit on the home screen (bundle ID com.arahe.ProductivityTracker)"

Invoke-Item $ipa.DirectoryName

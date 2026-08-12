param(
    [string]$Repo = "",
    [string]$ArtifactName = "ProductivityTracker-iOS-device-unsigned",
    [string]$OutDir = (Join-Path (Get-Location) "artifacts")
)

$ErrorActionPreference = "Stop"

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing command '$name'. Install GitHub CLI from https://cli.github.com and run 'gh auth login'."
    }
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
gh run download $runId --repo $Repo --name $ArtifactName --dir $OutDir

$ipa = Get-ChildItem -Path $OutDir -Recurse -Filter "ProductivityTracker-unsigned.ipa" | Select-Object -First 1
if (-not $ipa) {
    throw "IPA not found in artifact."
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

Invoke-Item $ipa.DirectoryName

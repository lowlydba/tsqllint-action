param(
    [Parameter()]
    [string]$Config,
    [string]$OnlyChangedFiles,
    [string]$Path
)
$files = $Path
$commentFile = Join-Path -Path $env:RUNNER_TEMP -ChildPath ".tsqllint-output.final"
$statusIcon = ":white_check_mark:"
$baseCommand = "tsqllint"
if ($Config) {
    $baseCommand = $baseCommand + " -c $Config"
}
$configCommand = $baseCommand + " -p"
$versionCommand = "tsqllint -v"

# Show config
$ConfigSetting = Invoke-Expression -Command $configCommand
$ConfigSetting = $ConfigSetting | Select-Object -Last 1
Write-Host "==================================="
Write-Host "⭐ TSQLLint Action ⭐"
Write-Host "💁 $ConfigSetting"

# Show version
$versionSetting = Invoke-Expression -Command $versionCommand
$versionSetting = $versionSetting | Select-Object -Last 1
Write-Host "💁 TSQLLint Version: $versionSetting"
Write-Host "==================================="

# Target changed files
if ($OnlyChangedFiles -eq "true" -and $env:GITHUB_HEAD_REF) {
    if ($env:GITHUB_HEAD_REF) {
        $files = git diff --diff-filter=MA --name-only origin/$env:GITHUB_BASE_REF...origin/$env:GITHUB_HEAD_REF | Select-String -Pattern ".sql" -SimpleMatch
    }
    else {
        Write-Host "No GITHUB_HEAD_REF detected for changed files, defaulting to path value."
    }
}

# Lint
$lintFiles = $files -Split("\n")

try {
    if ($Config) {
        tsqllint $files -c $Config | Out-File .tsqllint-output
    }
    else {
        tsqllint $files | Out-File .tsqllint-output
    }
}
catch {
    "Do nothing" | Out-Null
}

$tsqllint_rc = $LASTEXITCODE
"tsqllint_rc=$tsqllint_rc" >> $env:GITHUB_ENV

# Results
Get-Content -Path .tsqllint-output
$fullSummary = Get-Content -Path .tsqllint-output | Select-Object -Last 4 | ForEach-Object { $_ + "`n" }
$warningSummary = Get-Content -Path .tsqllint-output | Select-Object -Last 1
$errorSummary = Get-Content -Path .tsqllint-output | Select-Object -Last 2 | Select-Object -First 1
$numWarnings = $warningSummary.Split(" ")[0]
$numErrors = $errorSummary.Split(" ")[0]

if ($numErrors -gt 0) {
    $statusIcon = ":x:"
}
elseif ($numWarnings -gt 0) {
    $statusIcon = ":warning:"
}

$summary = $fullSummary

# Build comment
"## $statusIcon TSQLLint Summary" | Out-File $commentFile
"`n$summary" | Out-File $commentFile -Append
"`n[Detailed results.]($env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID)" | Out-File $commentFile -Append
"`n:recycle: This comment has been updated with latest results." | Out-File $commentFile -Append

exit 0
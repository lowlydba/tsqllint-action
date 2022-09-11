param(
    [Parameter()]
    [string]$Config,
    [string]$OnlyChangedFiles,
    [string]$Path
)
$commentFile = ".tsqllint-output.final"
$status = ":white_check_mark:"
$summary = "No issues found."
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
Write-Host "ℹ️ $ConfigSetting"

# Show version
$versionSetting = Invoke-Expression -Command $versionCommand
$versionSetting = $versionSetting | Select-Object -Last 1
Write-Host "ℹ️ Version: $versionSetting"
Write-Host "==================================="

# Target changed files
if ($OnlyChangedFiles -eq "true" -and $env:GITHUB_HEAD_REF) {
    $files = git diff --diff-filter=MA --name-only origin/$env:GITHUB_BASE_REF...origin/$env:GITHUB_HEAD_REF | Select-String -Pattern ".sql"
}
else {
    $files = $Path
}

# Quote filenames
$files = $('"' + ($files -join '" "') + '"')

if ($Config) {
    tsqllint $files -c $Config | Out-File .tsqllint-output
}
else {
    tsqllint $files | Out-File .tsqllint-output
}

$tsqllint_rc = $LASTEXITCODE
"tsqllint_rc=$tsqllint_rc" >> $env:GITHUB_ENV

# Results
Get-Content -Path .tsqllint-output
$fullSummary = Get-Content -Path .tsqllint-output | Select-Object -Last 4 | ForEach-Object { $_ + "`n" }

if ($tsqllint_rc -eq 1) {
    $status = ":x:"
    $summary = $fullSummary
}

# Build comment
"## $status TSQLLint Summary" | Out-File $commentFile
"`n$summary" | Out-File $commentFile -Append
"`n[Detailed results.]($env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID)" | Out-File $commentFile -Append
"`n:recycle: This comment has been updated with latest results." | Out-File $commentFile -Append

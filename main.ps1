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
Write-Host $ConfigSetting

# Show version
$versionSetting = Invoke-Expression -Command $versionCommand
$versionSetting = $versionSetting | Select-Object -Last 1
Write-Host $versionSetting

# Target changed files
if ($OnlyChangedFiles -eq "true" -and $GITHUB_READ_REF -ne "" ) {
    $files = git diff --diff-filter=MA --name-only origin/$GITHUB_BASE_REF...origin/$GITHUB_HEAD_REF | Select-String -Pattern ".sql"
}
else {
    $files = $Path
}

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

$fullSummary = Get-Content .tsqllint-output | Select-Object -Last 4
#$IssueCounts = $Summary | Select-Object -Last 2
#[int]$WarningCount = ($IssueCount | Select-Object -Last 1).Split(" ")[0]
#[int]$ErrorCount = ($IssueCount | Select-Object First 1).Split(" ")[0]

if ($tsqllint_rc -eq 1) {
    $status = ":x:"
    $summary = $fullSummary
}

# Build comment
"## $status TSQLLint Summary" | Out-File $commentFile
"$summary" | Out-File $commentFile -Append
"[Detailed results.]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)" | Out-File $commentFile -Append
":recycle: This comment has been updated with latest results." | Out-File $commentFile -Append

exit 0

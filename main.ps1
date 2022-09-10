param(
    [Parameter()]
    [string]$Config,
    [string]$OnlyChangedFiles,
    [string]$Path
)
$CommentFile = ".tsqllint-output.final"
$status = ":white_check_mark:"
$summary = "No issues found."

# Show config settings
if ($Config) {
    $ConfigSetting = tsqllint -p -c $Config
}
else {
    $ConfigSetting = tsqllint -p
}
Write-Host $ConfigSetting | Select-Object -Last 1

# Show version
tsqllint -v | Select-Object -Last 1

if ($OnlyChangedFiles -eq "true" -and $GITHUB_READ_REF -ne "" ) {
    $files = git diff --diff-filter=MA --name-only origin/$GITHUB_BASE_REF...origin/$GITHUB_HEAD_REF | Select-String -Pattern ".sql"
}
else {
    $files = $Path
}
tsqllint $files -c $Config | Out-File .tsqllint-output
$tsqllint_rc = $LASTEXITCODE
"tsqllint_rc=$tsqllint_rc" >> $env:GITHUB_ENV
Get-Content -Path .tsqllint-output

$FullSummary = Get-Content .tsqllint-output | Select-Object -Last 4
#$IssueCounts = $Summary | Select-Object -Last 2
#[int]$WarningCount = ($IssueCount | Select-Object -Last 1).Split(" ")[0]
#[int]$ErrorCount = ($IssueCount | Select-Object First 1).Split(" ")[0]

if ($tsqllint_rc -eq 1) {
    $status = ":x:"
    $summary = $FullSummary
}

# Build comment
"## $status TSQLLint Summary" | Out-File $CommentFile
"\n$summary" | Out-File $CommentFile -Append
"\n[Detailed results.]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)" | Out-File $CommentFile -Append
"\n:recycle: This comment has been updated with latest results." | Out-File $CommentFile -Append

exit 0

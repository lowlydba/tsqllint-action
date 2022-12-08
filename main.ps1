﻿param(
    [Parameter()]
    [string]$Config,
    [string]$OnlyChangedFiles,
    [string]$Path,
    [string]$Branch
)
$files = $Path
$commentFile = Join-Path -Path $env:RUNNER_TEMP -ChildPath ".tsqllint-output.final"

$statusIcon = ":white_check_mark:"
$configParams = @(
    "--init"
)
if ($Config) {
    if (Test-Path -Path $Config) {
        $configParams = @("-p", "-c", $Config)
    }
}

# Show config
$configOutput = & "tsqllint" @configParams
if ($configOutput -like "*Config file not found*") {
    $ConfigNotFound = $configOutput | Select-Object -First 2 | Select-Object -Last 1
    Write-Warning -Message $ConfigNotFound
}
$ConfigSetting = $configOutput | Select-Object -Last 1
Write-Output "==================================="
Write-Output "⭐ TSQLLint Action ⭐"
Write-Output "💁 $ConfigSetting"

# Show version
$versionParams = @("-v")
$versionSetting = & "tsqllint" @versionParams
$versionSetting = $versionSetting | Select-Object -Last 1
Write-Output "💁 TSQLLint Version: $versionSetting"
Write-Output "==================================="

# Target changed files
if ($OnlyChangedFiles -eq "true") {
    $files = git diff --diff-filter=MA --name-only origin/$Branch | Select-String -Pattern ".sql" -SimpleMatch
}

# Lint
if ($null -eq $files) {
    Write-Output "No modified or added files detected for linting."
    "no_results=true" >> $env:GITHUB_ENV
    exit 0
}

try {
    if (Test-Path -Path $Config) {
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
$outputContent = Get-Content -Path .tsqllint-output
Write-Output -InputObject $outputContent

$fullSummary = $outputContent | Select-Object -Last 4 | ForEach-Object { $_ + "`n" }
$warningSummary = $outputContent | Select-Object -Last 1
$errorSummary = $outputContent | Select-Object -Last 2 | Select-Object -First 1
$numWarnings = $warningSummary.Split(" ")[0]
$numErrors = $errorSummary.Split(" ")[0]
$summary = $fullSummary
if ($numErrors -gt 0 -or $numWarnings -gt 0) {
    $errorList = $outputContent | Select-Object -Skip 1 | Select-Object -First ($outputContent.Count - 6)
    $table = "| Type | Rule | Location | Message |" + "`n"
    $table += "| ---- | ---- | -------- | ------- |" + "`n"
    foreach ($line in $errorList) {
        $tableArray = $line.Split(":")
        $location = $tableArray[0]
        $err = ($tableArray[1].Split())[1]
        $rule = ($tableArray[1].Split())[2]
        $msg = $tableArray[2]
        $table += "| $err | [$rule](https://github.com/tsqllint/tsqllint/blob/main/documentation/rules/$rule.md) | $location | $msg |" + "`n"
    }

    if ($numErrors -gt 0) {
        $statusIcon = ":x:"
    }
    elseif ($numWarnings -gt 0) {
        $statusIcon = ":warning:"
    }
}
# Build comment
"## $statusIcon TSQLLint Summary" | Out-File $commentFile
"`n$summary" | Out-File $commentFile -Append
if ($table) {
    "`n<details>" | Out-File $commentFile -Append
    "`n<summary>See results</summary>" | Out-File $commentFile -Append
    "`n$table" | Out-File $commentFile -Append
    "`n</details>" | Out-File $commentFile -Append
}
"`n:page_facing_up: Full [job results]($env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID)." | Out-File $commentFile -Append
"`n:recycle: This comment has been updated with latest results." | Out-File $commentFile -Append

"COMMENT_FILE=$commentFile" >> $env:GITHUB_ENV

exit 0

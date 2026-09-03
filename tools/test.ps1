param(
    [string]$Godot = "C:\Godot461\Godot_v4.6.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Build = Join-Path $Root "build"
$TestHome = Join-Path $Build "test-user"
$Stdout = Join-Path $Build "tests_stdout.log"
$Stderr = Join-Path $Build "tests_stderr.log"
$SmokeStdout = Join-Path $Build "smoke_stdout.log"
$SmokeStderr = Join-Path $Build "smoke_stderr.log"

if (-not (Test-Path $Godot)) {
    throw "Godot not found: $Godot"
}

New-Item -ItemType Directory -Force -Path $Build | Out-Null
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $TestHome
New-Item -ItemType Directory -Force -Path $TestHome | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue $Stdout, $Stderr, $SmokeStdout, $SmokeStderr

# Godot uses APPDATA on Windows for user://. Redirect it so tests never read or
# overwrite the developer's real save, telemetry, or settings.
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = Join-Path $TestHome "Roaming"
$env:LOCALAPPDATA = Join-Path $TestHome "Local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

try {
    Write-Host "Running headless game tests with isolated user data..."
    $process = Start-Process `
        -FilePath $Godot `
        -ArgumentList @("--headless", "--path", $Root, "--quit-after", "300", "res://tests/TestRunner.tscn") `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $Stdout `
        -RedirectStandardError $Stderr

    $output = ""
    if (Test-Path $Stdout) {
        $stdoutText = Get-Content $Stdout -Raw
        if ($null -ne $stdoutText) {
            $output += $stdoutText
            Write-Host $stdoutText
        }
    }
    if (Test-Path $Stderr) {
        $stderrText = Get-Content $Stderr -Raw
        if ($null -ne $stderrText) {
            $output += "`n" + $stderrText
            if ($stderrText.Trim() -ne "") {
                Write-Host $stderrText
            }
        }
    }

    if ($process.ExitCode -ne 0) {
        throw "Game tests failed with exit code $($process.ExitCode)"
    }
    $fatalErrors = @($output -split "`r?`n" | Where-Object { $_ -match "^(SCRIPT ERROR|ERROR:)" })
    if ($fatalErrors.Count -gt 0) {
        throw "Godot reported a script/runtime error; see build/tests_*.log"
    }
    Write-Host "Game logic/content tests passed."

    Write-Host "Running main-scene smoke test..."
    $smoke = Start-Process `
        -FilePath $Godot `
        -ArgumentList @("--headless", "--path", $Root, "--quit-after", "3") `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $SmokeStdout `
        -RedirectStandardError $SmokeStderr
    $smokeOutput = ""
    if (Test-Path $SmokeStdout) {
        $text = Get-Content $SmokeStdout -Raw
        if ($null -ne $text) { $smokeOutput += $text }
    }
    if (Test-Path $SmokeStderr) {
        $text = Get-Content $SmokeStderr -Raw
        if ($null -ne $text) { $smokeOutput += "`n" + $text }
    }
    if ($smoke.ExitCode -ne 0 -or $smokeOutput -match "(?m)^(SCRIPT ERROR|ERROR:)") {
        Write-Host $smokeOutput
        throw "Main-scene smoke test failed; see build/smoke_*.log"
    }
    Write-Host "Main-scene smoke test passed."
}
finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
}

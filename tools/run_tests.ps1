# Every suite in tests\ inside the dev project, one RESULT line each. exit 0 = green.
#
#   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
#   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 -Only test_theme
#
# GODOT_EXE, else godot on PATH
param([string]$Only = '', [int]$TimeoutSeconds = 120)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$dev = & (Join-Path $PSScriptRoot 'dev_project.ps1')
$godot = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { 'godot' }
$logs = Join-Path $env:TEMP ("woldui-tests\run-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $logs | Out-Null

# new class_name stays undeclared until an import rebuilds the class cache
$importLog = Join-Path $logs 'import.log'
$import = Start-Process -FilePath $godot -PassThru -NoNewWindow `
    -ArgumentList @('--headless', '--path', "`"$dev`"", '--import') `
    -RedirectStandardOutput $importLog -RedirectStandardError "$importLog.err"
if (-not $import.WaitForExit($TimeoutSeconds * 1000)) {
    $import.Kill()
    Write-Output "import: TIMEOUT after $TimeoutSeconds s ($importLog)"
    exit 1
}

$suites = Get-ChildItem (Join-Path $repo 'tests') -Filter 'test_*.gd' | Sort-Object Name
if ($Only) {
    $want = $Only.Split(',') | ForEach-Object { $_.Trim() }
    $suites = $suites | Where-Object { $want -contains $_.BaseName }
}

$failed = 0
foreach ($suite in $suites) {
    $log = Join-Path $logs ($suite.BaseName + '.log')
    $proc = Start-Process -FilePath $godot -PassThru -NoNewWindow `
        -ArgumentList @('--headless', '--path', "`"$dev`"", '--log-file', "`"$log`"", '-s', "res://addons/woldui/tests/$($suite.Name)") `
        -RedirectStandardOutput "$log.out" -RedirectStandardError "$log.err"
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        $proc.Kill()
        Write-Output "$($suite.BaseName): TIMEOUT after $TimeoutSeconds s ($log)"
        $failed++
        continue
    }
    $out = Get-Content "$log.out" -Raw -ErrorAction SilentlyContinue
    $result = ($out -split "`n" | Where-Object { $_ -match 'RESULT:' } | Select-Object -Last 1)
    if (-not $result) { $result = 'RESULT: no result line (crashed?)' }
    Write-Output "$($suite.BaseName): $($result.Trim())"
    $err = Get-Content "$log.err" -Raw -ErrorAction SilentlyContinue
    (($out + "`n" + $err) -split "`n") | Where-Object { $_ -match 'FAIL:|SCRIPT ERROR|Parse Error' } | ForEach-Object { Write-Output "    $($_.Trim())" }
    if ($result -notmatch 'ALL PASSED') { $failed++ }
}
Write-Output "logs: $logs"
exit $failed

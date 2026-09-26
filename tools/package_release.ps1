# Release zip -> dist\woldui-<version>.zip, everything under addons/woldui/.
# git archive of HEAD, so commit first. .gitattributes export-ignore drops tests + dev scripts.
#
#   powershell -ExecutionPolicy Bypass -File tools\package_release.ps1
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$cfg = Get-Content (Join-Path $repo 'plugin.cfg') -Raw
if ($cfg -notmatch 'version="([^"]+)"') { throw 'plugin.cfg has no version' }
$version = $Matches[1]

$dirty = git status --porcelain
if ($dirty) { Write-Warning "Uncommitted changes are NOT in the zip (it packs HEAD):`n$($dirty -join "`n")" }

New-Item -ItemType Directory -Force (Join-Path $repo 'dist') | Out-Null
$zip = Join-Path $repo "dist\woldui-$version.zip"
git archive --format=zip --prefix=addons/woldui/ -o $zip HEAD
if ($LASTEXITCODE -ne 0) { throw 'git archive failed' }
Write-Output "PACKED $zip ($([math]::Round((Get-Item $zip).Length / 1KB)) KB)"

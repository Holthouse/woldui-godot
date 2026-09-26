# Dev project for tests + gallery at %LOCALAPPDATA%\woldui-godot-dev.
# addons\woldui there is a junction to this repo, so nothing gets copied.
#
#   powershell -ExecutionPolicy Bypass -File tools\dev_project.ps1          # prints the path
#   powershell -ExecutionPolicy Bypass -File tools\dev_project.ps1 -Open    # also opens the editor
param([switch]$Open)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$dev = Join-Path $env:LOCALAPPDATA 'woldui-godot-dev'
$godot = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { 'godot' }

New-Item -ItemType Directory -Force (Join-Path $dev 'addons') | Out-Null
$link = Join-Path $dev 'addons\woldui'
if (-not (Test-Path $link)) {
    cmd /c mklink /J "$link" "$repo" | Out-Null
}

$project = Join-Path $dev 'project.godot'
if (-not (Test-Path $project)) {
    $text = @'
config_version=5

[application]

config/name="WoldUI dev"
run/main_scene="res://addons/woldui/gallery/gallery.tscn"

[autoload]

WoldUI="*res://addons/woldui/runtime/wold_ui_runtime.gd"

[editor_plugins]

enabled=PackedStringArray("res://addons/woldui/plugin.cfg")

[woldui]

tokens="res://addons/woldui/tokens/default_dark.tres"
'@
    [System.IO.File]::WriteAllText($project, $text, (New-Object System.Text.UTF8Encoding($false)))
}

if ($Open) { & $godot --path $dev -e }
$dev

# Build a Lua watchface project into build\<name>.face
# Usage: .\build_face.ps1 mb10pro\wf_lua_flappy [id] [-Device band9pro]
# -Device builds for another 336x480 Lua device -> build\<name>_<device>.face
param(
    [Parameter(Mandatory)][string]$Project,
    [string]$Id = "",
    [ValidateSet("", "band8pro", "band9pro", "band10pro")][string]$Device = "",
    [string]$Compiler = "C:\Users\Hassan\Downloads\Easyface\app\Compiler.exe"
)
$ErrorActionPreference = "Stop"
$proj = (Resolve-Path $Project).Path
$fprj = Get-ChildItem $proj -Filter *.fprj | Select-Object -First 1
if (-not $fprj) { throw "no .fprj in $proj" }
$name = (Split-Path $proj -Leaf) -replace '^wf_', ''
# stable per-project id unless given: watchfaces with the same id replace each other
if (-not $Id) {
    $h = 0; foreach ($c in $name.ToCharArray()) { $h = ($h * 31 + [int]$c) % 99991 }
    $Id = [string](167200000 + $h)
}
$out = Join-Path $PSScriptRoot "build"
New-Item -ItemType Directory -Force $out, (Join-Path $proj "output") | Out-Null
$faceName = "$name.face"
$src = $fprj.FullName
if ($Device) {
    # same screen, other device: swap the DeviceType (EasyFace DeviceInfo.db) in a temp copy
    $type = @{ band8pro = 11; band9pro = 367; band10pro = 567 }[$Device]
    $faceName = "$($name)_$Device.face"
    $src = Join-Path $proj "module.$Device.fprj"
    (Get-Content $fprj.FullName -Raw) -replace 'DeviceType="\d+"', "DeviceType=`"$type`"" | Set-Content $src -NoNewline
}
try { & $Compiler -b $src $out $faceName $Id }
finally { if ($Device) { Remove-Item $src } }
# the compiler ignores $Id and stamps 167210065 into every face, so the band sees
# them all as one face. Write ours into the ID field (0x28, 64 bytes, NUL padded).
$facePath = Join-Path $out $faceName
$bytes = [IO.File]::ReadAllBytes($facePath)
for ($i = 0; $i -lt 64; $i++) { $bytes[0x28 + $i] = 0 }
[Text.Encoding]::ASCII.GetBytes($Id).CopyTo($bytes, 0x28)
[IO.File]::WriteAllBytes($facePath, $bytes)
Write-Host "-> $facePath  (id $Id)"

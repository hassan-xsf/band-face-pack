# Build a Lua watchface project into build\<name>.face
# Usage: .\build_face.ps1 mb10pro\wf_lua_flappy [id]
param(
    [Parameter(Mandatory)][string]$Project,
    [string]$Id = "",
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
& $Compiler -b $fprj.FullName $out "$name.face" $Id
# the compiler ignores $Id and stamps 167210065 into every face, so the band sees
# them all as one face. Write ours into the ID field (0x28, 64 bytes, NUL padded).
$facePath = Join-Path $out "$name.face"
$bytes = [IO.File]::ReadAllBytes($facePath)
for ($i = 0; $i -lt 64; $i++) { $bytes[0x28 + $i] = 0 }
[Text.Encoding]::ASCII.GetBytes($Id).CopyTo($bytes, 0x28)
[IO.File]::WriteAllBytes($facePath, $bytes)
Write-Host "-> $out\$name.face  (id $Id)"

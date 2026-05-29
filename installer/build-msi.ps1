<#
.SYNOPSIS
  Genera el MSI de Catálogo Interactivo usando WiX Toolset v4.
  Ejecutar desde la raíz del proyecto Flutter.

.PARAMETER Version
  Número de versión, ej: 1.0.0

.EXAMPLE
  .\installer\build-msi.ps1 -Version 1.0.0
#>
param(
  [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

$BuildDir  = "build\windows\x64\runner\Release"
$WxsInput  = "installer\wix\product.wxs"
$WxsFinal  = "installer\wix\_product_gen.wxs"
$HeatOutput = "installer\wix\_files_gen.wxs"
$OutputMsi = "CatalogoInteractivo-$Version.msi"

Write-Host "=== Catálogo Interactivo — Build MSI v$Version ===" -ForegroundColor Cyan

# 1. Build Flutter Windows
Write-Host "`n[1/4] Building Flutter Windows release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build falló" }

# 2. Harvest de archivos con heat.exe (WiX heat o wix harvest)
Write-Host "`n[2/4] Harvesting files from $BuildDir..." -ForegroundColor Yellow

# wix 4 usa "wix harvest" en lugar de heat.exe
wix harvest dir $BuildDir `
  -nologo `
  -ag `
  -sfrag `
  -sreg `
  -srd `
  -dr INSTALLFOLDER `
  -cg HarvestedFiles `
  -var var.BuildDir `
  -o $HeatOutput

if ($LASTEXITCODE -ne 0) { throw "wix harvest falló" }

# 3. Reemplazar versión en .wxs principal
Write-Host "`n[3/4] Preparando .wxs con versión $Version..." -ForegroundColor Yellow
(Get-Content $WxsInput) `
  -replace '\$\{VERSION\}', $Version `
  -replace '\$\{BUILD_DIR\}', $BuildDir |
  Set-Content $WxsFinal

# 4. Compilar MSI
Write-Host "`n[4/4] Compilando MSI..." -ForegroundColor Yellow
wix build $WxsFinal $HeatOutput `
  -d BuildDir="$BuildDir" `
  -ext WixToolset.UI.wixext `
  -o $OutputMsi

if ($LASTEXITCODE -ne 0) { throw "wix build falló" }

Write-Host "`n✓ MSI generado: $OutputMsi" -ForegroundColor Green

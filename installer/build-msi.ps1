<#
.SYNOPSIS
  Genera el MSI de Catalogo Interactivo usando WiX Toolset v4.
  Enumera todos los archivos de salida de Flutter y construye un .wxs
  completo (directorios + componentes), sin depender de 'wix harvest'.

.PARAMETER Version
  Numero de version, ej: 1.0.0

.EXAMPLE
  .\installer\build-msi.ps1 -Version 1.0.0
#>
param(
  [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

$BuildDir  = "build\windows\x64\runner\Release"
$OutWxs    = "installer\wix\_generated.wxs"
$OutputMsi = "CatalogoInteractivo-$Version.msi"
$ExeName   = "catalogo_interactivo.exe"

Write-Host "=== Catalogo Interactivo - Build MSI v$Version ===" -ForegroundColor Cyan

# 0. Generar archivos de plataforma Windows (runner/, flutter/) limpios
Write-Host "`n[0/4] Generando archivos de plataforma Windows..." -ForegroundColor Yellow
if (Test-Path "windows") { Remove-Item -Recurse -Force "windows" }
flutter create --platforms=windows --project-name catalogo_interactivo .
if ($LASTEXITCODE -ne 0) { throw "flutter create fallo" }

# 1. Build Flutter Windows release
Write-Host "`n[1/4] Building Flutter Windows release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build fallo" }

$exePath = Join-Path $BuildDir $ExeName
if (-not (Test-Path $exePath)) { throw "No se encontro $ExeName en $BuildDir" }

# 2. Generar el .wxs enumerando archivos y directorios
Write-Host "`n[2/4] Generando WiX source desde $BuildDir..." -ForegroundColor Yellow

$dirXml  = New-Object System.Text.StringBuilder
$compXml = New-Object System.Text.StringBuilder

function Get-HashId {
  param([string]$prefix, [string]$text)
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
  $hex = ([System.BitConverter]::ToString($bytes)).Replace("-", "")
  return "$prefix$($hex.Substring(0,24))"
}

function Get-GuidFor {
  param([string]$text)
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
  return ([System.Guid]::new($bytes)).ToString().ToUpper()
}

function Walk-Dir {
  param([string]$physDir, [string]$dirId, [string]$relPath)

  # Componentes para los archivos en este directorio (lista plana en compXml)
  foreach ($f in (Get-ChildItem -Path $physDir -File | Sort-Object Name)) {
    $rel    = if ($relPath) { "$relPath\$($f.Name)" } else { $f.Name }
    $compId = Get-HashId "cmp" $rel
    $fileId = Get-HashId "fil" $rel
    $guid   = Get-GuidFor $rel
    [void]$compXml.AppendLine("      <Component Id=`"$compId`" Directory=`"$dirId`" Guid=`"$guid`">")
    [void]$compXml.AppendLine("        <File Id=`"$fileId`" Source=`"$($f.FullName)`" KeyPath=`"yes`" />")
    [void]$compXml.AppendLine("      </Component>")
  }

  # Subdirectorios (anidados correctamente en dirXml)
  foreach ($d in (Get-ChildItem -Path $physDir -Directory | Sort-Object Name)) {
    $rel      = if ($relPath) { "$relPath\$($d.Name)" } else { $d.Name }
    $subDirId = Get-HashId "dir" $rel
    [void]$dirXml.AppendLine("        <Directory Id=`"$subDirId`" Name=`"$($d.Name)`">")
    Walk-Dir -physDir $d.FullName -dirId $subDirId -relPath $rel
    [void]$dirXml.AppendLine("        </Directory>")
  }
}

Walk-Dir -physDir (Resolve-Path $BuildDir).Path -dirId "INSTALLFOLDER" -relPath ""

$template = @'
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="Catalogo Interactivo"
           Manufacturer="Alejandro Martin"
           Version="@VERSION@"
           UpgradeCode="A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
           InstallerVersion="500"
           Compressed="yes"
           Scope="perMachine">

    <SummaryInformation Description="Catalogo Interactivo de URLs" />
    <MajorUpgrade DowngradeErrorMessage="Ya hay una version mas nueva instalada de Catalogo Interactivo." />
    <MediaTemplate EmbedCab="yes" />

    <StandardDirectory Id="ProgramFiles6432Folder">
      <Directory Id="INSTALLFOLDER" Name="Catalogo Interactivo">
@DIRS@
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="ProgramMenuFolder">
      <Directory Id="ApplicationProgramsFolder" Name="Catalogo Interactivo" />
    </StandardDirectory>
    <StandardDirectory Id="DesktopFolder" />

    <Component Id="AppShortcuts" Directory="ApplicationProgramsFolder" Guid="C0FFEE01-0000-4000-8000-000000000001">
      <Shortcut Id="StartMenuShortcut"
                Name="Catalogo Interactivo"
                Target="[INSTALLFOLDER]catalogo_interactivo.exe"
                WorkingDirectory="INSTALLFOLDER" />
      <Shortcut Id="DesktopShortcut"
                Directory="DesktopFolder"
                Name="Catalogo Interactivo"
                Target="[INSTALLFOLDER]catalogo_interactivo.exe"
                WorkingDirectory="INSTALLFOLDER" />
      <RemoveFolder Id="CleanupProgramsFolder" On="uninstall" />
      <RegistryValue Root="HKCU"
                     Key="Software\CatalogoInteractivo"
                     Name="installed"
                     Type="integer"
                     Value="1"
                     KeyPath="yes" />
    </Component>

    <Feature Id="MainApp" Title="Catalogo Interactivo" Level="1">
      <ComponentGroupRef Id="AppFiles" />
      <ComponentRef Id="AppShortcuts" />
    </Feature>

    <ComponentGroup Id="AppFiles">
@COMPS@
    </ComponentGroup>
  </Package>
</Wix>
'@

$xml = $template.
  Replace("@VERSION@", $Version).
  Replace("@DIRS@", $dirXml.ToString().TrimEnd()).
  Replace("@COMPS@", $compXml.ToString().TrimEnd())

Set-Content -Path $OutWxs -Value $xml -Encoding UTF8
Write-Host "WiX source generado: $OutWxs" -ForegroundColor DarkGray

# 3. Compilar MSI (x64, sin extensiones de UI)
Write-Host "`n[3/4] Compilando MSI..." -ForegroundColor Yellow
wix build $OutWxs -arch x64 -o $OutputMsi
if ($LASTEXITCODE -ne 0) { throw "wix build fallo" }

# 4. Verificar resultado
Write-Host "`n[4/4] Verificando..." -ForegroundColor Yellow
if (-not (Test-Path $OutputMsi)) { throw "No se genero el MSI" }
$size = [math]::Round((Get-Item $OutputMsi).Length / 1MB, 2)
Write-Host "`nMSI generado: $OutputMsi ($size MB)" -ForegroundColor Green

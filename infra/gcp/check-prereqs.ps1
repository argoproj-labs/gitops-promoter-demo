$ErrorActionPreference = "Stop"

function Resolve-ToolPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandName,
    [Parameter(Mandatory = $false)]
    [string[]]$FallbackPaths = @()
  )

  $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  foreach ($path in $FallbackPaths) {
    if (Test-Path $path) {
      return $path
    }
  }

  return $null
}

$gcloudPath = Resolve-ToolPath -CommandName "gcloud" -FallbackPaths @(
  "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
)

$terraformPath = Resolve-ToolPath -CommandName "terraform"
if (-not $terraformPath) {
  $wingetTerraform = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "terraform.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($wingetTerraform) {
    $terraformPath = $wingetTerraform.FullName
  }
}

Write-Host "== Tooling =="
if ($gcloudPath) {
  Write-Host "gcloud: OK ($gcloudPath)"
  & $gcloudPath --version | Select-Object -First 1
} else {
  Write-Host "gcloud: NOT FOUND"
}

if ($terraformPath) {
  Write-Host "terraform: OK ($terraformPath)"
  & $terraformPath version | Select-Object -First 1
} else {
  Write-Host "terraform: NOT FOUND"
}

Write-Host "`n== gcloud auth =="
if (-not $gcloudPath) {
  Write-Host "Skipping auth check because gcloud is unavailable."
} else {
  try {
    $account = & $gcloudPath config get-value account 2>$null
    if ([string]::IsNullOrWhiteSpace($account) -or $account -eq "(unset)") {
      Write-Host "No active gcloud account. Run: gcloud auth login"
    } else {
      Write-Host "Active account: $account"
    }
  } catch {
    Write-Host "Unable to read gcloud auth status. $_"
  }
}

Write-Host "`n== gcloud ADC =="
try {
  $adcPath = "$env:APPDATA\gcloud\application_default_credentials.json"
  if (Test-Path $adcPath) {
    Write-Host "ADC file present: $adcPath"
  } else {
    Write-Host "ADC missing. Run: gcloud auth application-default login"
  }
} catch {
  Write-Host "Unable to check ADC status. $_"
}

Write-Host "`n== billing accounts =="
if (-not $gcloudPath) {
  Write-Host "Skipping billing check because gcloud is unavailable."
} else {
  try {
    & $gcloudPath billing accounts list --format="table(name,displayName,open)"
  } catch {
    Write-Host "Unable to list billing accounts until authenticated."
  }
}


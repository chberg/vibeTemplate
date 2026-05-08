<#
.SYNOPSIS
vibe-init.ps1 — scaffold a new vibe-coded project from the starter templates.

.DESCRIPTION
This is the PowerShell equivalent of vibe-init.sh. It copies the starter templates,
substitutes placeholders, initializes git, and creates an initial commit.

.EXAMPLE
.\vibe-init.ps1 lockix-platform C:\projects
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false, Position=1)]
    [string]$TargetParentDir
)

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Host "Usage: .\vibe-init.ps1 <project-name> [target-parent-dir]"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($TargetParentDir)) {
    $TargetParentDir = (Get-Location).Path
}

$Target = Join-Path -Path $TargetParentDir -ChildPath $ProjectName
$ScriptDir = $PSScriptRoot
$Templates = Join-Path -Path $ScriptDir -ChildPath "templates"

if (-not (Test-Path -Path $Templates -PathType Container)) {
    Write-Host "Templates not found at $Templates"
    exit 1
}

if (Test-Path -Path $Target) {
    Write-Host "Target already exists: $Target"
    exit 1
}

Write-Host "==> Creating $Target"
New-Item -ItemType Directory -Path $Target | Out-Null

Write-Host "==> Copying templates"
Copy-Item -Path "$Templates\*" -Destination $Target -Recurse -Force
Get-ChildItem -Path $Templates -Force | Where-Object { $_.Name -like ".*" } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $Target -Recurse -Force
}

Write-Host "==> Substituting placeholders"
$pyprojectPath = Join-Path -Path $Target -ChildPath "pyproject.toml"
$readmePath = Join-Path -Path $Target -ChildPath "README.md"

if (Test-Path $pyprojectPath) {
    (Get-Content -Raw $pyprojectPath) -replace 'PROJECT_NAME_PLACEHOLDER', $ProjectName | Set-Content $pyprojectPath -NoNewline
}
if (Test-Path $readmePath) {
    (Get-Content -Raw $readmePath) -replace 'PROJECT_NAME_PLACEHOLDER', $ProjectName | Set-Content $readmePath -NoNewline
}

Write-Host "==> Initializing git"
Set-Location -Path $Target
git init -q
git checkout -q -b main
git add -A
git config user.email "vibe@local"
git config user.name "vibe-init"
git commit -q -m "chore: vibe factory scaffold"

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host ""
Write-Host "  cd $Target"
Write-Host "  cp .env.example .env   # fill in your API keys"
Write-Host "  ./scripts/agentctl/verify.sh   # confirm toolchain"
Write-Host "  ./scripts/agentctl/once.sh     # run the example ticket"
Write-Host ""
Write-Host "When ready for real work:"
Write-Host "  1. Open Antigravity (or Codex) on this directory."
Write-Host "  2. /clear"
Write-Host "  3. Load .skills/grill-me/SKILL.md and start your first session."

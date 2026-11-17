# Set up this environment on a new Windows PC.
# Works from Windows PowerShell 5.1 (no PowerShell 7 needed yet).
#
#   powershell -ExecutionPolicy Bypass -File ~/dotfiles/bootstrap.ps1
#
# Options: -SkipPackages  -SkipFont  -SkipAI
[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$SkipFont,
    [switch]$SkipAI
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = $PSScriptRoot

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Refresh-Path {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('PATH', 'User')
}

# 1. Packages ------------------------------------------------------------------
$packages = @(
    'Microsoft.WindowsTerminal'
    'Microsoft.PowerShell'
    'Git.Git'
    'GitHub.cli'
    'Starship.Starship'
    'ajeetdsouza.zoxide'
    'junegunn.fzf'
    'eza-community.eza'
    'sharkdp.bat'
    'BurntSushi.ripgrep.MSVC'
    'sharkdp.fd'
    'dandavison.delta'
)
if (-not $SkipPackages) {
    Step 'Installing packages with winget'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install "App Installer" from the Microsoft Store first.'
    }
    foreach ($id in $packages) {
        $null = winget list -e --id $id --source winget --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Host "  ok       $id"; continue }
        Write-Host "  install  $id"
        winget install -e --id $id --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Warning "winget install $id failed (exit $LASTEXITCODE)" }
    }
    Refresh-Path
}

# 2. Font: PlemolJP Console NF -------------------------------------------------
if (-not $SkipFont) {
    Step 'Installing font: PlemolJP Console NF'
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    if (Test-Path (Join-Path $fontDir 'PlemolJPConsoleNF-Regular.ttf')) {
        Write-Host '  already installed'
    } else {
        $rel = Invoke-RestMethod 'https://api.github.com/repos/yuru7/PlemolJP/releases/latest'
        $asset = $rel.assets | Where-Object { $_.name -like 'PlemolJP_NF_*.zip' } | Select-Object -First 1
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("plemoljp-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        try {
            Write-Host ("  downloading {0} ({1:N0} MB)" -f $asset.name, ($asset.size / 1MB))
            $zip = Join-Path $tmp 'font.zip'
            Invoke-WebRequest $asset.browser_download_url -OutFile $zip
            Expand-Archive $zip -DestinationPath $tmp -Force
            New-Item -ItemType Directory -Force $fontDir | Out-Null
            $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
            if (-not ('Dotfiles.Gdi' -as [type])) {
                Add-Type -Namespace Dotfiles -Name Gdi -MemberDefinition '[DllImport("gdi32.dll", CharSet=CharSet.Unicode)] public static extern int AddFontResource(string f);'
            }
            Get-ChildItem $tmp -Recurse -Filter 'PlemolJPConsoleNF-*.ttf' | ForEach-Object {
                $target = Join-Path $fontDir $_.Name
                Copy-Item $_.FullName $target -Force
                New-ItemProperty $reg -Name "$($_.BaseName) (TrueType)" -Value $target -PropertyType String -Force | Out-Null
                [void][Dotfiles.Gdi]::AddFontResource($target)
            }
            Write-Host '  installed'
        } finally {
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# 3. PowerShell modules --------------------------------------------------------
Step 'Installing PowerShell 7 modules'
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'pwsh not found. Re-run without -SkipPackages.' }
pwsh -NoProfile -Command 'if (-not (Get-Module -ListAvailable PSFzf)) { Install-Module PSFzf -Scope CurrentUser -Force -AcceptLicense }; ''  PSFzf ok'''

# 4. Claude Code / Codex -------------------------------------------------------
if (-not $SkipAI) {
    Step 'Installing Claude Code and Codex (npm)'
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        winget install -e --id OpenJS.NodeJS.LTS --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
        Refresh-Path
    }
    foreach ($pair in @(@('claude', '@anthropic-ai/claude-code'), @('codex', '@openai/codex'))) {
        if (Get-Command $pair[0] -ErrorAction SilentlyContinue) { Write-Host "  ok       $($pair[0])"; continue }
        Write-Host "  install  $($pair[1])"
        npm install -g $pair[1] | Out-Null
    }
}

# 5. Link config files ---------------------------------------------------------
Step 'Applying config files'
pwsh -NoProfile -File (Join-Path $root 'install.ps1')

Write-Host "`nDone. Open Windows Terminal from the Start menu." -ForegroundColor Green

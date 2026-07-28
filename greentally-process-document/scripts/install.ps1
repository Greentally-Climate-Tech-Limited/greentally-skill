$ErrorActionPreference = "Stop"

$repository = "Greentally-Climate-Tech-Limited/greentally-skill"

function Confirm-GreentallyCli {
    param([Parameter(Mandatory = $true)][string]$Path)

    & $Path version | Out-Null
    Write-Output $Path
}

if ($env:GREENTALLY_CLI_PATH) {
    if (-not (Test-Path -LiteralPath $env:GREENTALLY_CLI_PATH -PathType Leaf)) {
        throw "GREENTALLY_CLI_PATH is not a file."
    }
    Confirm-GreentallyCli -Path $env:GREENTALLY_CLI_PATH
    exit 0
}

$cacheRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
if (-not $cacheRoot) {
    throw "LOCALAPPDATA is unavailable."
}
$cliPath = Join-Path $cacheRoot "Greentally\cli\greentally.exe"

if (Test-Path -LiteralPath $cliPath -PathType Leaf) {
    Confirm-GreentallyCli -Path $cliPath
    exit 0
}

$pathCli = Get-Command "greentally" -CommandType Application -ErrorAction SilentlyContinue
if ($pathCli) {
    Confirm-GreentallyCli -Path $pathCli.Source
    exit 0
}

switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
    "X64" { $architecture = "amd64" }
    "Arm64" { $architecture = "arm64" }
    default { throw "Unsupported Windows architecture." }
}

$temporaryDir = Join-Path ([System.IO.Path]::GetTempPath()) (
    "greentally-install-" + [System.Guid]::NewGuid().ToString("N")
)
New-Item -ItemType Directory -Path $temporaryDir | Out-Null

try {
    $headers = @{ Accept = "application/vnd.github+json" }
    $release = Invoke-RestMethod `
        -Headers $headers `
        -Uri "https://api.github.com/repos/$repository/releases/latest"
    $tag = [string]$release.tag_name
    $version = $tag.TrimStart("v")
    if (-not $tag -or -not $version) {
        throw "Could not determine the latest Greentally CLI version."
    }

    $archive = "greentally_${version}_windows_${architecture}.zip"
    $releaseBase = "https://github.com/$repository/releases/download/$tag"
    $archivePath = Join-Path $temporaryDir $archive
    $checksumsPath = Join-Path $temporaryDir "checksums.txt"

    Invoke-WebRequest -Uri "$releaseBase/$archive" -OutFile $archivePath
    Invoke-WebRequest -Uri "$releaseBase/checksums.txt" -OutFile $checksumsPath

    $checksumLine = Get-Content -LiteralPath $checksumsPath |
        Where-Object { $_ -match ("^[0-9a-fA-F]{64}\s+" + [regex]::Escape($archive) + "$") } |
        Select-Object -First 1
    if (-not $checksumLine) {
        throw "No checksum found for $archive."
    }
    $expected = ($checksumLine -split "\s+")[0].ToLowerInvariant()
    $actual = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        throw "Checksum verification failed for $archive."
    }

    $extractPath = Join-Path $temporaryDir "extracted"
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath
    $executable = Join-Path $extractPath "greentally.exe"
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "The release archive does not contain greentally.exe."
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $cliPath) -Force | Out-Null
    Move-Item -LiteralPath $executable -Destination $cliPath
    Confirm-GreentallyCli -Path $cliPath
}
finally {
    if (Test-Path -LiteralPath $temporaryDir) {
        Remove-Item -LiteralPath $temporaryDir -Recurse -Force
    }
}

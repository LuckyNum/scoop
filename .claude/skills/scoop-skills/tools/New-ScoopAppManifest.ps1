# New-ScoopAppManifest.ps1
# 辅助创建 Scoop App Manifest 的 PowerShell 脚本

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$Url,

    [string]$Description = "",

    [string]$Homepage = "",

    [string]$License = "",

    [string]$Bin = "",

    [switch]$SkipHash
)

function Get-FileHashFromUrl {
    param(
        [string]$Url,
        [string]$TempPath
    )

    Write-Host "正在下载文件以计算 hash..." -ForegroundColor Yellow
    $outputFile = Join-Path $TempPath (Split-Path $Url -Leaf)
    Invoke-WebRequest -Uri $Url -OutFile $outputFile
    $hash = (Get-FileHash $outputFile -Algorithm SHA256).Hash.ToLower()
    Remove-Item $outputFile -Force

    return "sha256:$hash"
}

function New-ScoopManifest {
    param(
        [string]$Name,
        [string]$Version,
        [string]$Url,
        [string]$Description,
        [string]$Homepage,
        [string]$License,
        [string]$Bin,
        [string]$Hash
    )

    $manifest = [ordered]@{
        version = $Version
    }

    if ($Description) {
        $manifest.description = $Description
    }

    if ($Homepage) {
        $manifest.homepage = $Homepage
    }

    if ($License) {
        $manifest.license = $License
    }

    $manifest.url = $Url

    if ($Hash) {
        $manifest.hash = $Hash
    }

    if ($Bin) {
        $manifest.bin = $Bin
    }

    # GitHub Releases autoupdate detection
    if ($Url -match "github\.com/([^/]+)/([^/]+)/releases") {
        $owner = $matches[1]
        $repo = $matches[2]

        $manifest.checkver = "github"
        $manifest.autoupdate = [ordered]@{
            url = $Url -replace [regex]::Escape($Version), "`$version"
        }
    }

    return $manifest | ConvertTo-Json -Depth 10
}

# Main
$ErrorActionPreference = "Stop"

# 创建临时目录
$tempDir = Join-Path $env:TEMP "scoop-manifest-$Name"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

try {
    # 计算 hash
    if ($SkipHash) {
        $hash = "sha256:PLACEHOLDER"
        Write-Host "跳过 hash 计算" -ForegroundColor Yellow
    }
    else {
        $hash = Get-FileHashFromUrl -Url $Url -TempPath $tempDir
        Write-Host "Hash: $hash" -ForegroundColor Green
    }

    # 生成 manifest
    $manifestJson = New-ScoopManifest `
        -Name $Name `
        -Version $Version `
        -Url $Url `
        -Description $Description `
        -Homepage $Homepage `
        -License $License `
        -Bin $Bin `
        -Hash $hash

    # 输出文件
    $outputFile = "$Name.json"
    $manifestJson | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "`nManifest 已创建: $outputFile" -ForegroundColor Green
    Write-Host "`n内容预览:"
    Write-Host "-----------------------------------"
    Write-Host $manifestJson
    Write-Host "-----------------------------------"

    # 下一步提示
    Write-Host "`n下一步操作:" -ForegroundColor Cyan
    Write-Host "1. 检查 manifest 内容是否正确"
    Write-Host "2. 测试安装: scoop install --custom $outputFile"
    Write-Host "3. 提交到 bucket: git add $outputFile && git commit -m 'Add $Name ($Version)'"
}
finally {
    # 清理临时目录
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

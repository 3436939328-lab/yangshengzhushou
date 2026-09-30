param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$stageRoot = 'D:\yangshengzhushou\.work\backend'
$backendRoot = 'D:\SpringBoot\SpringBootDemo'
$backupRoot = 'D:\yangshengzhushou\.work\backend-original'
$manifest = Get-Content -Raw 'D:\yangshengzhushou\.work\backend-publish.json' | ConvertFrom-Json
foreach ($item in $manifest) {
    $source = [IO.Path]::GetFullPath((Join-Path $stageRoot $item.relative))
    $target = [IO.Path]::GetFullPath((Join-Path $backendRoot $item.relative))
    if (-not $source.StartsWith($stageRoot + '\') -or -not $target.StartsWith($backendRoot + '\')) { throw 'Invalid publication path' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.stagedHash) { throw "Staged file changed: $($item.relative)" }
    $currentHash = if (Test-Path -LiteralPath $target) { (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
    if ($currentHash -ne $item.originalHash) { throw "Original file changed since review: $($item.relative)" }
}
if (-not $Apply) { Write-Output "Verified $($manifest.Count) files. Run with -Apply to publish."; exit 0 }
foreach ($item in $manifest) {
    $source = Join-Path $stageRoot $item.relative
    $target = Join-Path $backendRoot $item.relative
    if (Test-Path -LiteralPath $target) {
        $backup = Join-Path $backupRoot $item.relative
        New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
        Copy-Item -LiteralPath $target -Destination $backup
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.stagedHash) { throw "Published hash mismatch: $($item.relative)" }
}
Write-Output "Published and verified $($manifest.Count) files; originals backed up in $backupRoot"

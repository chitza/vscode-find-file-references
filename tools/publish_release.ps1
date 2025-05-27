#!/usr/bin/env pwsh

$ErrorActionPreference='Stop'

$isMain = $env:BRANCH_NAME -eq 'main'
$packageJsonPath = "package.json"
$tmpPath = "package.tmp"

$branch = $(git rev-parse --abbrev-ref HEAD)
$branchSafeName = $($branch.Split([IO.Path]::GetInvalidFileNameChars()) -join '_')
Write-Host "Branch name: $branch, SafeName: $branchSafeName"

$packageJson = Get-Content $packageJsonPath | ConvertFrom-Json
$versionStr = $packageJson.version

[version]$version = $versionStr.Trim('"')
$newVersion = "$($version.Major).$($version.Minor).$($version.Build + 1)"
Write-Host "Current version: $($version.Major).$($version.Minor).$($version.Build), new version: $newVersion"

if ($isMain) {
    # update version
    $packageJson.version = $newVersion

    Write-Host "Writing new $packageJsonPath to $tmpPath ..."
    Set-Content $tmpPath $($packageJson | ConvertTo-Json -Depth 100) -Encoding UTF8

    Write-Host "Overwriting original $packageJsonPath ..."
    Move-Item $tmpPath $packageJsonPath -Force
}

Write-Host "Packaging extension ..."
$outFile = "vscode-find-file-references-$newVersion.vsix"

if ($isMain) {
    Write-Host "Creating release version ..."
    vsce package --out $outFile

    # push the new version only if packaging was successful
    if (Test-Path $outFile) {
        Write-Host "Creating & pushing commit with version bump ..."
        git config --global user.name "GitHubAction"
        git config --global user.email "username@users.noreply.github.com"
        git add package.json
        git commit -m "Bump version to $newVersion"

        Write-Host "Pushing commit with new version ..."
        git push
    }
} else {
    Write-Host "Creating pre-release version ..."
    vsce package --out $outFile --pre-release
}

if (!$isMain) {
    $versionStr = "v$newVersion-$branchSafeName"
} else {
    $versionStr = "v$newVersion"
}

if ($isMain) {
    Write-Host "Creating release $versionStr ..."
    gh release create $versionStr --title "$versionStr" --generate-notes

    Write-Host "Uploading $outFile to $versionStr ..."
    gh release upload $versionStr $outFile

    Write-Host "Publishing with vsce ..."
    vsce publish -p "$env:MARKETPLACE_PAT"
}


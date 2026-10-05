# SPDX-FileCopyrightText: 2026 Caracu contributors
# SPDX-License-Identifier: GPL-3.0+
# Real discovery regression: no configure, compiler invocation, emulator or profile.
param([Parameter(Mandatory = $true)][string]$DependencyBundle)
$ErrorActionPreference = 'Stop'
$taskScript = Join-Path $PSScriptRoot '../build-windows.ps1'
$taskSaved = [Environment]::GetEnvironmentVariable('PATHEXT', 'Process')
try {
    foreach ($taskValue in @('.CPL', '.CUSTOM;.exe;.CMD', $null)) {
        [Environment]::SetEnvironmentVariable('PATHEXT', $taskValue, 'Process')
        $taskBefore = [Environment]::GetEnvironmentVariable('PATHEXT', 'Process')
        $taskOutput = @(& $taskScript -DependencyBundle $DependencyBundle -CheckOnly -Target caracu-ps2d)
        if (-not ($taskOutput -match '^Visual Studio: ')) {
            throw 'Preflight did not discover the real compiler installation.'
        }
        if ([Environment]::GetEnvironmentVariable('PATHEXT', 'Process') -cne $taskBefore) {
            throw 'Successful preflight changed the caller PATHEXT.'
        }
        $taskRejected = $false
        try {
            & $taskScript -DependencyBundle (Join-Path $DependencyBundle ('missing-' + [guid]::NewGuid())) -CheckOnly
        } catch {
            $taskRejected = $true
        }
        if (-not $taskRejected) { throw 'Missing dependencies were accepted.' }
        if ([Environment]::GetEnvironmentVariable('PATHEXT', 'Process') -cne $taskBefore) {
            throw 'Failed preflight changed the caller PATHEXT.'
        }
        Write-Output "PASS: native discovery, missing dependency rejection and environment restoration; PATHEXT=[$taskBefore]"
    }
} finally {
    if ($null -eq $taskSaved) {
        Remove-Item Env:PATHEXT -ErrorAction SilentlyContinue
    } else {
        [Environment]::SetEnvironmentVariable('PATHEXT', $taskSaved, 'Process')
    }
}

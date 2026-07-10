[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PrimaryRemote = 'origin',
    [string]$PersonalMirrorRemote = 'github'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$remotes = @(git -C $root remote)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to enumerate Git remotes.'
}

foreach ($remote in @($PrimaryRemote, $PersonalMirrorRemote)) {
    if ($remote -notin $remotes) {
        throw "Required remote '$remote' is not configured."
    }
}

$status = git -C $root status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to inspect repository status.'
}
if ($status) {
    throw 'Refusing to publish with uncommitted changes.'
}

foreach ($remote in @($PrimaryRemote, $PersonalMirrorRemote)) {
    if ($PSCmdlet.ShouldProcess($remote, 'push all branches and tags')) {
        git -C $root push $remote --all
        if ($LASTEXITCODE -ne 0) {
            throw "Branch publication failed for '$remote'."
        }
        git -C $root push $remote --tags
        if ($LASTEXITCODE -ne 0) {
            throw "Tag publication failed for '$remote'."
        }
    }
}

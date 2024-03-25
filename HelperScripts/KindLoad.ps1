# Workaround for `kind load docker-image <image-name>` because it doesn't work
param (
    [Parameter(Mandatory=$True)]
    [String]$ImageName
)

$ExistingInLocal = $(podman image ls --filter reference=$ImageName --format="{{.ID}}") -gt 0

if(-Not $ExistingInLocal)
{
    Write-Host -NoNewline "$ImageName"
    Write-Host " NOT FOUND" -ForegroundColor Red
}

$ExistingInKind = $(ConvertFrom-Json "$(podman exec -it kind-control-plane crictl images --output json)").images.repoTags.Contains($ImageName) 

if($ExistingInKind)
{
    Write-Host -NoNewline "$ImageName"
    Write-Host " already exists in KinD" -ForegroundColor Cyan
    return
}

$env:KIND_EXPERIMENTAL_PROVIDER="podman"
$tempFileName = [Guid]::NewGuid().Guid + ".tar"
podman save $ImageName -o $tempFileName
kind load image-archive $tempFileName 

if($?)
{
    Write-Host "Loaded $ImageName" -ForegroundColor Green
}
else
{
    Write-Host "$ImageName not loaded" -ForegroundColor Red
}

Remove-Item $tempFileName 


param (
    [Parameter(Mandatory=$True)]
    [String]$ImageName
)

$ExistingInLocal = $(podman image ls --filter reference=$ImageName --format="{{.ID}}") -gt 0

if($ExistingInLocal)
{
    Write-Host -NoNewline "$ImageName"
    Write-Host " already exists in Podman." -ForegroundColor Cyan
}
else
{
    podman pull --tls-verify=$False $ImageName
}
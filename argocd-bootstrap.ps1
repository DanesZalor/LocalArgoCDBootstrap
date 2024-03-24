# using kind and podman

Set-Alias Base64Decode ./HelperScripts/Base64Decode.ps1
Set-Alias KindLoad ./HelperScripts/KindLoad.ps1
Set-Alias RunWithTimeout ./HelperScripts/RunScriptBlockWithTimeout.ps1

function DeployAndWait()
{
    param (
        [Parameter(Mandatory=$True)]
        [String]$ManifestPath
    )

    Write-Host "Initializing ArgoCD $ManifestPath" -ForegroundColor Cyan
    kubectl create namespace argocd
    kubectl apply -n argocd -f $ManifestPath 
    
    Write-Host "Waiting for ArgoCD to stabilize (timeout 90s)" -ForegroundColor Cyan
    kubectl -n argocd wait --for=condition=Ready=true --timeout=90s pod --all
    $SuccessfulDeployment = $?

    if(-Not $SuccessfulDeployment)
    {
        Write-Host "Deployment failed" -ForegroundColor Red
        kubectl delete namespace argocd
    }
    else
    {
        $argocd_password = Base64Decode $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")
        Write-Host "ArgoCD server now running at https://localhost:31415" -ForegroundColor Green 
        Write-Host "  USERNAME:admin  PASS:$argocd_password" 
        
        $PortForwardJob = Start-Job -ScriptBlock {
            kubectl port-forward svc/argocd-server -n argocd 31415:443; 
        }

        Write-Host "  Press [X] to delete ArgoCD instance" 
        do
        {
            $PortforwardOutput = $(Receive-Job -Job $PortForwardJob)
            if($PortforwardOutput.Length -gt 0) 
            {
                Write-Host $PortForwardOutput -ForegroundColor DarkGray
            }
            $key = [Console]::ReadKey("noecho");
        }
        while ($key.Key -ne "x")

        Remove-Job -Job $PortForwardJob -Force
        kubectl delete namespace argocd
    }
}

# Normal way 
DeployAndWait -ManifestPath "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

# Workaround
# $imagesToPull = $(Get-Content .\argocd-install.yaml | findstr "image:" | Select-Object -Unique) -Replace '(image:)|(\s+)', ''
# foreach($img in $imagesToPull)
# {
#     Write-Output "pulling $img"
#     podman pull --tls-verify=$False $img
#     Write-Output "loading $img into kind"
#     KindLoad $img
# }

# DeployAndWait -ManifestPath .\argocd-install.yaml

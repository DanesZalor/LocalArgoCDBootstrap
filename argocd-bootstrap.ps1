# using kind and podman

Set-Alias Base64Decode ./HelperScripts/Base64Decode.ps1
Set-Alias KindLoad ./HelperScripts/KindLoad.ps1
function DeployAndWait()
{
    param (
        [Parameter(Mandatory=$True)]
        [String]$ManifestPath
    )

    Write-Host "Initializing ArgoCD $ManifestPath" 
    kubectl apply -n argocd -f $ManifestPath 
    Write-Host "waiting for ArgoCD pods to be ready..." 
    
    $WaitForDeployment = 
    {
        return kubectl -n argocd wait --for=condition=Ready=true --timeout=180s pod --all
    }
    
    $WaitJob = Start-Job -ScriptBlock $WaitForDeployment
    For($CurrentTime = 180; $CurrentTime -gt 0; $CurrentTime--)
    {
        if($WaitJob.State -eq "Completed")
        {
            break
        }
        Write-Progress -Activity "Waiting for..." -Status "${CurrentTime}s left" -PercentComplete ($CurrentTime / 180 * 100)
        Start-Sleep 1
    }

    $SuccessfulDeployment = Receive-Job $WaitJob

    if(-Not $SuccessfulDeployment)
    {
        Write-Host "Deployment failed" 
        kubectl delete -f $ManifestPath
    }
    else
    {
        $argocd_password = Base64Decode $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")
        Write-Host "ArgoCD credentials:" 
        Write-Host "    username: admin" 
        Write-Host "    password: $argocd_password" 
        Write-Host "now listening at localhost:31415"
        kubectl port-forward svc/argocd-server -n argocd 31415:443
    }

    return $SuccessfulDeployment
}

kubectl create namespace argocd
$NormalDeployment = DeployAndWait -ManifestPath "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

if(-Not $NormalDeployment)
{
    $imagesToPull = $(Get-Content .\argocd-install.yaml | findstr "image:" | Select-Object -Unique) -Replace '(image:)|(\s+)', ''
    foreach($img in $imagesToPull)
    {
        Write-Output "pulling $img"
        podman pull --tls-verify=$False $img
        Write-Output "loading $img into kind"
        KindLoad $img
    }
    
    $WorkAroundDeployment = DeployAndWait -ManifestPath .\argocd-install.yaml

    if(-Not $WorkAroundDeployment)
    {
        Write-Host "Failed Workaround deployment. Out of options"
    }
}
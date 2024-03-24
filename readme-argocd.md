# Running ArgoCD locally

![a](https://miro.medium.com/v2/resize:fit:1400/0*8W3t7eUT5WKvnHpG)

### Prerequisites
- kind
- argocd-cli (`scoop install main/argocd`)
- ## argocd server **running in kind**

    create the namespace
    ```
    kubectl create namespace argocd
    ```

    Assuming we can pull images in the office no problem:
    ```
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 
    ```
    
    Assuming our prior assumption was wrong
    I copied the install.yaml from argocd and set all `imagePullPolicy: Never`
    ALSO you have to manually kindload the images needed in the manifest. 
    ```
    kubectl apply -n argocd -f https://raw.githubusercontent.com/DanesZalor/accounts-api/master/argocd-install.yaml
    ```

    Verify installation
    ```powershell
    kubectl get pods -n argocd
    # should output all pods are running and ready
    ```

    port forward the server
    ```
    kubectl port-forward svc/argocd-server -n argocd 31415:443
    ```
    you'll need the password for the server;
    ```powershell
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
    # output is the base64encoded password; you need to decode this
    ```
    login argocd via `argocd-cli`
    ```
    argocd login  --insecure --username=admin --password=<password> localhost:31415
    ```
    or login via WebUI by going to https://localhost:31415 with the same credentials
    
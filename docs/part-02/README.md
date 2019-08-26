# Install Helm + Flux

Create git repository which will be used by Flux in GitHub:

```bash
hub create -d "Flux repository for k8s-flux-istio-gitlab-harbor" -h "https://ruzickap.github.io/k8s-flux-istio-gitlab-harbor/" ruzickap/k8s-flux-repository
```

Output:

```text
A git remote named 'origin' already exists and is set to push to 'ssh://git@github.com/ruzickap/k8s-flux-istio-gitlab-harbor.git'.
https://github.com/ruzickap/k8s-flux-repository
```

Clone newly create git repository:

```bash
if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi
git config --global user.email "petr.ruzicka@gmail.com"
git -C tmp clone git@github.com:ruzickap/k8s-flux-repository.git
```

Output:

```text
Cloning into 'k8s-flux-repository'...
warning: You appear to have cloned an empty repository
```

Create initial flux repository structure and add it into the git repository:

```bash
cp -v files/flux-repository/README.md tmp/k8s-flux-repository/
mkdir -v tmp/k8s-flux-repository/{namespaces,releases,workloads}

git -C tmp/k8s-flux-repository add .
git -C tmp/k8s-flux-repository commit -m "Initial commit"
git -C tmp/k8s-flux-repository push -q
```

Output:

```text
'files/flux-repository/README.md' -> 'tmp/k8s-flux-repository/README.md'
mkdir: created directory 'tmp/k8s-flux-repository/namespaces'
mkdir: created directory 'tmp/k8s-flux-repository/releases'
mkdir: created directory 'tmp/k8s-flux-repository/workloads'
[master (root-commit) 6b7646c] Initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 237 bytes | 237.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To github.com:ruzickap/k8s-flux-repository.git
 * [new branch]      master -> master
```

## Install Helm

Install [Helm](https://helm.sh/) binary:

```bash
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- --version v2.14.3
```

Output:

```text
Helm v2.14.3 is already v2.14.3
Run 'helm init' to configure helm.
```

Create a service account and a cluster role binding for Tiller:

```bash
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller
```

Output:

```text
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-rule created
```

Deploy Tiller in `kube-system` namespace:

```bash
helm init --skip-refresh --upgrade --service-account tiller --history-max 10 --wait
```

Output:

```text
Creating /home/pruzicka/.helm
Creating /home/pruzicka/.helm/repository
Creating /home/pruzicka/.helm/repository/cache
Creating /home/pruzicka/.helm/repository/local
Creating /home/pruzicka/.helm/plugins
Creating /home/pruzicka/.helm/starters
Creating /home/pruzicka/.helm/cache/archive
Creating /home/pruzicka/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /home/pruzicka/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
```

Check if the tiller was installed properly:

```bash
kubectl get pods -l app=helm -n kube-system
```

Output:

```text
NAME                             READY   STATUS    RESTARTS   AGE
tiller-deploy-7b8b4499b5-hgpfm   1/1     Running   0          14s
```

## Install Flux

Add the Flux repository:

```bash
helm repo add fluxcd https://charts.fluxcd.io
helm update
```

Output:

```text
"fluxcd" has been added to your repositories
Command "update" is deprecated, use 'helm repo update'

Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "fluxcd" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete.
```

Apply the Helm Release CRD:

```bash
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml
```

Output:

```text
customresourcedefinition.apiextensions.k8s.io/helmreleases.flux.weave.works created
```

Install Flux:

```bash
helm install --name flux --namespace flux --wait --version 0.12.0 fluxcd/flux \
  --set git.email="petr.ruzicka@gmail.com" \
  --set git.url=git@github.com:ruzickap/k8s-flux-repository \
  --set git.user="Flux" \
  --set helmOperator.create=true \
  --set helmOperator.createCRD=false \
  --set registry.insecureHosts="harbor.${MY_DOMAIN}" \
  --set registry.pollInterval="1m" \
  --set syncGarbageCollection.enabled=true
```

Output:

```text
NAME:   flux
LAST DEPLOYED: Thu Aug 22 10:12:20 2019
NAMESPACE: flux
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME              DATA  AGE
flux-kube-config  1     42s

==> v1/Deployment
NAME                READY  UP-TO-DATE  AVAILABLE  AGE
flux                1/1    1           1          42s
flux-helm-operator  1/1    1           1          42s
flux-memcached      1/1    1           1          42s

==> v1/Pod(related)
NAME                                 READY  STATUS   RESTARTS  AGE
flux-585f49f8b9-vwncn                1/1    Running  0         42s
flux-helm-operator-6877b9f564-sqpv2  1/1    Running  0         42s
flux-memcached-8545bfdbdd-hlcnz      1/1    Running  0         42s

==> v1/Secret
NAME             TYPE    DATA  AGE
flux-git-deploy  Opaque  1     42s

==> v1/Service
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
flux            ClusterIP  100.68.237.154  <none>       3030/TCP   42s
flux-memcached  ClusterIP  100.67.222.178  <none>       11211/TCP  42s

==> v1/ServiceAccount
NAME  SECRETS  AGE
flux  1        42s

==> v1beta1/ClusterRole
NAME  AGE
flux  42s

==> v1beta1/ClusterRoleBinding
NAME  AGE
flux  42s


NOTES:
Get the Git deploy key by either (a) running

  kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

or by (b) installing fluxctl through
https://github.com/weaveworks/flux/blob/master/docs/references/fluxctl.md#installing-fluxctl
and running:

  fluxctl identity
```

Install fluxcli:

```bash
sudo wget -q -c https://github.com/fluxcd/flux/releases/download/1.14.0/fluxctl_linux_amd64 -O /usr/local/bin/fluxctl
sudo chmod a+x /usr/local/bin/fluxctl
```

Set the namespace (`flux`) where flux was installed for running `fluxctl`:

```bash
export FLUX_FORWARD_NAMESPACE=flux
```

Obtain the ssh public key through `fluxctl`:

```bash
fluxctl identity
if [ -x /usr/bin/chromium-browser ]; then chromium-browser https://github.com/ruzickap/k8s-flux-repository/settings/keys/new & fi
```

Output:

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIwnEd0awRYwZbcHukvovcJqllWll7DthW4NYX3Y3Kr8j/ZqgIbMJbmF2E5bwvRk0puUfSFynMVuEZUu+1KqfPhcCFjY5AzjFHQqdrvoLMeuRx9wY0lAYCwbVUqPedCwkeHOCnpgtM+I3nW3AhlotIOgdzKebR+Ox7jjke0L4cuR7IySxhQdkrdwJtq0miN3zmWu8W4LplSBs0PdQYXrl1ApBZ39fB+WPgrorwvtIgCnXYSgyfj9d50VWZjpNdnLRB1etiKHqr1uF3e5cxNyc7CKn/A5L8Dkl9Aa2JS/IHp5ErNyfGzJrkiQs1V92k37xGHPDDkhxZhtI8gvkRy/Ar
```

Add the ssh key to the GitHub "[https://github.com/ruzickap/k8s-flux-repository](https://github.com/ruzickap/k8s-flux-repository)"
-> "Settings" -> "Deploy keys" -> "Add new" -> "Allow write access"

-----

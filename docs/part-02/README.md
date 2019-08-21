# Install Helm + Flux

It's necessary to create git repository for Flux:

```bash
hub create -d "Flux repository for k8s-flux-istio-gitlab-harbor" -h "https://ruzickap.github.io/k8s-flux-istio-gitlab-harbor/" ruzickap/k8s-flux-repository
```

```bash
git -C tmp clone git@github.com:ruzickap/k8s-flux-repository.git
```

```bash
cp -R files/flux-repository/README.md tmp/k8s-flux-repository/
mkdir tmp/k8s-flux-repository/{namespaces,releases,workloads}
```

```bash
git -C tmp/k8s-flux-repository add .
git -C tmp/k8s-flux-repository commit -m "Initial commit"
git -C tmp/k8s-flux-repository push
```

## Install Helm

Install [Helm](https://helm.sh/) binary:

```bash
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- --version v2.14.3
```

Output:

```text
```

Create a service account and a cluster role binding for Tiller:

```bash
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller
```

Deploy Tiller in `kube-system` namespace:

```bash
helm init --skip-refresh --upgrade --service-account tiller --history-max 10 --wait
```

Check if the tiller was installed properly:

```bash
kubectl get pods -l app=helm -n kube-system
```

Output:

```text
```

## Install Flux

Add the Flux repository:

```bash
helm repo add fluxcd https://charts.fluxcd.io
helm update
```

Apply the Helm Release CRD:

```bash
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml
```

```bash
helm install --name flux --namespace flux --wait fluxcd/flux \
  --set git.email="petr.ruzicka@gmail.com" \
  --set git.url=git@github.com:ruzickap/k8s-flux-repository \
  --set git.user="Flux" \
  --set helmOperator.create=true \
  --set helmOperator.createCRD=false \
  --set syncGarbageCollection.enabled=true
```

Install fluxcli:

```bash
sudo wget -q -c https://github.com/fluxcd/flux/releases/download/1.13.3/fluxctl_linux_amd64 -O /usr/local/bin/fluxctl
sudo chmod a+x /usr/local/bin/fluxctl
```

Set the namespace (`flux`) where flux was installed for running `fluxctl`:

```bash
export FLUX_FORWARD_NAMESPACE=flux
```

Get the Flux public ssh key

```bash
fluxctl identity
chromium-browser https://github.com/ruzickap/k8s-flux-repository/settings/keys/new &
```

Add the key to the GitHub "[https://github.com/ruzickap/k8s-flux-repository](https://github.com/ruzickap/k8s-flux-repository)"
-> "Settings" -> "Deploy keys" -> "Add new" -> "Allow write access"

-----

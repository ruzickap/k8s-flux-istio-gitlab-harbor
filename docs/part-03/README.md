# Install basic application using Flux

## cert-manager

```bash
envsubst < files/flux-repository/namespaces/cert-manager-ns.yaml     > tmp/k8s-flux-repository/namespaces/cert-manager-ns.yaml
envsubst < files/flux-repository/releases/cert-manager-release.yaml  > tmp/k8s-flux-repository/releases/cert-manager-release.yaml
envsubst < files/flux-repository/workloads/cert-manager-00-crds.yaml > tmp/k8s-flux-repository/workloads/cert-manager-00-crds.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add cert-manager"
git -C tmp/k8s-flux-repository push -q
```

Output:

```text
add 'namespaces/cert-manager-ns.yaml'
add 'releases/cert-manager-release.yaml'
add 'workloads/cert-manager-00-crds.yaml'
[master 90f78a1] Add cert-manager
 3 files changed, 1458 insertions(+)
 create mode 100644 namespaces/cert-manager-ns.yaml
 create mode 100644 releases/cert-manager-release.yaml
 create mode 100644 workloads/cert-manager-00-crds.yaml
```

Let Flux to sync the configuration from git repository:

```bash
sleep 30
fluxctl sync
```

Output:

```text
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is 90f78a1
Waiting for 90f78a1 to be applied ...
Done.
```

Create `ClusterIssuer`:

```bash
export ROUTE53_AWS_SECRET_ACCESS_KEY_BASE64=$(echo -n "$ROUTE53_AWS_SECRET_ACCESS_KEY" | base64)
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: aws-route53-secret-access-key-secret
  namespace: cert-manager
data:
  secret-access-key: $ROUTE53_AWS_SECRET_ACCESS_KEY_BASE64
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-dns
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: petr.ruzicka@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging-dns
    dns01:
      providers:
      - name: aws-route53
        route53:
          accessKeyID: ${ROUTE53_AWS_ACCESS_KEY_ID}
          region: eu-central-1
          secretAccessKeySecretRef:
            name: aws-route53-secret-access-key-secret
            key: secret-access-key
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production-dns
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: petr.ruzicka@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production-dns
    dns01:
      providers:
      - name: aws-route53
        route53:
          accessKeyID: ${ROUTE53_AWS_ACCESS_KEY_ID}
          region: eu-central-1
          secretAccessKeySecretRef:
            name: aws-route53-secret-access-key-secret
            key: secret-access-key
EOF
```

Output:

```text
secret/aws-route53-secret-access-key-secret created
clusterissuer.certmanager.k8s.io/letsencrypt-staging-dns created
clusterissuer.certmanager.k8s.io/letsencrypt-production-dns created
```

Create certificate using cert-manager:

```bash
cat << EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  namespace: cert-manager
spec:
  secretName: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-${LETSENCRYPT_ENVIRONMENT}-dns
  commonName: "*.${MY_DOMAIN}"
  dnsNames:
  - "*.${MY_DOMAIN}"
  acme:
    config:
    - dns01:
        provider: aws-route53
      domains:
      - "*.${MY_DOMAIN}"
EOF
```

Output:

```text
certificate.certmanager.k8s.io/ingress-cert-staging created
```

## kubed

Install [kubed](https://github.com/appscode/kubed):

```bash
envsubst < files/flux-repository/namespaces/kubed-ns.yaml    > tmp/k8s-flux-repository/namespaces/kubed-ns.yaml
envsubst < files/flux-repository/releases/kubed-release.yaml > tmp/k8s-flux-repository/releases/kubed-release.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add kubed"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

Output:

```text
add 'namespaces/kubed-ns.yaml'
add 'releases/kubed-release.yaml'
[master 869bc1b] Add kubed
 2 files changed, 23 insertions(+)
 create mode 100644 namespaces/kubed-ns.yaml
 create mode 100644 releases/kubed-release.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is 869bc1b
Waiting for 869bc1b to be applied ...
Done.
```

Annotate (mark) the cert-manager secret to be copied to other namespaces
if necessary:

```bash
kubectl annotate secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n cert-manager kubed.appscode.com/sync="app=kubed"
```

Output:

```text
secret/ingress-cert-staging annotated
```

## Istio

Install [Istio](https://istio.io/) by installing the `istio-init`:

```bash
envsubst < files/flux-repository/namespaces/istio-ns.yaml         > tmp/k8s-flux-repository/namespaces/istio-ns.yaml
envsubst < files/flux-repository/releases/istio-init-release.yaml > tmp/k8s-flux-repository/releases/istio-init-release.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add Istio init"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
sleep 10
```

Output:

```text
add 'namespaces/istio-ns.yaml'
add 'releases/istio-init-release.yaml'
[master a86b69c] Add istio-init
 2 files changed, 21 insertions(+)
 create mode 100644 namespaces/istio-ns.yaml
 create mode 100644 releases/istio-init-release.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is a86b69c
Waiting for a86b69c to be applied ...
Done.
```

Install [Istio](https://istio.io/):

```bash
envsubst < files/flux-repository/releases/istio-release.yaml   > tmp/k8s-flux-repository/releases/istio-release.yaml
envsubst < files/flux-repository/workloads/istio-gateway.yaml  > tmp/k8s-flux-repository/workloads/istio-gateway.yaml
envsubst < files/flux-repository/workloads/istio-services.yaml > tmp/k8s-flux-repository/workloads/istio-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add Istio"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
sleep 200
```

Output:

```text
add 'releases/istio-release.yaml'
add 'workloads/istio-gateway.yaml'
add 'workloads/istio-services.yaml'
[master 8ea8110] Add istio
 3 files changed, 177 insertions(+)
 create mode 100644 releases/istio-release.yaml
 create mode 100644 workloads/istio-gateway.yaml
 create mode 100644 workloads/istio-services.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is 8ea8110
Waiting for 8ea8110 to be applied ...
Done.
```

Create DNS record `mylabs.dev` for the loadbalancer created by Istio:

```bash
export LOADBALANCER_HOSTNAME=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
export CANONICAL_HOSTED_ZONE_NAME_ID=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName==\`$LOADBALANCER_HOSTNAME\`].CanonicalHostedZoneNameID" --output text)
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text)

envsubst < files/aws_route53-dns_change.json | aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch=file:///dev/stdin
```

## Harbor

Install Harbor:

```bash
envsubst < files/flux-repository/namespaces/harbor-ns.yaml      > tmp/k8s-flux-repository/namespaces/harbor-ns.yaml
envsubst < files/flux-repository/releases/harbor-release.yaml   > tmp/k8s-flux-repository/releases/harbor-release.yaml
envsubst < files/flux-repository/workloads/harbor-services.yaml > tmp/k8s-flux-repository/workloads/harbor-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add Harbor"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

## Prepare docker images

Clone [kuard](https://github.com/kubernetes-up-and-running/kuard):

```bash
git -C tmp clone https://github.com/kubernetes-up-and-running/kuard
```

Build `kuard` container image and push it to
`harbor.mylabs.dev/library/kuard:v1`:

```bash
docker build --tag harbor.${MY_DOMAIN}/library/kuard:v1 tmp/kuard
echo admin | docker login --username admin --password-stdin harbor.${MY_DOMAIN}
docker push harbor.${MY_DOMAIN}/library/kuard:v1
```

"Pre-build" the second docker image:

```bash
sed -i "s/ENV VERSION=test/ENV VERSION=new_version/" tmp/kuard/Dockerfile
docker build --tag delete_me tmp/kuard
sed -i "s/ENV VERSION=new_version/ENV VERSION=test/" tmp/kuard/Dockerfile
```

Open these URLs to verify everything is working:

* [https://grafana.mylabs.dev](https://grafana.mylabs.dev), [http://grafana.mylabs.dev](http://grafana.mylabs.dev)
* [https://jaeger.mylabs.dev](https://jaeger.mylabs.dev), [http://jaeger.mylabs.dev](http://jaeger.mylabs.dev)
* [https://kiali.mylabs.dev](https://kiali.mylabs.dev), [http://kiali.mylabs.dev](http://kiali.mylabs.dev)
* [https://prometheus.mylabs.dev](https://prometheus.mylabs.dev), [http://prometheus.mylabs.dev](http://prometheus.mylabs.dev)
* [https://harbor.mylabs.dev](https://harbor.mylabs.dev), [http://harbor.mylabs.dev](http://harbor.mylabs.dev)

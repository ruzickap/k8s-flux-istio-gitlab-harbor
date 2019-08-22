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

```bash
sleep 15
fluxctl sync
```

Output:

```text
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is 90f78a1
Waiting for 90f78a1 to be applied ...
Done.
```

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

```bash
envsubst < files/flux-repository/namespaces/istio-ns.yaml         > tmp/k8s-flux-repository/namespaces/istio-ns.yaml
envsubst < files/flux-repository/releases/istio-init-release.yaml > tmp/k8s-flux-repository/releases/istio-init-release.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add istio-init"
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

```bash
envsubst < files/flux-repository/releases/istio-release.yaml   > tmp/k8s-flux-repository/releases/istio-release.yaml
envsubst < files/flux-repository/workloads/istio-gateway.yaml  > tmp/k8s-flux-repository/workloads/istio-gateway.yaml
envsubst < files/flux-repository/workloads/istio-services.yaml > tmp/k8s-flux-repository/workloads/istio-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add istio"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
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

## external-dns

Install [external-dns](https://github.com/kubernetes-incubator/external-dns) and
let it manage `mylabs.dev` entries in Route 53:

```bash
helm install --name external-dns --namespace external-dns --version 2.5.1 stable/external-dns \
  --set aws.credentials.accessKey="${ROUTE53_AWS_ACCESS_KEY_ID}" \
  --set aws.credentials.secretKey="${ROUTE53_AWS_SECRET_ACCESS_KEY}" \
  --set aws.region=eu-central-1 \
  --set domainFilters={${MY_DOMAIN}} \
  --set istioIngressGateways={istio-system/istio-ingressgateway} \
  --set policy="sync" \
  --set rbac.create=true \
  --set sources="{istio-gateway,service}" \
  --set txtOwnerId="${USER}-k8s.${MY_DOMAIN}"
```

Output:

```text
NAME:   external-dns
LAST DEPLOYED: Thu Aug 22 11:07:49 2019
NAMESPACE: external-dns
STATUS: DEPLOYED

RESOURCES:
==> v1/Deployment
NAME          READY  UP-TO-DATE  AVAILABLE  AGE
external-dns  0/1    1           0          0s

==> v1/Pod(related)
NAME                          READY  STATUS             RESTARTS  AGE
external-dns-ddd67cbc4-xdhbc  0/1    ContainerCreating  0         0s

==> v1/Secret
NAME          TYPE    DATA  AGE
external-dns  Opaque  1     0s

==> v1/Service
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
external-dns  ClusterIP  100.70.204.246  <none>       7979/TCP  0s

==> v1/ServiceAccount
NAME          SECRETS  AGE
external-dns  1        0s

==> v1beta1/ClusterRole
NAME          AGE
external-dns  0s

==> v1beta1/ClusterRoleBinding
NAME          AGE
external-dns  0s


NOTES:
** Please be patient while the chart is being deployed **

To verify that external-dns has started, run:

  kubectl --namespace=external-dns get pods -l "app.kubernetes.io/name=external-dns,app.kubernetes.io/instance=external-dns"
```

Open these URLs to verify everything is working:

* [https://grafana.mylabs.dev](https://grafana.mylabs.dev), [http://grafana.mylabs.dev](http://grafana.mylabs.dev)
* [https://jaeger.mylabs.dev](https://jaeger.mylabs.dev), [http://jaeger.mylabs.dev](http://jaeger.mylabs.dev)
* [https://kiali.mylabs.dev](https://kiali.mylabs.dev), [http://kiali.mylabs.dev](http://kiali.mylabs.dev)
* [https://prometheus.mylabs.dev](https://prometheus.mylabs.dev), [http://prometheus.mylabs.dev](http://prometheus.mylabs.dev)

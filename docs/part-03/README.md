# Install application using Flux

## cert-manager

```bash
envsubst < files/flux-repository/namespaces/cert-manager-ns.yaml     > tmp/k8s-flux-repository/namespaces/cert-manager-ns.yaml
envsubst < files/flux-repository/releases/cert-manager-release.yaml  > tmp/k8s-flux-repository/releases/cert-manager-release.yaml
envsubst < files/flux-repository/workloads/cert-manager-00-crds.yaml > tmp/k8s-flux-repository/workloads/cert-manager-00-crds.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add cert-manager"
git -C tmp/k8s-flux-repository push
```

```bash
sleep 15
fluxctl sync
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

## kubed

```bash
envsubst < files/flux-repository/namespaces/kubed-ns.yaml    > tmp/k8s-flux-repository/namespaces/kubed-ns.yaml
envsubst < files/flux-repository/releases/kubed-release.yaml > tmp/k8s-flux-repository/releases/kubed-release.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add kubed"
git -C tmp/k8s-flux-repository push
```

```bash
fluxctl sync
```

Annotate (mark) the cert-manager secret to be copied to other namespaces
if necessary:

```bash
kubectl annotate secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n cert-manager kubed.appscode.com/sync="app=kubed"
```

## Istio

```bash
envsubst < files/flux-repository/namespaces/istio-ns.yaml         > tmp/k8s-flux-repository/namespaces/istio-ns.yaml
envsubst < files/flux-repository/releases/istio-init-release.yaml > tmp/k8s-flux-repository/releases/istio-init-release.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add istio-init"
git -C tmp/k8s-flux-repository push
```

```bash
fluxctl sync
sleep 10
```

```bash
envsubst < files/flux-repository/releases/istio-release.yaml   > tmp/k8s-flux-repository/releases/istio-release.yaml
envsubst < files/flux-repository/workloads/istio-gateway.yaml  > tmp/k8s-flux-repository/workloads/istio-gateway.yaml
envsubst < files/flux-repository/workloads/istio-services.yaml > tmp/k8s-flux-repository/workloads/istio-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add istio"
git -C tmp/k8s-flux-repository push
```

```bash
fluxctl sync
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

```json
```

## Harbor

```bash
envsubst < files/flux-repository/namespaces/harbor-ns.yaml      > tmp/k8s-flux-repository/namespaces/harbor-ns.yaml
envsubst < files/flux-repository/releases/harbor-release.yaml   > tmp/k8s-flux-repository/releases/harbor-release.yaml
envsubst < files/flux-repository/workloads/harbor-services.yaml > tmp/k8s-flux-repository/workloads/harbor-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add harbor"
git -C tmp/k8s-flux-repository push
```

```bash
fluxctl sync
```

## GitLab

```bash
envsubst < files/flux-repository/namespaces/gitlab-ns.yaml                          > tmp/k8s-flux-repository/namespaces/gitlab-ns.yaml
envsubst < files/flux-repository/releases/gitlab-release.yaml                       > tmp/k8s-flux-repository/releases/gitlab-release.yaml
envsubst < files/flux-repository/workloads/gitlab-custom-ca.yaml                    > tmp/k8s-flux-repository/workloads/gitlab-custom-ca.yaml
envsubst < files/flux-repository/workloads/gitlab-gitlab-initial-root-password.yaml > tmp/k8s-flux-repository/workloads/gitlab-gitlab-initial-root-password.yaml
envsubst < files/flux-repository/workloads/gitlab-services.yaml                     > tmp/k8s-flux-repository/workloads/gitlab-services.yaml

git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add GitLab"
git -C tmp/k8s-flux-repository push
```

```bash
fluxctl sync
```

Try to open these URLs:

* [https://harbor.mylabs.dev](https://harbor.mylabs.dev)
* [http://harbor.mylabs.dev](http://harbor.mylabs.dev)
* [https://gitlab.mylabs.dev](https://gitlab.mylabs.dev)
* [http://gitlab.mylabs.dev](http://gitlab.mylabs.dev)
* `ssh://gitlab.mylabs.dev`
* [https://grafana.mylabs.dev](https://grafana.mylabs.dev)
* [http://grafana.mylabs.dev](http://grafana.mylabs.dev)
* [https://jaeger.mylabs.dev](https://jaeger.mylabs.dev)
* [http://jaeger.mylabs.dev](http://jaeger.mylabs.dev)
* [https://kiali.mylabs.dev](https://kiali.mylabs.dev)
* [http://kiali.mylabs.dev](http://kiali.mylabs.dev)
* [https://prometheus.mylabs.dev](https://prometheus.mylabs.dev)
* [http://prometheus.mylabs.dev](http://prometheus.mylabs.dev)

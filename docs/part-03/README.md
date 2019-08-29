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
[master 6284194] Add cert-manager
 3 files changed, 1460 insertions(+)
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
Revision of master to apply is 6284194
Waiting for 6284194 to be applied ...
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
sleep 5
```

Output:

```text
certificate.certmanager.k8s.io/ingress-cert-production created
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
[master fee3f31] Add kubed
 2 files changed, 24 insertions(+)
 create mode 100644 namespaces/kubed-ns.yaml
 create mode 100644 releases/kubed-release.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is fee3f31
Waiting for fee3f31 to be applied ...
Done.
```

Annotate (mark) the cert-manager secret to be copied to other namespaces
if necessary:

```bash
kubectl annotate secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n cert-manager kubed.appscode.com/sync="app=kubed"
```

Output:

```text
secret/ingress-cert-production annotated
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
[master ff90dcd] Add Istio init
 2 files changed, 22 insertions(+)
 create mode 100644 namespaces/istio-ns.yaml
 create mode 100644 releases/istio-init-release.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is ff90dcd
Waiting for ff90dcd to be applied ...
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
[master 6d6f49b] Add Istio
 3 files changed, 180 insertions(+)
 create mode 100644 releases/istio-release.yaml
 create mode 100644 workloads/istio-gateway.yaml
 create mode 100644 workloads/istio-services.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is 6d6f49b
Waiting for 6d6f49b to be applied ...
Done.
```

Create DNS record `mylabs.dev` for the loadbalancer created by Istio:

```bash
export LOADBALANCER_HOSTNAME=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
export CANONICAL_HOSTED_ZONE_NAME_ID=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName==\`$LOADBALANCER_HOSTNAME\`].CanonicalHostedZoneNameID" --output text)
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text)

envsubst < files/aws_route53-dns_change.json | aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch=file:///dev/stdin
```

Output:

```json
{
    "ChangeInfo": {
        "Id": "/change/CKGC5VND57XVI",
        "Status": "PENDING",
        "SubmittedAt": "2019-08-29T07:45:55.744Z",
        "Comment": "A new record set for the zone."
    }
}
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

Output:

```text
add 'namespaces/harbor-ns.yaml'
add 'releases/harbor-release.yaml'
add 'workloads/harbor-services.yaml'
[master dd95b25] Add Harbor
 3 files changed, 119 insertions(+)
 create mode 100644 namespaces/harbor-ns.yaml
 create mode 100644 releases/harbor-release.yaml
 create mode 100644 workloads/harbor-services.yaml
Synchronizing with git@github.com:ruzickap/k8s-flux-repository
Revision of master to apply is dd95b25
Waiting for dd95b25 to be applied ...
Done.
```

## Prepare docker images

Clone [kuard](https://github.com/kubernetes-up-and-running/kuard):

```bash
git -C tmp clone https://github.com/kubernetes-up-and-running/kuard
```

Output:

```text
Cloning into 'kuard'...
remote: Enumerating objects: 4, done.
remote: Counting objects: 100% (4/4), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 1404 (delta 0), reused 4 (delta 0), pack-reused 1400
Receiving objects: 100% (1404/1404), 2.18 MiB | 3.82 MiB/s, done.
Resolving deltas: 100% (486/486), done.
```

Build `kuard` container image and push it to
`harbor.mylabs.dev/library/kuard:v1`:

```bash
docker build --tag harbor.${MY_DOMAIN}/library/kuard:v1 tmp/kuard
echo admin | docker login --username admin --password-stdin harbor.${MY_DOMAIN}
docker push harbor.${MY_DOMAIN}/library/kuard:v1
```

Output:

```text
Sending build context to Docker daemon  3.378MB
Step 1/14 : FROM golang:1.12-alpine AS build
1.12-alpine: Pulling from library/golang
9d48c3bd43c5: Already exists
7f94eaf8af20: Already exists
9fe9984849c1: Already exists
cf0db633a67d: Already exists
0f7136d71739: Already exists
Digest: sha256:e0660b4f1e68e0d408420acb874b396fc6dd25e7c1d03ad36e7d6d1155a4dff6
Status: Downloaded newer image for golang:1.12-alpine
 ---> e0d646523991
Step 2/14 : RUN apk update && apk upgrade && apk add --no-cache git nodejs bash npm
 ---> Running in baec888bed54
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
v3.10.2-22-gb819553afa [http://dl-cdn.alpinelinux.org/alpine/v3.10/main]
v3.10.2-20-ga23f3d183a [http://dl-cdn.alpinelinux.org/alpine/v3.10/community]
OK: 10334 distinct packages available
OK: 6 MiB in 15 packages
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
(1/17) Installing ncurses-terminfo-base (6.1_p20190518-r0)
(2/17) Installing ncurses-terminfo (6.1_p20190518-r0)
(3/17) Installing ncurses-libs (6.1_p20190518-r0)
(4/17) Installing readline (8.0.0-r0)
(5/17) Installing bash (5.0.0-r0)
Executing bash-5.0.0-r0.post-install
(6/17) Installing nghttp2-libs (1.39.2-r0)
(7/17) Installing libcurl (7.65.1-r0)
(8/17) Installing expat (2.2.7-r0)
(9/17) Installing pcre2 (10.33-r0)
(10/17) Installing git (2.22.0-r0)
(11/17) Installing c-ares (1.15.0-r0)
(12/17) Installing libgcc (8.3.0-r0)
(13/17) Installing http-parser (2.9.2-r0)
(14/17) Installing libstdc++ (8.3.0-r0)
(15/17) Installing libuv (1.29.1-r0)
(16/17) Installing nodejs (10.16.3-r0)
(17/17) Installing npm (10.16.3-r0)
Executing busybox-1.30.1-r2.trigger
OK: 83 MiB in 32 packages
Removing intermediate container baec888bed54
 ---> a76e7141f9a2
Step 3/14 : RUN go get -u github.com/jteeuwen/go-bindata/...
 ---> Running in 3a73805b8df0
Removing intermediate container 3a73805b8df0
 ---> e809ae1cf8bc
Step 4/14 : WORKDIR /go/src/github.com/kubernetes-up-and-running/kuard
 ---> Running in 8d4abaec72d2
Removing intermediate container 8d4abaec72d2
 ---> 2789d5fd896f
Step 5/14 : COPY . .
 ---> 09cf2d1ce5ab
Step 6/14 : ENV VERBOSE=0
 ---> Running in 8bc543402831
Removing intermediate container 8bc543402831
 ---> 72225f2963bb
Step 7/14 : ENV PKG=github.com/kubernetes-up-and-running/kuard
 ---> Running in ac5988e3c6e0
Removing intermediate container ac5988e3c6e0
 ---> a553568d0612
Step 8/14 : ENV ARCH=amd64
 ---> Running in 2415a750ac6e
Removing intermediate container 2415a750ac6e
 ---> 2ee75018db33
Step 9/14 : ENV VERSION=test
 ---> Running in 77958a3dd12e
Removing intermediate container 77958a3dd12e
 ---> cd66dc4e3cd2
Step 10/14 : RUN build/build.sh
 ---> Running in 12a339b49a27
Verbose: 0

> webpack-cli@3.2.1 postinstall /go/src/github.com/kubernetes-up-and-running/kuard/client/node_modules/webpack-cli
> lightercollective


     *** Thank you for using webpack-cli! ***

Please consider donating to our open collective
     to help us maintain this package.

  https://opencollective.com/webpack/donate

                    ***

added 819 packages from 505 contributors and audited 8399 packages in 12.56s
found 247 vulnerabilities (1 moderate, 246 high)
  run `npm audit fix` to fix them, or `npm audit` for details

> client@1.0.0 build /go/src/github.com/kubernetes-up-and-running/kuard/client
> webpack --mode=production

Browserslist: caniuse-lite is outdated. Please run next command `npm update caniuse-lite browserslist`
Hash: 52ca742bfd1307531486
Version: webpack 4.28.4
Time: 8722ms
Built at: 08/29/2019 7:47:16 AM
    Asset     Size  Chunks                    Chunk Names
bundle.js  333 KiB       0  [emitted]  [big]  main
Entrypoint main [big] = bundle.js
 [26] (webpack)/buildin/global.js 472 bytes {0} [built]
[228] (webpack)/buildin/module.js 497 bytes {0} [built]
[236] (webpack)/buildin/amd-options.js 80 bytes {0} [built]
[252] ./src/index.jsx + 12 modules 57.6 KiB {0} [built]
      | ./src/index.jsx 285 bytes [built]
      | ./src/app.jsx 7.79 KiB [built]
      | ./src/env.jsx 5.42 KiB [built]
      | ./src/mem.jsx 5.81 KiB [built]
      | ./src/probe.jsx 7.64 KiB [built]
      | ./src/dns.jsx 5.1 KiB [built]
      | ./src/keygen.jsx 7.69 KiB [built]
      | ./src/request.jsx 3.01 KiB [built]
      | ./src/highlightlink.jsx 1.37 KiB [built]
      | ./src/disconnected.jsx 3.6 KiB [built]
      | ./src/memq.jsx 6.33 KiB [built]
      | ./src/fetcherror.js 122 bytes [built]
      | ./src/markdown.jsx 3.46 KiB [built]
    + 249 hidden modules
go: finding github.com/spf13/viper v1.3.2
go: finding github.com/dustin/go-humanize v1.0.0
go: finding github.com/pkg/errors v0.8.1
go: finding github.com/prometheus/client_golang v0.9.2
go: finding github.com/elazarl/go-bindata-assetfs v1.0.0
go: finding github.com/felixge/httpsnoop v1.0.0
go: finding github.com/miekg/dns v1.1.6
go: finding github.com/julienschmidt/httprouter v1.2.0
go: finding github.com/BurntSushi/toml v0.3.1
go: finding golang.org/x/crypto v0.0.0-20190313024323-a1f597ede03a
go: finding golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a
go: finding github.com/spf13/pflag v1.0.3
go: finding github.com/pelletier/go-toml v1.2.0
go: finding github.com/coreos/go-etcd v2.0.0+incompatible
go: finding github.com/stretchr/testify v1.2.2
go: finding github.com/coreos/go-semver v0.2.0
go: finding github.com/spf13/jwalterweatherman v1.0.0
go: finding github.com/hashicorp/hcl v1.0.0
go: finding github.com/spf13/afero v1.1.2
go: finding golang.org/x/text v0.3.0
go: finding golang.org/x/crypto v0.0.0-20181203042331-505ab145d0a9
go: finding golang.org/x/sync v0.0.0-20181108010431-42b317875d0f
go: finding github.com/magiconair/properties v1.8.0
go: finding github.com/armon/consul-api v0.0.0-20180202201655-eb2c6b5be1b6
go: finding github.com/mitchellh/mapstructure v1.1.2
go: finding github.com/golang/protobuf v1.2.0
go: finding golang.org/x/sys v0.0.0-20181205085412-a5c9d58dba9a
go: finding github.com/coreos/etcd v3.3.10+incompatible
go: finding gopkg.in/yaml.v2 v2.2.2
go: finding golang.org/x/net v0.0.0-20181201002055-351d144fa1fc
go: finding github.com/matttproud/golang_protobuf_extensions v1.0.1
go: finding github.com/prometheus/common v0.0.0-20181126121408-4724e9255275
go: finding github.com/beorn7/perks v0.0.0-20180321164747-3a771d992973
go: finding github.com/prometheus/procfs v0.0.0-20181204211112-1dc9a6cbc91a
go: finding github.com/ugorji/go/codec v0.0.0-20181204163529-d75b2dcb6bc8
go: finding github.com/prometheus/client_model v0.0.0-20180712105110-5c3871d89910
go: finding github.com/xordataexchange/crypt v0.0.3-0.20170626215501-b2862e3d0a77
go: finding github.com/spf13/cast v1.3.0
go: finding github.com/fsnotify/fsnotify v1.4.7
go: finding gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405
go: finding github.com/davecgh/go-spew v1.1.1
go: finding github.com/pmezard/go-difflib v1.0.0
go: downloading github.com/dustin/go-humanize v1.0.0
go: downloading golang.org/x/crypto v0.0.0-20190313024323-a1f597ede03a
go: downloading github.com/spf13/pflag v1.0.3
go: downloading github.com/felixge/httpsnoop v1.0.0
go: downloading github.com/julienschmidt/httprouter v1.2.0
go: downloading github.com/elazarl/go-bindata-assetfs v1.0.0
go: downloading github.com/pkg/errors v0.8.1
go: extracting github.com/dustin/go-humanize v1.0.0
go: extracting github.com/felixge/httpsnoop v1.0.0
go: downloading github.com/prometheus/client_golang v0.9.2
go: downloading github.com/spf13/viper v1.3.2
go: extracting github.com/spf13/pflag v1.0.3
go: extracting github.com/pkg/errors v0.8.1
go: extracting github.com/julienschmidt/httprouter v1.2.0
go: extracting github.com/elazarl/go-bindata-assetfs v1.0.0
go: downloading github.com/miekg/dns v1.1.6
go: extracting github.com/spf13/viper v1.3.2
go: downloading github.com/mitchellh/mapstructure v1.1.2
go: downloading gopkg.in/yaml.v2 v2.2.2
go: downloading github.com/spf13/jwalterweatherman v1.0.0
go: downloading github.com/hashicorp/hcl v1.0.0
go: downloading github.com/magiconair/properties v1.8.0
go: downloading github.com/pelletier/go-toml v1.2.0
go: downloading github.com/fsnotify/fsnotify v1.4.7
go: extracting github.com/prometheus/client_golang v0.9.2
go: downloading github.com/golang/protobuf v1.2.0
go: extracting github.com/mitchellh/mapstructure v1.1.2
go: downloading github.com/prometheus/client_model v0.0.0-20180712105110-5c3871d89910
go: extracting github.com/spf13/jwalterweatherman v1.0.0
go: extracting github.com/fsnotify/fsnotify v1.4.7
go: downloading github.com/prometheus/common v0.0.0-20181126121408-4724e9255275
go: downloading github.com/prometheus/procfs v0.0.0-20181204211112-1dc9a6cbc91a
go: extracting github.com/magiconair/properties v1.8.0
go: downloading github.com/spf13/cast v1.3.0
go: extracting github.com/pelletier/go-toml v1.2.0
go: extracting gopkg.in/yaml.v2 v2.2.2
go: downloading github.com/spf13/afero v1.1.2
go: downloading golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a
go: extracting github.com/hashicorp/hcl v1.0.0
go: extracting github.com/prometheus/client_model v0.0.0-20180712105110-5c3871d89910
go: extracting github.com/spf13/cast v1.3.0
go: downloading github.com/beorn7/perks v0.0.0-20180321164747-3a771d992973
go: extracting github.com/beorn7/perks v0.0.0-20180321164747-3a771d992973
go: extracting github.com/prometheus/common v0.0.0-20181126121408-4724e9255275
go: extracting github.com/spf13/afero v1.1.2
go: downloading golang.org/x/text v0.3.0
go: downloading github.com/matttproud/golang_protobuf_extensions v1.0.1
go: extracting github.com/prometheus/procfs v0.0.0-20181204211112-1dc9a6cbc91a
go: extracting github.com/matttproud/golang_protobuf_extensions v1.0.1
go: extracting github.com/golang/protobuf v1.2.0
go: extracting golang.org/x/crypto v0.0.0-20190313024323-a1f597ede03a
go: extracting github.com/miekg/dns v1.1.6
go: downloading golang.org/x/net v0.0.0-20181201002055-351d144fa1fc
go: extracting golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a
go: extracting golang.org/x/net v0.0.0-20181201002055-351d144fa1fc
go: extracting golang.org/x/text v0.3.0
Removing intermediate container 12a339b49a27
 ---> b9109e26bb7a
Step 11/14 : FROM alpine
latest: Pulling from library/alpine
9d48c3bd43c5: Already exists
Digest: sha256:72c42ed48c3a2db31b7dafe17d275b634664a708d901ec9fd57b1529280f01fb
Status: Downloaded newer image for alpine:latest
 ---> 961769676411
Step 12/14 : USER nobody:nobody
 ---> Running in 5537a9c9e76b
Removing intermediate container 5537a9c9e76b
 ---> ae127ae912d6
Step 13/14 : COPY --from=build /go/bin/kuard /kuard
 ---> 7fae33a9c5b8
Step 14/14 : CMD [ "/kuard" ]
 ---> Running in 219825d3419a
Removing intermediate container 219825d3419a
 ---> 647aa8b7809d
Successfully built 647aa8b7809d
Successfully tagged harbor.mylabs.dev/library/kuard:v1
WARNING! Your password will be stored unencrypted in /home/pruzicka/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
The push refers to repository [harbor.mylabs.dev/library/kuard]
da5d66d6f82d: Pushed
03901b4a2ea8: Pushed
v1: digest: sha256:907e61de499613c77579736c7a54373ffde84150cb952768cd035f81508c4b88 size: 739
```

"Pre-build" the second docker image:

```bash
sed -i "s/ENV VERSION=test/ENV VERSION=new_version/" tmp/kuard/Dockerfile
docker build --tag delete_me tmp/kuard
sed -i "s/ENV VERSION=new_version/ENV VERSION=test/" tmp/kuard/Dockerfile
```

Output:

```text
Sending build context to Docker daemon  3.378MB
Step 1/14 : FROM golang:1.12-alpine AS build
...
Step 14/14 : CMD [ "/kuard" ]
 ---> Running in 8cf26fdfe261
Removing intermediate container 8cf26fdfe261
 ---> 652d18a08b2d
Successfully built 652d18a08b2d
Successfully tagged delete_me:latest
```

Open these URLs to verify everything is working:

* [https://grafana.mylabs.dev](https://grafana.mylabs.dev), [http://grafana.mylabs.dev](http://grafana.mylabs.dev)
* [https://jaeger.mylabs.dev](https://jaeger.mylabs.dev), [http://jaeger.mylabs.dev](http://jaeger.mylabs.dev)
* [https://kiali.mylabs.dev](https://kiali.mylabs.dev), [http://kiali.mylabs.dev](http://kiali.mylabs.dev)
* [https://prometheus.mylabs.dev](https://prometheus.mylabs.dev), [http://prometheus.mylabs.dev](http://prometheus.mylabs.dev)
* [https://harbor.mylabs.dev](https://harbor.mylabs.dev), [http://harbor.mylabs.dev](http://harbor.mylabs.dev)

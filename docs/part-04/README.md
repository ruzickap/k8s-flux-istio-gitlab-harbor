# Flux image operations

Install [podinfo](https://github.com/stefanprodan/podinfo) application using
Flux:

```bash
envsubst << EOF > tmp/k8s-flux-repository/workloads/podinfo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - name: podinfo
        image: "stefanprodan/podinfo:2.1.2"
        ports:
        - containerPort: 9898
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo-service
  namespace: default
  labels:
    app: podinfo
spec:
  type: ClusterIP
  selector:
    app: podinfo
  ports:
  - name: podinfo-http
    port: 9898
    protocol: TCP
    targetPort: 9898
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: podinfo-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-podinfo
      protocol: HTTP
    hosts:
    - podinfo.${MY_DOMAIN}
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: podinfo-http-virtual-service
  namespace: default
spec:
  hosts:
  - podinfo.${MY_DOMAIN}
  gateways:
  - podinfo-gateway
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: podinfo-service.default.svc.cluster.local
        port:
          number: 9898
EOF
```

Add it to the git repository and let Flux to deploy the application:

```bash
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add podinfo"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
sleep 150
```

```bash
curl http://podinfo.mylabs.dev
if [ -x /usr/bin/chromium-browser ]; then chromium-browser http://podinfo.mylabs.dev & fi
```

Output:

```json
{
  "hostname": "podinfo-56c6447655-mc7kp",
  "version": "2.1.2",
  "revision": "ab74d6ef0bd3c5f39090134f59b12837757e80b8",
  "color": "blue",
  "message": "greetings from podinfo v2.1.2",
  "goos": "linux",
  "goarch": "amd64",
  "runtime": "go1.12.7",
  "num_goroutine": "6",
  "num_cpu": "2"
}
```

::: tip
Workloads refers to any cluster resource responsible for the creation
of containers from versioned images - in Kubernetes these are objects such as
Deployments, DaemonSets, StatefulSets and CronJobs.
:::

Check whether Flux can see any running workloads:

```bash
fluxctl list-workloads
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                       RELEASE  POLICY
default:deployment/podinfo  podinfo    stefanprodan/podinfo:2.1.2  ready
```

Inspect which versions of the image are running in the workload:

```bash
fluxctl list-images --workload default:deployment/podinfo 2>/dev/null
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                 CREATED
default:deployment/podinfo  podinfo    stefanprodan/podinfo
                                       |   2.1.3             13 Aug 19 09:33 UTC
                                       |   latest            13 Aug 19 09:33 UTC
                                       '-> 2.1.2             13 Aug 19 07:53 UTC
                                           2.1.1             13 Aug 19 07:51 UTC
                                           2.1.0             07 Aug 19 13:18 UTC
                                           2.0.5             07 Aug 19 12:50 UTC
                                           2.0.4             07 Aug 19 12:48 UTC
                                           2.0.3             07 Aug 19 12:45 UTC
                                           2.0.2             07 Aug 19 12:41 UTC
                                           2.0.1             07 Aug 19 12:39 UTC
```

```bash
fluxctl release --workload=default:deployment/podinfo --user=pruzicka --message="New version" --update-all-images
```

Output:

```text
Submitting release ...
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success  podinfo: stefanprodan/podinfo:2.1.2 -> 2.1.3
Commit pushed:  87989e5
Commit applied: 87989e5
```

```bash
fluxctl list-images --workload default:deployment/podinfo 2>/dev/null
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                 CREATED
default:deployment/podinfo  podinfo    stefanprodan/podinfo
                                       '-> 2.1.3             13 Aug 19 09:33 UTC
                                           latest            13 Aug 19 09:33 UTC
                                           2.1.2             13 Aug 19 07:53 UTC
                                           2.1.1             13 Aug 19 07:51 UTC
...
```

```bash
kubectl describe pods | grep Image:
```

Output:

```text
    Image:          stefanprodan/podinfo:2.1.3
```

## Turning on Automation

```bash
fluxctl automate --workload=default:deployment/podinfo
```

Output:

```text
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success
Commit pushed:  99dd0ba
```

Flux will now automatically deploy a new version of a workload whenever one is available and commit the new configuration to the version control system.

```bash
fluxctl list-workloads
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                       RELEASE  POLICY
default:deployment/podinfo  podinfo    stefanprodan/podinfo:2.1.3  ready    automated
```

## Rolling back a Workload

```bash
fluxctl deautomate --workload=default:deployment/podinfo
```

Output:

```text
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success
Commit pushed:  806a45b
```

```bash
fluxctl release --workload=default:deployment/podinfo --update-image=stefanprodan/podinfo:2.1.2
```

Output:

```text
Submitting release ...
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success  podinfo: stefanprodan/podinfo:2.1.3 -> 2.1.2
Commit pushed:  a0f8e97
Commit applied: a0f8e97
```

```bash
fluxctl list-images --workload=default:deployment/podinfo
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                 CREATED
default:deployment/podinfo  podinfo    stefanprodan/podinfo
                                       |   2.1.3             13 Aug 19 09:33 UTC
                                       |   latest            13 Aug 19 09:33 UTC
                                       '-> 2.1.2             13 Aug 19 07:53 UTC
                                           2.1.1             13 Aug 19 07:51 UTC
...
```

# Image Tag Filtering

```bash
fluxctl policy --workload=default:deployment/podinfo --tag-all='2.0.*'
```

```text
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success
Commit pushed:  38d94be
```

```bash
git -C tmp/k8s-flux-repository pull -q
git -C tmp/k8s-flux-repository show
```

Output:

```text
commit 38d94be23eec28b9477b799f100d393a806c9085 (HEAD -> master, tag: flux-sync, origin/master)
Author: Flux <petr.ruzicka@gmail.com>
Date:   Thu Aug 22 12:45:03 2019 +0000

    Updated policies: default:deployment/podinfo

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
modified: workloads/podinfo.yaml
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
@ workloads/podinfo.yaml:7 @ kind: Deployment
metadata:
  name: podinfo
  namespace: default
  annotations:
    flux.weave.works/tag.podinfo: glob:2.0.*
spec:
  replicas: 1
  selector:
```


```bash
fluxctl release --workload=default:deployment/podinfo --update-all-images
```

Output:

```text
Submitting release ...
WORKLOAD                    STATUS   UPDATES
default:deployment/podinfo  success  podinfo: stefanprodan/podinfo:2.1.2 -> 2.0.5
Commit pushed:  af27a35
Commit applied: af27a35
```

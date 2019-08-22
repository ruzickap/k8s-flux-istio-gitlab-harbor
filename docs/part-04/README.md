# Flux operations

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
          image: "stefanprodan/podinfo:2.1.3"
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
git -C tmp/k8s-flux-repository commit -m "Add istio"
git -C tmp/k8s-flux-repository push
fluxctl sync
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
default:deployment/podinfo  podinfo    stefanprodan/podinfo:2.1.3  ready
```

Inspect which versions of the image are running in the workload:

```bash
fluxctl list-images --workload default:deployment/podinfo
```

Output:

```text
WORKLOAD                    CONTAINER  IMAGE                 CREATED
default:deployment/podinfo  podinfo    stefanprodan/podinfo
                                       '-> 2.1.3             13 Aug 19 09:33 UTC
                                           latest            13 Aug 19 09:33 UTC
                                           2.1.2             13 Aug 19 07:53 UTC
                                           2.1.1             13 Aug 19 07:51 UTC
                                           2.1.0             07 Aug 19 13:18 UTC
                                           2.0.5             07 Aug 19 12:50 UTC
                                           2.0.4             07 Aug 19 12:48 UTC
                                           2.0.3             07 Aug 19 12:45 UTC
                                           2.0.2             07 Aug 19 12:41 UTC
                                           2.0.1             07 Aug 19 12:39 UTC
```

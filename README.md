# Kubernetes + Flux + Istio + GitLab + Harbor

[![Build Status](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/workflows/vuepress-build/badge.svg)](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor)

* GitHub repository: [https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor)
* Web Pages: [https://ruzickap.github.io/k8s-flux-istio-gitlab-harbor](https://ruzickap.github.io/k8s-flux-istio-gitlab-harbor)

## Requirements

* [awscli](https://aws.amazon.com/cli/)
* [AWS IAM Authenticator for Kubernetes](https://github.com/kubernetes-sigs/aws-iam-authenticator)
* [AWS account](https://aws.amazon.com/account/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [kops](https://github.com/kubernetes/kops)
* [hub](https://hub.github.com/)
* Kubernetes, Docker, Linux, AWS knowledge required

## Content

* [Part 01 - Create "kops" cluster in AWS](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/tree/main/docs/part-01/README.md)
* [Part 02 - Install Helm + Flux](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/tree/main/docs/part-02/README.md)
* [Part 03 - Install cert-manager, kubed, Istio, Harbor using Flux](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/tree/main/docs/part-03/README.md)
* [Part 04 - Flux operations with container images (podinfo, kuard)](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/tree/main/docs/part-04/README.md)
* [Part 05 - Flux operations with Helm Charts (podinfo)](https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor/tree/main/docs/part-05/README.md)

## Links

* [https://github.com/justinbarrick/fluxcloud](https://github.com/justinbarrick/fluxcloud)
* [https://github.com/stefanprodan/gitops-istio](https://github.com/stefanprodan/gitops-istio)
* [https://github.com/stefanprodan/openfaas-flux](https://github.com/stefanprodan/openfaas-flux)
* [https://github.com/fluxcd/helm-operator-get-started](https://github.com/fluxcd/helm-operator-get-started)

![Flux logo](https://raw.githubusercontent.com/fluxcd/flux/18e5174581f44ed8c9a881dd5071179eed1ebf4d/docs/_files/flux-logo-vertical.svg?sanitize=true
"Flux logo")

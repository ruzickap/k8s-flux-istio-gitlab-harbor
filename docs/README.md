# Kubernetes + Flux + Istio + GitLab + Harbor

[![Build Status](https://travis-ci.com/ruzickap/k8s-flux-istio-gitlab-harbor.svg?branch=master)](https://travis-ci.com/ruzickap/k8s-flux-istio-gitlab-harbor)

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

* [Part 01 - Create "kops" cluster in AWS](part-01/README.md)
* [Part 02 - Install Helm + Flux](part-02/README.md)
* [Part 03 - Install cert-manager, kubed, Istio, Harbor using Flux](part-03/README.md)
* [Part 04 - Flux operations with container images (podinfo, kuard)](part-04/README.md)
* [Part 05 - Flux operations with Helm Charts (podinfo)](part-05/README.md)

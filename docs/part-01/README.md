# Create k8s cluster

Before starting with the main content, it's necessary to provision
the Kubernetes in AWS.

Use the `MY_DOMAIN` variable containing domain and `LETSENCRYPT_ENVIRONMENT`
variable.
The `LETSENCRYPT_ENVIRONMENT` variable should be one of:

* `staging` - Let’s Encrypt will create testing certificate (not valid)

* `production` - Let’s Encrypt will create valid certificate (use with care)

```bash
export MY_DOMAIN=${MY_DOMAIN:-mylabs.dev}
export LETSENCRYPT_ENVIRONMENT=${LETSENCRYPT_ENVIRONMENT:-staging}
echo "${MY_DOMAIN} | ${LETSENCRYPT_ENVIRONMENT}"
```

## Prepare the local working environment

::: tip
You can skip these steps if you have all the required software already
installed.
:::

Install necessary software:

```bash
if [ -x /usr/bin/apt ]; then
  apt update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli curl gettext-base git jq openssh-client sudo wget > /dev/null
fi
```

Install [kubectl](https://github.com/kubernetes/kubectl) binary:

```bash
if [ ! -x /usr/local/bin/kubectl ]; then
  sudo curl -s -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  sudo chmod a+x /usr/local/bin/kubectl
fi
```

Install [kops](https://github.com/kubernetes/kops):

```bash
if [ ! -x /usr/local/bin/kops ]; then
  sudo curl -s -L "https://github.com/kubernetes/kops/releases/download/1.14.0-alpha.3/kops-linux-amd64" > /usr/local/bin/kops
  sudo chmod a+x /usr/local/bin/kops
fi
```

Install [hub](https://hub.github.com/):

```bash
if [ ! -x /usr/local/bin/hub ]; then
  curl -s -L https://github.com/github/hub/releases/download/v2.12.3/hub-linux-amd64-2.12.3.tgz | tar xzf - -C /tmp/
  sudo mv /tmp/hub-linux-amd64-2.12.3/bin/hub /usr/local/bin/
fi
```

## Configure AWS

Authorize to AWS using AWS CLI: [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

```bash
aws configure
...
```

Create DNS zone:

```bash
aws route53 create-hosted-zone --name ${MY_DOMAIN} --caller-reference ${MY_DOMAIN}
```

Use your domain registrar to change the nameservers for your zone (for example
`mylabs.dev`) to use the Amazon Route 53 nameservers. Here is the way how you
can find out the the Route 53 nameservers:

```bash
aws route53 get-hosted-zone --id $(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text) --query "DelegationSet.NameServers"
```

Create policy allowing the cert-manager to change Route 53 settings. This will
allow cert-manager to generate wildcard SSL certificates by Let's Encrypt
certificate authority.

```bash
aws iam create-policy \
  --policy-name ${USER}-AmazonRoute53Domains-cert-manager \
  --description "Policy required by cert-manager to be able to modify Route 53 when generating wildcard certificates using Lets Encrypt" \
  --policy-document file://files/route_53_change_policy.json \
| jq
```

Output:

```json
{
  "Policy": {
    "PolicyName": "pruzicka-AmazonRoute53Domains-cert-manager",
    "PolicyId": "AxxxxxxxxxxxxxxxxxxxO",
    "Arn": "arn:aws:iam::822044714040:policy/pruzicka-AmazonRoute53Domains-cert-manager",
    "Path": "/",
    "DefaultVersionId": "v1",
    "AttachmentCount": 0,
    "IsAttachable": true,
    "CreateDate": "2019-08-29T07:32:23Z",
    "UpdateDate": "2019-08-29T07:32:23Z"
  }
}
```

Create user which will use the policy above allowing the cert-manager to change
Route 53 settings:

```bash
aws iam create-user --user-name ${USER}-route53 | jq && \
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName==\`${USER}-AmazonRoute53Domains-cert-manager\`].{ARN:Arn}" --output text) && \
aws iam attach-user-policy --user-name "${USER}-route53" --policy-arn $POLICY_ARN && \
aws iam create-access-key --user-name ${USER}-route53 > $HOME/.aws/${USER}-route53-${MY_DOMAIN} && \
export ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" $HOME/.aws/${USER}-route53-${MY_DOMAIN}) && \
export ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" $HOME/.aws/${USER}-route53-${MY_DOMAIN})
```

Output:

```json
{
  "User": {
    "Path": "/",
    "UserName": "pruzicka-route53",
    "UserId": "AxxxxxxxxxxxxxxxxxxxU",
    "Arn": "arn:aws:iam::822044714040:user/pruzicka-route53",
    "CreateDate": "2019-08-29T07:32:25Z"
  }
}
```

The `AccessKeyId` and `SecretAccessKey` is need for creating the `ClusterIssuer`
definition for `cert-manager`.

## Create K8s in AWS

![Architecture](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/3-service-animated.gif
"Architecture")

Generate SSH keys if not exists:

```bash
test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )
```

Clone the `k8s-flux-istio-gitlab-harbor` Git repository if it wasn't done already:

```bash
if [ ! -d .git ]; then
  git clone --quiet https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor && cd k8s-flux-istio-gitlab-harbor
fi
```

Create S3 bucket where the kops will store cluster status:

```bash
aws s3api create-bucket --bucket ${USER}-kops-k8s --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1 | jq
```

Output:

```json
{
    "Location": "http://pruzicka-kops-k8s.s3.amazonaws.com/"
}
```

Create Kubernetes cluster in AWS by using [kops](https://github.com/kubernetes/kops):

```bash
kops create cluster \
  --name=${USER}-k8s.${MY_DOMAIN} \
  --state=s3://${USER}-kops-k8s \
  --zones=eu-central-1a \
  --node-count=4 \
  --node-size=t3.large \
  --node-volume-size=10 \
  --master-count=1 \
  --master-size=t3.small \
  --master-volume-size=10 \
  --dns-zone=${MY_DOMAIN} \
  --cloud-labels "Owner=${USER},Environment=Test,Division=Services" \
  --ssh-public-key $HOME/.ssh/id_rsa.pub \
  --yes
```

Output:

```text
...
I0829 09:32:53.961790    4154 dns.go:153] Pre-creating DNS records
I0829 09:32:55.037438    4154 update_cluster.go:291] Exporting kubecfg for cluster
kops has set your kubectl context to pruzicka-k8s.mylabs.dev

Cluster changes have been applied to the cloud.


Changes may require instances to restart: kops rolling-update cluster
```

Wait for cluster to be up and running:

```bash
sleep 200
while `kops validate cluster --state=s3://${USER}-kops-k8s -o yaml 2>&1 | grep -q failures`; do sleep 5; echo -n .; done
echo
```

Store `kubeconfig` in current directory:

```bash
kops export kubecfg ${USER}-k8s.${MY_DOMAIN} --state=s3://${USER}-kops-k8s --kubeconfig kubeconfig.conf
```

Output:

```text
kops has set your kubectl context to pruzicka-k8s.mylabs.dev
```

Check if the new Kubernetes cluster is available:

```bash
export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes -o wide
```

Output:

```text
NAME                                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP     OS-IMAGE                       KERNEL-VERSION   CONTAINER-RUNTIME
ip-172-20-51-30.eu-central-1.compute.internal    Ready    node     25s   v1.14.6   172.20.51.30    18.197.69.215   Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-56-172.eu-central-1.compute.internal   Ready    node     27s   v1.14.6   172.20.56.172   18.194.44.246   Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-57-146.eu-central-1.compute.internal   Ready    node     24s   v1.14.6   172.20.57.146   18.185.188.31   Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-58-112.eu-central-1.compute.internal   Ready    master   72s   v1.14.6   172.20.58.112   18.194.242.59   Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-58-28.eu-central-1.compute.internal    Ready    node     16s   v1.14.6   172.20.58.28    3.120.175.151   Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
```

```bash
test -d tmp || mkdir tmp
if [ ${LETSENCRYPT_ENVIRONMENT} = "staging" ]; then
  for EXTERNAL_IP in $(kubectl get nodes --output=jsonpath="{.items[*].status.addresses[?(@.type==\"ExternalIP\")].address}"); do
    ssh -q -o StrictHostKeyChecking=no -l admin ${EXTERNAL_IP} \
      "sudo mkdir -p /etc/docker/certs.d/harbor.${MY_DOMAIN}/ && sudo wget -q https://letsencrypt.org/certs/fakelerootx1.pem -O /etc/docker/certs.d/harbor.${MY_DOMAIN}/ca.crt"
  done
  echo "*** Done"
fi
```

# Clean-up

![Clean-up](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/cleanup.svg?sanitize=true
"Clean-up")

Configure `kubeconfig`:

```bash
export MY_DOMAIN="mylabs.dev"
kops export kubecfg ${USER}-k8s.${MY_DOMAIN} --state=s3://${USER}-kops-k8s --kubeconfig /tmp/kubeconfig.conf
export KUBECONFIG=/tmp/kubeconfig.conf
```

Remove K8s cluster:

```bash
kops delete cluster --name=${USER}-k8s.${MY_DOMAIN} --yes --state=s3://${USER}-kops-k8s
```

Output:

```text
security-group:sg-06d46ba965803d316     ok
subnet:subnet-07ed5c1e194433a0f ok
route-table:rtb-01b1001514d69cfa4       ok
vpc:vpc-0c76a222e55c511ed       ok
dhcp-options:dopt-08ce550770088824c     ok
Deleted kubectl config for pruzicka-k8s.mylabs.dev

Deleted cluster: "pruzicka-k8s.mylabs.dev"
```

Delete GitHub repository:

```bash
hub delete -y ruzickap/k8s-flux-repository
```

Output:

```text
Deleted repository 'ruzickap/k8s-flux-repository'.
```

Remove S3 bucket used for storing the configuration by kops:

```bash
aws s3api delete-bucket --bucket ${USER}-kops-k8s --region eu-central-1
```

Clean Policy, User, Access Key in AWS:

```bash
# aws route53 delete-hosted-zone --id $(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text)

POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName==\`${USER}-AmazonRoute53Domains-cert-manager\`].{ARN:Arn}" --output text) && \
aws iam detach-user-policy --user-name "${USER}-route53" --policy-arn ${POLICY_ARN} && \
aws iam delete-policy --policy-arn ${POLICY_ARN}

USER_ACCESS_KEYS=$(aws iam list-access-keys --user-name ${USER}-route53 --query "AccessKeyMetadata[].AccessKeyId" --output text) && \
aws iam delete-access-key --user-name ${USER}-route53 --access-key-id ${USER_ACCESS_KEYS}

aws iam delete-user --user-name ${USER}-route53
```

Cleanup + Remove Helm:

```bash
rm -rf /home/${USER}/.helm
```

Docker certificate cleanup if exists:

```bash
sudo rm -rf /etc/docker/certs.d/harbor.${MY_DOMAIN}
```

Docker clean-up:

```bash
test -d ~/.docker/ && rm -rf ~/.docker/
DOCKER_IMAGES=$(docker images -q)
[ -n "${DOCKER_IMAGES}" ] && docker rmi --force ${DOCKER_IMAGES}
```

Remove `tmp` directory:

```bash
rm -rf tmp
```

Remove other files:

```bash
rm demo-magic.sh kubeconfig.conf README.sh &> /dev/null
```

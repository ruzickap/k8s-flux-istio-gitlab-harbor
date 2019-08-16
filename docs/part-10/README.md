# Clean-up

![Clean-up](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/cleanup.svg?sanitize=true
"Clean-up")

-----

Configure `kubeconfig`:

```bash
export MY_DOMAIN="mylabs.dev"
kops export kubecfg ${USER}-k8s.${MY_DOMAIN} --state=s3://${USER}-kops-k8s --kubeconfig /tmp/kubeconfig.conf
export KUBECONFIG=/tmp/kubeconfig.conf
```

Remove installed applications

```bash
#helm delete istio
kubectl delete virtualservices.networking.istio.io --all-namespaces --all
```

Remove K8s cluster:

```bash
kops delete cluster --name=${USER}-k8s.${MY_DOMAIN} --yes --state=s3://${USER}-kops-k8s
```

Remove S3 bucket used for storing the configuration by kops:

```bash
aws s3api delete-bucket --bucket ${USER}-kops-k8s --region eu-central-1
```

Output:

```text
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

Remove other files:

```bash
rm demo-magic.sh kubeconfig.conf README.sh &> /dev/null
```

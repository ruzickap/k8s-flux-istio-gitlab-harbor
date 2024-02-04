#!/usr/bin/env bash

set -eu

################################################
# include the magic
################################################
test -s ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
# shellcheck disable=SC1091
. ./demo-magic.sh

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
export TYPE_SPEED=60

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=0

# No wait
export NO_WAIT=false

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
export DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# hide the evidence
#clear

### Please run these commands before running the script

# if [ -n "$SSH_AUTH_SOCK" ]; then
#  docker run -it --rm -e USER="$USER" -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK -v $PWD:/mnt -v $HOME/.aws:/root/.aws -v $HOME/.config/hub:/root/.config/hub:ro ubuntu
# else
#  docker run -it --rm -e USER="$USER" -v $PWD:/mnt -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.aws:/root/.aws -v $HOME/.config/hub:/root/.config/hub:ro ubuntu
# fi
# echo $(hostname -I) $(hostname) >> /etc/hosts
# apt-get update -qq && apt-get install -qq -y curl git pv > /dev/null
# cd /mnt

# export LETSENCRYPT_ENVIRONMENT="production"  # Use with care - Let's Encrypt will generate real certificates
# export MY_DOMAIN="mylabs.dev"

# ./run-k8s-part2.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor && cd k8s-flux-istio-gitlab-harbor

sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p;/^-----$/p" docs/part-0{4,5}/README.md |
  sed \
    -e 's/^-----$/\np  ""\np  "################################################################################################### Press <ENTER> to continue"\nwait\n/' \
    -e 's/^```bash.*/\npe '"'"'/' \
    -e 's/^```$/'"'"'/' \
    -e 's/^sleep /#sleep /' \
    > README.sh

if [ "$#" -eq 0 ]; then
  ### Please run these commands before running the script

  # mkdir /var/tmp/test && cd /var/tmp/test
  # git clone --quiet https://github.com/ruzickap/k8s-flux-istio-gitlab-harbor && cd k8s-flux-istio-gitlab-harbor

  export LETSENCRYPT_ENVIRONMENT=${LETSENCRYPT_ENVIRONMENT:-staging}
  # export LETSENCRYPT_ENVIRONMENT="production" # Use with care - Let's Encrypt will generate real certificates
  # ./run-k8s-part2.sh

  export MY_DOMAIN="mylabs.dev"
  EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID
  EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY
  kops export kubecfg "${USER}-k8s.${MY_DOMAIN}" --state="s3://${USER}-kops-k8s" --kubeconfig kubeconfig.conf
  echo -e "\n*** ${MY_DOMAIN} | ${LETSENCRYPT_ENVIRONMENT} | ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID} | ${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY} ***\n$(kubectl --kubeconfig=./kubeconfig.conf cluster-info)"

  if [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID}" ] || [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}" ]; then
    echo -e "\n*** One of the mandatory variables 'EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID' or 'EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY' is not set !!\n"
    exit 1
  fi

  awk "/${MY_DOMAIN}/" /etc/hosts
  set +eux

  echo -e "\n\n*** Press ENTER to start\n"
  read -r

  # hide the evidence
  clear
  # shellcheck disable=SC1091
  source README.sh
else
  cat README.sh
fi

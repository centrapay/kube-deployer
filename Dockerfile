FROM debian:bullseye-slim as installer
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    gpg \
    unzip \
  && rm -rf /var/lib/apt/lists/*

# =====
# Kubectl
#
# kubectl versions may be found at:
# https://github.com/kubernetes/kubernetes/releases
FROM installer as kubectl
ENV KUBE_VERSION="v1.21.11"
RUN curl -s https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl
RUN shasum -a 512 /usr/local/bin/kubectl
ENV KUBECTL_SHA_512=82cd205c0ecb6660a0c4915b8f58b79ba94ad1c1ddf05491345b7c671ef6f1b1fb78c13c7968d4ddd2a712de43b4b67a587c1aeef36325e53f3b15871a13d132
RUN echo "${KUBECTL_SHA_512}  /usr/local/bin/kubectl" | shasum -c
RUN chmod +x /usr/local/bin/kubectl

# =====
# Helm
#
# helm versions may be found at:
# https://github.com/kubernetes/helm/releases
FROM installer as helm
ENV HELM_VERSION="v3.8.1"
RUN curl -s https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xzO linux-amd64/helm > /usr/local/bin/helm
RUN shasum -a 256 /usr/local/bin/helm
ENV HELM_SHA_256=1fe973bb32db1dcacdda9cda150e71e47b517a2af6bfdc8a2735859c8070a0b6
RUN echo "${HELM_SHA_256}  /usr/local/bin/helm" | shasum -c
RUN chmod +x /usr/local/bin/helm

# =====
# Kubeval
#
# kubeval versions may be found at:
# https://github.com/instrumenta/kubeval/releases
FROM installer as kubeval
ENV KUBEVAL_URL="https://github.com/instrumenta/kubeval/releases/download/v0.16.1/kubeval-linux-amd64.tar.gz"
RUN curl -Ls "${KUBEVAL_URL}" > kubeval.tar.gz
RUN tar -xzf kubeval.tar.gz
RUN mv kubeval /usr/local/bin/kubeval
RUN shasum -a 512 /usr/local/bin/kubeval
ENV KUBEVAL_SHA_512=74964fe7ee96f445597c904ba18b14fdbdd78c1bd69c838d6798d0c5b3ba398d01ad3c3319f08ae8241bc28d11b29b6a562546d4f5580221fda96a2b3bb34002
RUN echo "${KUBEVAL_SHA_512}  /usr/local/bin/kubeval" | shasum -c
RUN chmod +x /usr/local/bin/kubeval

# =====
# AWS CLI
#
# https://github.com/aws/aws-cli/blob/v2/docker/Dockerfile
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
FROM installer as awscli
RUN curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' > /awscliv2.zip
RUN curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig' > /awscliv2.sig
COPY aws-cli-public-key.asc /
RUN gpg --import /aws-cli-public-key.asc
RUN gpg --verify awscliv2.sig awscliv2.zip
RUN unzip -q /awscliv2.zip
RUN /aws/install --bin-dir /aws-cli-bin
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
ENV IAM_AUTHENTICATOR_VERSION="1.15.10/2020-02-22"
RUN curl -s https://amazon-eks.s3-us-west-2.amazonaws.com/${IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator \
      > /aws-cli-bin/aws-iam-authenticator
RUN shasum -a 256 /aws-cli-bin/aws-iam-authenticator
ENV AUTHENTICATOR_SHA_256=fe958eff955bea1499015b45dc53392a33f737630efd841cd574559cc0f41800
RUN echo "${AUTHENTICATOR_SHA_256}  /aws-cli-bin/aws-iam-authenticator" | shasum -c
RUN chmod +x /aws-cli-bin/aws-iam-authenticator

# =====
# Docker
#
# https://docs.docker.com/engine/install/debian/
FROM installer as docker
# Add Docker's official GPG key:
ENV DOCKER_VERSION_STRING=5:24.0.6-1~debian.11~bullseye
RUN apt-get update && apt-get install ca-certificates gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
RUN echo \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
# Install Docker
RUN apt-get update && apt-get install -y docker-ce-cli=$DOCKER_VERSION_STRING && rm -rf /var/lib/apt/lists/*

# =====
# Terraform
#
# https://github.com/hashicorp/terraform/releases
FROM installer as terraform
ENV TERRAFORM_VERSION="1.5.2"
RUN curl -sL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > /terraform.zip
RUN shasum -a 256 /terraform.zip
ENV TERRAFORM_SHA_256=781ffe0c8888d35b3f5bd0481e951cebe9964b9cfcb27e352f22687975401bcd
RUN echo "${TERRAFORM_SHA_256}  /terraform.zip" | shasum -c
RUN unzip /terraform.zip
RUN chmod +x terraform

# ====
# AWS Sam Deployer
#
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html
FROM installer as samcli
RUN apt-get update \
  && apt-get install -y \
     python3 \
     python3-pip \
  && rm -rf /var/lib/apt/lists/*
RUN pip3 install aws-sam-cli \
  && rm -rf /root/.cache/pip

# =====
# Kubeconform
#
# kubeconform versions may be found at:
# https://github.com/yannh/kubeconform/releases
FROM installer as kubeconform
ENV KUBECONFORM_URL="https://github.com/yannh/kubeconform/releases/download/v0.6.4/kubeconform-linux-amd64.tar.gz"
RUN curl -Ls "${KUBECONFORM_URL}" > kubeconform.tar.gz
RUN tar -xvzf kubeconform.tar.gz
RUN mv kubeconform /usr/local/bin/kubeconform
ENV KUBECONFORM_SHA_256=d095722bf8032abec604dbb2c68f7c77fee55a5b770d1f96d5e3988b3c5faae5
RUN echo "${KUBECONFORM_SHA_256}  /usr/local/bin/kubeconform" | shasum -a 256 -c
RUN chmod +x /usr/local/bin/kubeconform

# ====
# General Tools
#
# yq - https://github.com/mikefarah/yq
FROM installer as tools
ENV YQ_SHA_256=8afd786b3b8ba8053409c5e7d154403e2d4ed4cf3e93c237462dc9ef75f38c8d
RUN curl -sL "https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64" > yq
RUN echo "${YQ_SHA_256}  yq" | shasum -c
RUN chmod +x yq

# =====
# Deployer
#
FROM node:18-bullseye
# Less and Groff required for some AWS CLI commands (eg: help and cloudfront)
RUN apt-get update && apt-get install -y \
    groff \
    less \
    jq \
 && rm -rf /var/lib/apt/lists/*
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /usr/local/bin/helm /usr/local/bin/helm
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /aws-cli-bin/ /usr/local/bin/
COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=docker /usr/bin/docker /usr/local/bin/docker
COPY --from=kubeval /usr/local/bin/kubeval /usr/local/bin/kubeval
COPY --from=kubeconform /usr/local/bin/kubeconform /usr/local/bin/kubeconform
COPY --from=samcli /usr/local/bin/sam /usr/local/bin/sam
COPY --from=samcli /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=tools /yq /usr/local/bin/yq

RUN kubectl help > /dev/null
RUN helm version
RUN kubeval --version
RUN kubeconform -v
RUN aws --version
RUN terraform version
RUN docker --version
RUN bash --version
RUN curl --version
RUN git --version
RUN jq --version
RUN sam --version
RUN yq --version

WORKDIR /config
CMD bash

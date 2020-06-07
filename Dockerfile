FROM debian:10.3-slim as installer
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
ENV KUBE_VERSION="v1.17.4"
RUN curl -s https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl
RUN shasum -a 256 /usr/local/bin/kubectl
ENV KUBECTL_SHA_256=465b2d2bd7512b173860c6907d8127ee76a19a385aa7865608e57a5eebe23597
RUN echo "${KUBECTL_SHA_256}  /usr/local/bin/kubectl" | shasum -c
RUN chmod +x /usr/local/bin/kubectl

# =====
# Helm
#
# helm versions may be found at:
# https://github.com/kubernetes/helm/releases
FROM installer as helm
ENV HELM_VERSION="v3.2.1"
RUN curl -s https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xzO linux-amd64/helm > /usr/local/bin/helm
RUN shasum -a 256 /usr/local/bin/helm
ENV HELM_SHA_256=98c57f2b86493dd36ebaab98990e6d5117510f5efbf21c3344c3bdc91a4f947c
RUN echo "${HELM_SHA_256}  /usr/local/bin/helm" | shasum -c
RUN chmod +x /usr/local/bin/helm

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
# https://docs.docker.com/install/linux/docker-ce/debian/
FROM installer as docker
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
COPY ./docker-public-key.asc /
RUN apt-key add /docker-public-key.asc
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
RUN apt-get update && apt-get install -y docker-ce-cli

# =====
# Terraform
#
FROM installer as terraform
ENV TERRAFORM_VERSION="0.12.24"
RUN curl -sL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > /terraform.zip
RUN shasum -a 256 /terraform.zip
ENV TERRAFORM_SHA_256=602d2529aafdaa0f605c06adb7c72cfb585d8aa19b3f4d8d189b42589e27bf11
RUN echo "${TERRAFORM_SHA_256}  /terraform.zip" | shasum -c
RUN unzip /terraform.zip
RUN chmod +x terraform

# =====
# Sops
#
FROM installer as sops
ENV SOPS_VERSION="v3.5.0"
RUN curl -sL "https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux" > /sops
RUN shasum -a 256 /sops
ENV SOPS_SHA_256=610fca9687d1326ef2e1a66699a740f5dbd5ac8130190275959da737ec52f096
RUN echo "${SOPS_SHA_256}  /sops" | shasum -c
RUN chmod +x /sops

# =====
# Deployer
#
FROM node:12
# Less and Groff required for some AWS CLI commands (eg: help and cloudfront)
RUN apt-get update && apt-get install -y \
    groff \
    less \
 && rm -rf /var/lib/apt/lists/*
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /usr/local/bin/helm /usr/local/bin/helm
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /aws-cli-bin/ /usr/local/bin/
COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=sops /sops /usr/local/bin/sops
COPY --from=docker /usr/bin/docker /usr/local/bin/docker

RUN kubectl help > /dev/null
RUN helm version
RUN aws --version
RUN terraform version
RUN sops --version
RUN docker --version
RUN bash --version
RUN curl --version
RUN git --version

WORKDIR /config
CMD bash

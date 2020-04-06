FROM debian:10.3-slim as base
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
  && rm -rf /var/lib/apt/lists/*

# kubectl versions may be found at:
# https://github.com/kubernetes/kubernetes/releases
FROM base as kubectl
ENV KUBE_VERSION="v1.17.4"
RUN curl -s https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# helm versions may be found at:
# https://github.com/kubernetes/helm/releases
FROM base as helm
ENV HELM_VERSION="v3.1.2"
RUN curl -s https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xzO linux-amd64/helm > /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm

# https://github.com/aws/aws-cli/blob/v2/docker/Dockerfile
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
FROM base as awscli
RUN apt-get update && apt-get install -y \
    gpg \
    unzip
RUN curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' > /awscliv2.zip
RUN curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig' > /awscliv2.sig
COPY aws-cli-public-key.asc /
RUN gpg --import /aws-cli-public-key.asc
RUN gpg --verify awscliv2.sig awscliv2.zip
RUN unzip -q /awscliv2.zip
RUN /aws/install --bin-dir /aws-cli-bin

FROM base
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /usr/local/bin/helm /usr/local/bin/helm
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /aws-cli-bin/ /usr/local/bin/

RUN kubectl help > /dev/null && echo kubectl ok
RUN helm version
RUN aws --version

WORKDIR /config
CMD bash

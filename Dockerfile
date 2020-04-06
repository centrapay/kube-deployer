FROM alpine:3.11 as base
RUN apk add --no-cache ca-certificates bash git openssh curl

# kubectl versions may be found at:
# https://github.com/kubernetes/kubernetes/releases
FROM base as kubectl
ENV KUBE_VERSION="v1.17.4"
RUN wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# helm versions may be found at:
# https://github.com/kubernetes/helm/releases
FROM base as helm
ENV HELM_VERSION="v3.1.2"
RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm

FROM base
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /usr/local/bin/helm /usr/local/bin/helm
RUN kubectl help
RUN helm version

WORKDIR /config
CMD bash

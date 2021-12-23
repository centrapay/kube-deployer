# kube-deployer

This is a base image with dependencies needed for deployment to Kubernetes.

This includes:

- node
- kubectl
- helm
- kubeval
- aws
- terraform
- docker
- bash
- curl
- git
- sam
- jq

# How do I do a new release?

Create a git tag that starts with 1.x and it'll show up in GH Actions. This
will build the image and push it to the Centrapay namespace on dockerhub.

# Kubernetes Homelab Configuration

This repository contains the configuration files for a Kubernetes-based homelab environment. It uses [FluxCD](https://fluxcd.io/) for GitOps-based deployment and management of applications and infrastructure. The setup includes various applications and services, such as Nextcloud, PostgreSQL, Redis, MinIO, Vaultwarden, and more, along with supporting infrastructure like Longhorn, MetalLB, and Ingress-NGINX.

## Overview

The repository is structured as follows:

- **`apps/`**: Contains application-specific configurations, including namespaces, Helm releases, and other Kubernetes manifests.
- **`infrastructure/`**: Contains infrastructure-related configurations, such as storage (Longhorn), ingress (NGINX), and networking (MetalLB).
- **`cluster/`**: Contains FluxCD configurations for managing the cluster's state.
- **`other/`**: Contains unused manifests that I keep in case I need them one day
- **`.sops.yaml`**: Contains the public key used to encrypt the secrets

## Key Features

- **GitOps Workflow**: All configurations are managed via Git and deployed using FluxCD.
- **Persistent Storage**: Longhorn is used for distributed block storage.
- **Ingress Management**: Ingress-NGINX is used for routing external traffic to services.
- **TLS Certificates**: Cert-Manager is used to manage TLS certificates via Let's Encrypt.
- **Service Discovery**: MetalLB provides load balancer functionality for bare-metal Kubernetes clusters.

## Services and Ports

Below is the list of ports used by essential services on your machine:

| Service         | Ports to Open | Protocol | Description                              |
|------------------|---------------|----------|------------------------------------------|
| NGINX Ingress    | 80, 443       | TCP      | Routes external traffic to services.     |
| Cert-Manager     | 80, 443       | TCP      | Handles TLS certificate issuance.        |
| Blocky           | 53, 853       | TCP/UDP  | DNS resolver with ad-blocking.           |

## Getting Started

1. Clone this repository:
   ```bash
   git clone git@github.com:seercle/kubernetes.git
   cd kubernetes
    ```

2. Install FluxCD and bootstrap the cluster:
    ```bash
    flux bootstrap github \
    --owner=seercle \
    --repository=kubernetes \
    --branch=main \
    --path=./cluster
 
3. Enter the kustomization directory:
    ```bash
    cd infrastructure/kustomization
    ```
 
3. Create the sops-age secret:
    ```bash
    sops -d secret.yaml | k apply -f -
    ```
 

5. Deploy infrastructure-pre:
    ```bash
    kubectl apply -f ./infra-pre.yaml
    ```
 
6. Deploy infrastructure-post:
    ```bash
    kubectl apply -f ./infra-post.yaml
    ```

7. At this point, you should log into longhorn and setup the disks, with the labels `ssd` and `hdd`

8. Deploy applications-pre:
    ```bash
    kubectl apply -f ./apps-pre.yaml
    ```

9. At this point, you should log into the `postgresql` and `redis` databases and create the users that will be used in `authentik`, `harbor`, `nextcloud`, ...

10. Deploy applications-post:
    ```bash
    kubectl apply -f ./apps-post.yaml
    ```


## Notes
- Ensure that the required ports are open on your firewall or router.
- Update the DNS records for your domain to point to the cluster's ingress IP.
- Use the provided .sops.yaml configuration to manage secrets securely.
- If you don't want to boostrap, you can:
  - Apply `instance.yaml` in `cluster`
  - Create the secret `git-auth` in `cluster/git` with `sops -d secret.yaml | k apply -f -` 
  - Apply `git.yaml` in `cluster/git`
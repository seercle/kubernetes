# Kubernetes Homelab Configuration

This repository contains the configuration files for a Kubernetes-based homelab environment. It uses [FluxCD](https://fluxcd.io/) for GitOps-based deployment and management of applications and infrastructure. The setup includes various applications and services, such as Nextcloud, PostgreSQL, Redis, MinIO, Vaultwarden, and more, along with supporting infrastructure like Longhorn, MetalLB, and Ingress-NGINX.

## Overview

The repository is structured as follows:

- **`apps/`**: Contains application-specific configurations, including namespaces, Helm releases, and other Kubernetes manifests.
- **`infrastructure/`**: Contains infrastructure-related configurations, such as storage (Longhorn), ingress (NGINX), and networking (MetalLB).
- **`secrets/`**: Contains encrypted secrets managed using [SOPS](https://github.com/mozilla/sops).
- **`cluster/`**: Contains FluxCD configurations for managing the cluster's state.
- **`other/`**: Contains unused manifests that I keep in case I need them one day

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
    ```

3. Deploy secrets:
    ```bash
    kubectl apply -k ./secrets
    ```

4. Deploy infrastructure:
    ```bash
    kubectl apply -k ./infrastructure
    ```

5. Deploy applications:
    ```bash
    kubectl apply -k ./apps
    ```

## Notes
- Ensure that the required ports are open on your firewall or router.
- Update the DNS records for your domain to point to the cluster's ingress IP.
- Use the provided .sops.yaml configuration to manage secrets securely.

## License
This repository is licensed under the MIT License. See the LICENSE file for details.
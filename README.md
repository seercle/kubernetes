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
- **DNS Proxy**: Blocky proxies all DNS requests to Cloudflare, while blocking certain sites

## Services and Ports

Below is the list of ports used by essential services on your machine:

| Service         | Ports to Open | Protocol | Description                              |
|------------------|---------------|----------|------------------------------------------|
| NGINX Ingress    | 80, 443       | TCP      | Routes external traffic to services.     |
| Cert-Manager     | 80, 443       | TCP      | Handles TLS certificate issuance.        |
| Blocky           | 53, 853       | TCP/UDP  | DNS resolver with ad-blocking.           |

## Getting Started

The following installation was tested on commit `ef2bd6cf9f6b700c64c262ae64694ff358841d45`.

**It might not work for future commits.**

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

5. Deploy infrastructure-core:
    ```bash
    kubectl apply -f ./infra-core.yaml
    ```

6. Deploy infrastructure-platform:
    ```bash
    kubectl apply -f ./infra-platform.yaml
    ```

7. At this point, you should log into longhorn and setup the disks, with the labels `ssd` and `hdd`

8. Deploy applications-database:
    ```bash
    kubectl apply -f ./apps-database.yaml
    ```

9. At this point, you should log into the `postgresql` and `redis` databases and create the users that will be used in `authentik`, `harbor`, `nextcloud`, ...

10. Deploy applications-services:
    ```bash
    kubectl apply -f ./apps-services.yaml
    ```

## Notes
- Ensure that the required ports are open on your firewall or router.
- Update the DNS records for your domain to point to the cluster's ingress IP.
- Use the provided .sops.yaml configuration to manage secrets securely.
- If you don't want to boostrap flux, you can:
  - Apply `instance.yaml` in `cluster`
  - Create the secret `git-auth` in `cluster/git`:
  ```bash
  sops -d secret.yaml | k apply -f -
  ```
  - Apply `git.yaml` in `cluster/git`
- If a persistent volume gets `Unbound` and you want to re-use it, delete the `claimRef` inside the PV and the newly deployed pods will use it.

## Tips for some services

- ### Vaultwarden

Head to `https://vaultwarden.seercle.com/admin` and enter the admin key to create a user

- ### Dashboard

To retrieve the password:
```bash
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```
Beware that the browser loves to cache the login page and make it seem like the password is wrong !

- ### Nextcloud

Beware of Nextcloud. If it goes down, it will never go back up sometimes. I don't know why ! Probably when the Postgresql database has not changed but Nexcloud's persistent volume was recreated. I don't know !

- ### Harbor

Make sure that the harbor-registry-auth correctly match Harbor's password.

- ### Blocky

The TLS certificate has an expiration date. Don't forget to change it from time to time.

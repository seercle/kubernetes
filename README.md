# Kubernetes Homelab Configuration

This repository contains the configuration files for a Kubernetes-based homelab environment. It leverages [FluxCD](https://fluxcd.io/) for GitOps-based deployment and management of applications and infrastructure. The setup includes various applications and services, such as **Nextcloud**, **PostgreSQL**, **Redis**, **MinIO**, **Vaultwarden**, and more, along with supporting infrastructure like **Longhorn**, **MetalLB**, and **Ingress-NGINX**.

---

This configuration expects `coredns` to be preinstalled

## Overview

The repository is structured as follows:

*   **`apps/`**: Contains application-specific configurations, including namespaces, Helm releases, and other Kubernetes manifests.
*   **`infrastructure/`**: Contains infrastructure-related configurations, such as storage (**Longhorn**), ingress (**NGINX**), and networking (**MetalLB**).
*   **`cluster/`**: Contains FluxCD configurations for managing the cluster's state.
*   **`other/`**: Contains unused manifests kept for potential future use.
*   **`.sops.yaml`**: Contains the public key used to encrypt secrets.

---

## Key Features

*   **GitOps Workflow**: All configurations are managed via Git and deployed using **FluxCD**.
*   **Persistent Storage**: **Longhorn** provides distributed block storage.
*   **Ingress Management**: **Ingress-NGINX** handles routing external traffic to services.
*   **TLS Certificates**: **Cert-Manager** manages TLS certificates via Let's Encrypt.
*   **Service Discovery**: **MetalLB** offers load balancer functionality for bare-metal Kubernetes clusters.
*   **DNS Proxy**: **Blocky** proxies all DNS requests to Cloudflare, including ad-blocking.

---

## Services and Ports

Below is a list of essential services and the ports they use on your machine:

| Service         | Ports to Open | Protocol | Description                                |
| :-------------- | :------------ | :------- | :----------------------------------------- |
| **NGINX Ingress** | 80, 443       | TCP      | Routes external traffic to services.       |
| **Cert-Manager**  | 80, 443       | TCP      | Handles TLS certificate issuance.          |
| **Blocky**        | 53, 853       | TCP/UDP  | DNS resolver with ad-blocking capabilities. |
| **Gitea**         | 22            | TCP      | Git platform.                              |

---

## Getting Started

This installation guide was tested on commit `ef2bd6cf9f6b700c64c262ae64694ff358841d45`.

**It might not work for future commits.**

1.  **Clone this repository**:
    ```bash
    git clone git@github.com:seercle/kubernetes.git
    cd kubernetes
    ```
2.  **Install FluxCD and bootstrap the cluster**:
    ```bash
    flux bootstrap github \
      --owner=seercle \
      --repository=kubernetes \
      --branch=main \
      --path=./cluster
    ```
3.  **Enter the kustomization directory**:
    ```bash
    cd infrastructure/kustomization
    ```
4.  **Create the `sops-age` secret**:
    ```bash
    sops -d secret.yaml | k apply -f -
    ```
5.  **Deploy `infrastructure-core`**:
    ```bash
    kubectl apply -f ./infra-core.yaml
    ```
6.  **Deploy `infrastructure-platform`**:
    ```bash
    kubectl apply -f ./infra-platform.yaml
    ```
7.  At this point, you should log into **Longhorn** and set up the disks with the labels `ssd` and `hdd`.
8.  **Deploy `applications-database`**:
    ```bash
    kubectl apply -f ./apps-database.yaml
    ```
9.  At this point, you should log into the `postgresql` and `redis` databases and create the users that will be used in `authentik`, `harbor`, `nextcloud`, etc.
10. **Deploy `applications-services`**:
    ```bash
    kubectl apply -f ./apps-services.yaml
    ```

---

## Notes

*   Ensure that the required ports are open on your firewall or router.
*   Update **MetalLB** configuration if your network range changes.
*   Update the DNS records for your domain to point to the cluster's ingress IP.
*   Use the provided `.sops.yaml` configuration to manage secrets securely.
*   If you prefer not to bootstrap **Flux**, you can:
    *   Install Flux:
        ```bash
        flux install
        ```
    *   Create the secret `git-auth` in `cluster/git` (not necessary for public repos):
        ```bash
        sops -d secret.yaml | k apply -f -
        ```
    *   Apply `git.yaml` in `cluster/git`.
*   If a persistent volume becomes `Unbound` and you wish to reuse it, delete the `claimRef` inside the PV. Newly deployed pods will then utilize it.
*   For an IPv6-only cluster:
    *   Change **MetalLB's** ConfigMap to use IPv6 addresses.
    *   Edit **CoreDNS's** ConfigMap to use the `dns64` plugin.
    *   Install **NAT64** ([https://github.com/kubernetes-sigs/nat64](https://github.com/kubernetes-sigs/nat64)).

---

## Tips for Specific Services

### Authentik

The initial login page is `https://authentik.seercle.com/if/flow/initial-setup/`.

To activate the authentification outpost:

1.  **Create a proxy provider**
    *   Go to **Applications → Providers**.
    *   Click **Create Provider → Proxy**.
    *   Set Proxy type to **Forward auth (domain level)**
    *   **Authentification URL**: `https://authentik.<your-domain>
    *   **Cookie domain**: `<your-domain>`

2.  **Create the application**
    *  Go to **Applications → Applications**.
    *  Create an application using the provider created above.

3. **Edit the default outpost**
    *   Go to **Applications → Outposts**.
    *   Edit the default outpost.
    *   Select the application created above under **Available Applications**.
    
Make sure that the NGINX annotations in the ingresses for the services you want to protect with authentik include the correct name of the outpost service (e.g., `ak-outpost-authentik-embedded-outpost`).

### Vaultwarden

Navigate to `https://vaultwarden.seercle.com/admin` and enter the admin key to create a user.

If you are using IPv4, remove the `ROCKET_ADDRESS` and `WEBSOCKET_ADDRESS` environment variables from the deployment.

### Kubernetes Dashboard

To retrieve the password:
```bash
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```
Be aware that browsers often cache the login page, which can make it appear as if the password is incorrect.

### Nextcloud

**Beware of Nextcloud!** If it goes down, it will sometimes never come back up. The exact cause is unknown, but it often happens when the PostgreSQL database hasn't changed but Nextcloud's persistent volume was recreated.

### Harbor

Make sure that `harbor-registry-auth` correctly matches Harbor's password.

### Blocky

The TLS certificate has an expiration date; remember to update it periodically.

### Arr Services

1.  **Create the WARP files**:
    ```bash
    wgcf register
    wgcf generate
    ```
2.  **Create the Kubernetes secret for WARP**:
    Edit the generated `wgcf-profile.conf`:
    *   Change `AllowedIPs = 0.0.0.0/0, ::/0` to `AllowedIPs = 0.0.0.0/0`.
    *   In the `[Interface]` section, add `Table = off`, `PostUp = ip -4 route add 0.0.0.0/0 dev wg0`, and `PreDown = ip -4 route del 0.0.0.0/0 dev wg0`.
    ```bash
    kubectl create secret generic warp-conf --from-file=wg0.conf=./wgcf-profile.conf -n servarr
    ```
3.  **Retrieve qBitTorrent's password**:
    ```bash
    kubectl logs -n servarr servarr-qbittorrent-<whatever> -c servarr
    ```
4.  **Configure qBitTorrent**:
    *   Go to **Options (WebUI) → Downloads**.
    *   Enable "**Default Torrent Management Mode**" to **Automatic**.
    *   Set the default download path to `/data/downloads` (this is the shared PVC).
    *   Create three categories (e.g., via right-click in the sidebar or UI): `radarr`, `sonarr`, and `lidarr`. Set their paths to `/data/downloads/radarr`, `/data/downloads/sonarr`, and `/data/downloads/lidarr` respectively.
    *   Go to **Options → Advanced**.
    *   Set "**Network interface**" to `wg0` and "**Optional IP address**" to the IPv4 address (usually `127.16.x.x`).

5.  **Configure Prowlarr**:
    *   **Connect Prowlarr to Flaresolverr (Bypass Cloudflare)**:
        In Prowlarr, go to **Settings → Indexers → Add Proxy**.
        Select `Flaresolverr`.
        *   **Name**: `Flaresolverr`
        *   **Host**: `http://flaresolverr:8191` (Assuming your K8s service name is `flaresolverr`).
        *   **Tags**: Add a tag like `flaresolverr`.
        Save.
    *   **Add Indexers**:
        Go to **Indexers → Add Indexer**. Search for public ones (e.g., **1337x**, **YTS**) or your private trackers and add them.
    *   **Sync to Apps**:
        Go to **Settings → Apps → Add Application**.
        Add **Radarr**.
        *   **Prowlarr Server**: `http://servarr-prowlarr:9696`
        *   **Radarr Server**: `http://servarr-radarr:7878`
        *   **API Key**: Paste from Radarr (**Settings → General**).
        Repeat for **Sonarr** and **Lidarr**.
        Result: Prowlarr will now automatically inject your indexers into Radarr, Sonarr, and Lidarr.

6.  **Add Torrentio**:
    *   Follow this guide: [https://github.com/dreulavelle/Prowlarr-Indexers](https://github.com/dreulavelle/Prowlarr-Indexers).
    *   Edit the file:
        ```/dev/null/example.yaml#L1-5
        infohash:
          selector: url
          filters:
            - name: split
              args: ["/", 5]
        ```
        to
        ```/dev/null/example.yaml#L1-2
        infohash:
          selector: infoHash
        ```

7.  **Create data directories**:
    ```bash
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/downloads/radarr
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/downloads/sonarr
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/downloads/lidarr
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/movies
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/tv
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- mkdir -p /data/music
    kubectl exec -n servarr -it servarr-qbittorrent-<whatever> -c servarr -- chmod -R 777 /data/
    ```

8.  **Configure Radarr & Sonarr (The Managers)**:
    *   **Connect Download Client (qBittorrent)**:
        In Radarr, go to **Settings → Download Clients → Add → qBittorrent**.
        *   **Name**: `qBittorrent`
        *   **Host**: `servarr-qbittorrent-web` (Use your K8s service name).
        *   **Username/Password**: (The default is often `admin / adminadmin` unless you changed it).
        *   **Category**: `radarr` (Important: This matches the category you made in step 4).
        Test and Save.
        Repeat this in Sonarr using the category `sonarr` and Lidarr using the category `lidarr`.
    *   **Root Folders**:
        In Radarr, go to **Settings → Media Management → Root Folders**.
        Add the path where you want the final movie files to live (should be `/data/movies` for the shared PVC).
        Repeat in Sonarr (`/data/tv`) and Lidarr (`/data/music`).
    *   **Profiles**:
        You might want to clone a profile and adjust it to another language for region-specific films.
    *   **Quality**:
        In Radarr, go to **Settings → Quality**.
        Adjust the quality profiles as desired.
        Repeat in Sonarr and Lidarr.

9.  **Configure Bazarr (Subtitles)**:
    *   **Connect to Arrs**:
        In Bazarr, go to **Settings → Radarr**.
        Enable it and enter the address `servarr-radarr` and the API Key.
        Repeat for Sonarr.
    *   **Languages**:
        Go to **Settings → Languages**.
        Add the languages you want subtitles for in `Language Filter`
        Create a "**Profile**" (e.g., "**English**") and select your desired subtitle languages.
        Add this profile as default for both movies and TV Shows at the bottom of the page.
    *   **Subtitle Providers**:
        Go to **Settings → Providers**.
       Configure your desired subtitle providers (e.g., OpenSubtitles, YIFY, etc.) with your credentials if needed.

10. **Configure Cleanuparr (Maintenance)**:
    In Cleanuparr settings, add your instances for **Radarr**, **Sonarr**, **Lidarr** and **qBittorrent**.

11. **Connect to Emby**:
    In Emby, add one or two libraries for Movies and TV Shows with the paths `/data/movies` and `/data/tv`.

12. **Connect to Jellyseer**:
    In Jellyseer, go to **Settings → Services**.
    Add **Radarr** and **Sonarr** with their respective addresses and API keys.

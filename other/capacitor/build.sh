wget -qO- https://gimlet.io/install-capacitor | bash

cp ~/.local/bin/next .
sops --decrypt config > kubeconfig

docker build -t harbor.seercle.com/homelab/capacitor:latest .

docker login harbor.seercle.com
docker push harbor.seercle.com/homelab/capacitor:latest

rm next
rm kubeconfig
docker rmi harbor.seercle.com/homelab/capacitor:latest

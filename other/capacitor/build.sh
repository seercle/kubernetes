# Retrieve the latest version
curl -L "https://github.com/gimlet-io/capacitor/releases/download/capacitor-next/next-$(uname)-$(uname -m)" -o next
chmod +x next

docker build -t harbor.seercle.com/homelab/capacitor:latest .

docker login harbor.seercle.com

docker push harbor.seercle.com/homelab/capacitor:latest

# Cleanup
rm next
rm kubeconfig
docker rmi harbor.seercle.com/homelab/capacitor:latest

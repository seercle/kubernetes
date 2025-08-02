# Build then push the image to the registry
# !/bin/bash
docker build -t blocky:latest -f Dockerfile .
if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi
docker tag blocky:latest harbor.vivenot.dev/homelab/blocky:latest
if [ $? -ne 0 ]; then
    echo "Docker tag failed"
    exit 1
fi 
docker push harbor.vivenot.dev/homelab/blocky:latest
if [ $? -ne 0 ]; then
    echo "Docker push failed"
    exit 1
fi
echo "Docker image built and pushed successfully"
# Cleanup
docker rmi blocky:latest
if [ $? -ne 0 ]; then
    echo "Docker image cleanup failed"
    exit 1
fi
docker rmi harbor.vivenot.dev/homelab/blocky:latest
if [ $? -ne 0 ]; then
    echo "Docker image cleanup failed"
    exit 1
fi
echo "Docker images cleaned up successfully"
# Exit script
exit 0

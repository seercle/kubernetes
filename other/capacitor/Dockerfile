FROM alpine:latest
WORKDIR /app
COPY ./next .
COPY ./kubeconfig /root/.kube/config
EXPOSE 3333
CMD ["./next", "--port", "3333"]

# Set your target namespace
NAMESPACE="longhorn-system"

# Get a list of all namespaced resources (excluding events)
RESOURCES=$(kubectl api-resources --verbs=list --namespaced -o name | grep -v events.events.k8s.io)

# Loop through each resource type
for RESOURCE in $RESOURCES; do
    echo "Processing resource type: $RESOURCE"
    # Get all resources of this type in the target namespace
    kubectl get "$RESOURCE" -n "$NAMESPACE" -o json --ignore-not-found | \
    jq -c '.items[] | select(.metadata.finalizers != null)' | \
    while read -r resource_json; do
        RESOURCE_NAME=$(echo "$resource_json" | jq -r '.metadata.name')
        echo "  - Patching finalizers for resource '$RESOURCE_NAME' of type '$RESOURCE'"
        
        # Patch the resource to set its finalizers to null
        kubectl -n "$NAMESPACE" patch "$RESOURCE" "$RESOURCE_NAME" \
            --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null
    done
done

# Wait for a moment for the garbage collector to work
echo "Finalizers removed from all resources in $NAMESPACE. Waiting for cleanup..."
sleep 10

# Now, try to delete the namespace's finalizer again
kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null

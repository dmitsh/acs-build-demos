##
## A script for autoscaling using HPA and node autoscaler
##

# Initial configuration
kubectl get nodes
kubectl get pods -o wide
kubectl get pods --all-namespaces -o wide

# Start node auto-scaler
kubectl create -f scaling-controller.yaml

# Get the name of autoscaler pod
kubectl get pods -o wide

# Print the log. 
# Ideally autoscaler should recognize idle nodes and delete them
kubectl logs autoscaler-<suffix>

# Get current node status
kubectl get nodes

# Deploy ngnix
kubectl create -f ngnix.yaml 
kubectl get all

# Start HPA on ngnix
kubectl autoscale --cpu-percent 10 --max 6 deploy/nginx
kubectl get hpa

# Display current pods
kubectl get pods -o wide

# Deploy vegeta loader
kubectl create -f vegeta.yaml
kubectl get pods -o wide

# Show current load
kubectl get hpa

# Increase the load on ngnix
kubectl scale --replicas=10 rc/vegeta

# Show current load exceeding the threshold
kubectl get pods -o wide
kubectl get hpa

# Show that autoscaler schedules new nodes
kubectl logs autoscaler-<suffix> | grep "New capacity"

# Show current node configuration
kubectl get nodes
kubectl get pods -o wide

# cleanup
kubectl delete rc/autoscaler

kubectl delete rc/vegeta
kubectl delete hpa/nginx
kubectl delete deploy/nginx
kubectl delete svc/nginx
kubectl get all

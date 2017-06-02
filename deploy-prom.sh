#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: ./deploy-prom.sh ENVIRONMENT (where environment = dev, qa, or prod)"
    exit 1
fi

export kube_env=$1

### Uncomment the lines below if you want delete and re-create prometheus and grafana stack.
# if [[ "$(kubectl get namespaces | awk '/monitoring/ {print $1}')" == "monitoring" ]] ; then
#     kubectl delete namespace monitoring
#     sleep 60s
# else
#     echo "Namespace monitoring does not exit"
# fi

for file in $(find ./manifests -type f -name "*.yaml" | sort) ; do
   kubectl apply --filename "$file"
done

# Create ConfigMap with Grafana dashboards and datasources
kubectl --namespace monitoring create configmap --dry-run grafana-import-dashboards \
  --from-file=configs/grafana \
  --output yaml \
    > /tmp/configmap-grafana-dashboard-tmp.yaml
# Workaround since `--namespace monitoring` from above is not preserved
echo "  namespace: monitoring" >>  /tmp/configmap-grafana-dashboard-tmp.yaml

kubectl --namespace monitoring apply -f /tmp/configmap-grafana-dashboard-tmp.yaml
kubectl --namespace monitoring create configmap prometheus-core --from-file=configs/prometheus
kubectl --namespace monitoring create configmap cloudwatch-exporter --from-file=configs/cloudwatch-exporter

## Create a configmap file
#kubectl --namespace prom-monitor create configmap --dry-run cloudwatch-exporter \
#  --from-file=configs/cloudwatch-exporter \
#  --output yaml \
#  > ./manifests/prometheus/cloudwatch-exporter/configmap.yaml
#
#  echo "  namespace: prom-monitor" >> manifests/prometheus/cloudwatch-exporter/configmap.yaml

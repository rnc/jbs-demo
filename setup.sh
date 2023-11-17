#!/bin/bash
#
#
# Bit of a hack, but lets expect jbs-installer directory to be cloned next to this one.
if [ ! -d "$(dirname $0)/../jbs-installer" ]; then
    echo "Clone jbs-installer"
fi

echo -e "\033[0;32mRunning JBS demo kustomize...\033[0m"
kustomize build . | kubectl apply -f -

# Loop until the route is ready. Should be far quicker than waiting for the entire nexus startup.
timeout=300
endTime=$(( $(date +%s) + timeout ))
until kubectl get --namespace=nexus routes.route.openshift.io nexus3 -o=jsonpath="{.status.ingress[0].host}" ; do
    sleep 1
    if [ $(date +%s) -gt $endTime ]; then
        exit 1
    fi
done
echo ""

export MAVEN_USERNAME=admin
export MAVEN_PASSWORD=admin123
export MAVEN_REPOSITORY="http://$(kubectl get --namespace=nexus routes.route.openshift.io nexus3 -o=json | jq -r '.spec.host')/repository/maven-releases"

echo -e "\033[0;32mCompleted setup (MAVEN_REPOSITORY is \"$MAVEN_REPOSITORY\" and PWD \"$MAVEN_PASSWORD\" )\033[0m"
cd $(dirname $0)/../jbs-installer && ./deploy.sh

echo -e "\033[0;32mCompleted setup\033[0m"
# Before doing any builds we might need to wait to allow nexus time to start...
echo -e "\033[0;32mWaiting to allow nexus time to start...\033[0m"
kubectl wait --namespace=nexus --for=condition=Available --timeout=480s deployments.apps nexus3

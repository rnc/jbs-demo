#!/bin/bash
#
#
# Bit of a hack, but lets expect jbs-installer directory to be cloned next to this one.
if [ ! -d "$(dirname $0)/../jbs-installer" ]; then
    echo "Clone jbs-installer"
fi

export OPENSHIFT_CLUSTER="$(kubectl get route -n openshift-console console -ojsonpath='{.status.ingress[0].host}' | sed 's/console-openshift-console.//')"
echo "Domain is $OPENSHIFT_CLUSTER"
kubectl config set-context --current --namespace=default

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

if [ "$1" = "-g" ]; then
    echo "Installing GitLab"
    kustomize build gitlab | envsubst '${OPENSHIFT_CLUSTER}' | kubectl apply -f -

    echo -e "\033[0;32mWait for GitLab to start (note: this will take a long time)\033[0m"
    echo -e "Run the following command to extract the password:"
    echo -e "\033[0;30mkubectl -n gitlab-system get secrets gitlab-gitlab-initial-root-password -o yaml | yq e '.data.password' - | base64 -d\033[0m"
    echo -e "Finally login with username 'root' and extracted password to create a token."
    echo -e "Set 'export GIT_DEPLOY_TOKEN=<value>' and rerun this script without the -g flag"
    kubectl wait --namespace=gitlab-system --for=condition=Available --timeout=480s gitlab gitlab
    exit 0
fi

echo -e "\033[0;32mRunning JBS demo kustomize...\033[0m"

# Default username/password from a Nexus installation that should be changed when using outside of a development/demo based scenario.
export MAVEN_USERNAME=admin
export MAVEN_PASSWORD=admin123
export MAVEN_REPOSITORY="http://$(kubectl get --namespace=nexus routes.route.openshift.io nexus3 -o=json | jq -r '.spec.host')/repository/maven-releases"
export GIT_DEPLOY_IDENTITY=root
export GIT_DEPLOY_URL="https://gitlab.$OPENSHIFT_CLUSTER"

echo -e "\033[0;32mCompleted setup (MAVEN_REPOSITORY is \"$MAVEN_REPOSITORY\")\033[0m"
cd $(dirname $0)/../jbs-installer && ./deploy.sh

echo -e "\033[0;32mCompleted setup\033[0m"

# Before doing any builds we might need to wait to allow nexus time to start...
echo -e "\033[0;32mWaiting to allow nexus time to start...\033[0m"
kubectl wait --namespace=nexus --for=condition=Available --timeout=480s deployments.apps nexus3

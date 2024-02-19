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

# Wait until the route is ready. Should be far quicker than waiting for the entire nexus startup.
kubectl wait --namespace=nexus --for=jsonpath='{.status.ingress[0].host}' --timeout=480s routes.route.openshift.io nexus3 || exit 1

echo ""

if [ "$1" = "-g" ]; then
    echo "Installing GitLab"
#    kubectl apply -f gitlab/namespace.yaml
#    kubectl apply -f gitlab/gitlab-operatorgroup.yaml
#    kubectl apply -f gitlab/subscription-certmanager.yaml
#    kubectl rollout status deployment -n openshift-operators cert-manager
#    kubectl rollout status deployment -n openshift-operators cert-manager-webhook
#    kubectl wait --for=condition=Available --timeout=480s -n openshift-operators deployment.apps cert-manager
#    kubectl wait --for=condition=Available --timeout=480s -n openshift-operators deployment.apps cert-manager-webhook
#    kubectl apply -f gitlab/subscription-gitlab.yaml
#    kubectl rollout status -n gitlab-system deployment gitlab-controller-manager

    kustomize build gitlab | envsubst '${OPENSHIFT_CLUSTER}' | kubectl apply -f -
    echo -e "\033[0;32mWait for GitLab to start (note: this will take a long time)\033[0m"
    echo -e "Run the following command to extract the password:"
    echo -e "\033[0;30mkubectl -n gitlab-system get secrets gitlab-gitlab-initial-root-password -o yaml | yq e '.data.password' - | base64 -d\033[0m"
    echo -e "Finally login with username 'root' and extracted password to create a token."
    echo -e "Set 'export GIT_DEPLOY_TOKEN=<value>' and rerun this script without the -g flag"
    echo -e "Run the following command to extract the domain:"
    echo -e "\033[0;30mecho \"https://gitlab.\`kubectl get gitlabs.apps.gitlab.com -n gitlab-system -o yaml | yq e '.items[].spec.chart.values.global.hosts.domain'\`\"\033[0m"
    echo -e "Set 'export GIT_DEPLOY_URL=<value>' and rerun this script without the -g flag"
    echo -e ""
    echo -e "This invocation with -g might need to be rerun if the instance rollout hasn't proceeded...sleeping for a minute ..."

    sleep 60
    kubectl rollout status deployment -n openshift-operators cert-manager
    kubectl rollout status deployment -n openshift-operators cert-manager-webhook
    kubectl rollout status -n gitlab-system deployment gitlab-controller-manager
    kubectl wait --for=condition=Available --timeout=480s -n openshift-operators deployment.apps cert-manager
    kubectl wait --for=condition=Available --timeout=480s -n openshift-operators deployment.apps cert-manager-webhook

    kubectl apply --dry-run=client -o yaml -f gitlab/gitlab.yaml | envsubst '${OPENSHIFT_CLUSTER}' | kubectl apply -f -
    kubectl wait --namespace=gitlab-system --for=condition=Available --timeout=480s gitlab gitlab

    exit 0
fi

echo -e "\033[0;32mCompleted JBS demo kustomize...\033[0m"

# Default username/password from a Nexus installation that should be changed when using outside of a development/demo based scenario.
export MAVEN_USERNAME=admin
export MAVEN_PASSWORD=admin123
export MAVEN_REPOSITORY="http://$(kubectl get --namespace=nexus routes.route.openshift.io nexus3 -o=json | jq -r '.spec.host')/repository/maven-releases"
export GIT_DEPLOY_IDENTITY=root
export GIT_DEPLOY_URL="https://gitlab.$OPENSHIFT_CLUSTER"
export GIT_DISABLE_SSL_VERIFICATION="true"

echo -e "\033[0;32mCompleted setup (MAVEN_REPOSITORY is \"$MAVEN_REPOSITORY\")\033[0m"
cd $(dirname $0)/../jbs-installer && ./deploy.sh

echo -e "\033[0;32mCompleted setup\033[0m"

# Before doing any builds we might need to wait to allow nexus time to start...
echo -e "\033[0;32mWaiting to allow nexus time to start...\033[0m"
kubectl wait --namespace=nexus --for=condition=Available --timeout=480s deployments.apps nexus3

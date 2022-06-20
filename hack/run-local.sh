#!/usr/bin/env bash

set -euox pipefail

#oc scale --replicas 0 -n openshift-cluster-version deployments/cluster-version-operator
oc scale --replicas 0 -n openshift-ingress-operator deployments ingress-operator

IMAGE=$(oc get -n openshift-ingress-operator deployments/ingress-operator -o json | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="IMAGE").value')
RELEASE_VERSION=$(oc get clusterversion/version -o json | jq -r '.status.desired.version')
RELEASE_VERSION="${RELEASE_VERSION:-unknown}"
NAMESPACE="${NAMESPACE:-"openshift-ingress-operator"}"
SHUTDOWN_FILE="${SHUTDOWN_FILE:-""}"

echo "Image: ${IMAGE}"
echo "Release version: ${RELEASE_VERSION}"
echo "Namespace: ${NAMESPACE}"

if [[ ! -z ${ENABLE_CANARY:-} ]]; then
    CANARY_IMAGE=$(oc get -n openshift-ingress-operator deployments/ingress-operator -o json | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="CANARY_IMAGE").value')
    echo "Canary Image: ${CANARY_IMAGE}"
fi

${DELVE:-} ./ingress-operator start --image "${IMAGE}" --canary-image=${CANARY_IMAGE:-} --release-version "${RELEASE_VERSION}" \
--namespace "${NAMESPACE}" --shutdown-file "${SHUTDOWN_FILE}" "$@"

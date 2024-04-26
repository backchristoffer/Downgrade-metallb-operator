#!/bin/bash

NAMESPACE="metallb-system"
CURRENT_CSV=$(oc get csv -n "$NAMESPACE" --no-headers | awk '{print $1}')

if [ -n "$1" ]; then
    NEW_CSV="$1"
else
    NEW_CSV="metallb-operator.4.12.0-202311220908"
fi

SUBSCRIPTION_YAML='
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: metallb-operator
  namespace: metallb-system
spec:
  channel: stable
  installPlanApproval: Manual
  name: metallb-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: '"$NEW_CSV"'
'
echo "Installed CSV:"
echo $CURRENT_CSV
echo "Deleting current CSV..."
oc delete csv -n "$NAMESPACE" $CURRENT_CSV &> /dev/null
echo "Deleting current Subscription..."
oc delete subscription -n "$NAMESPACE" metallb-operator &> /dev/null
echo "Deleting InstallPlans..."
oc delete installplan -n "$NAMESPACE" --all &> /dev/null

echo "Applying new Subscription..."
echo "$SUBSCRIPTION_YAML" | oc apply -f - &> /dev/null

sleep 10

INSTALLPLAN=$(oc get installplan -n "$NAMESPACE" --no-headers | grep "$NEW_CSV" | awk '{print $1}')
if [ -n "$INSTALLPLAN" ]; then
    echo "Approving InstallPlan..."
    oc patch installplan "$INSTALLPLAN" -n "$NAMESPACE" --type merge -p '{"spec":{"approved":true}}' &> /dev/null
fi

sleep 10
echo "Script completed successfully!"
echo "Installed CSV (after script execution):"
echo $CURRENT_CSV

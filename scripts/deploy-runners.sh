#!/bin/bash
# Script to deploy GitHub self-hosted runners to Kubernetes

# Check if all required parameters are provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <runner-name-prefix> <runner-count> <runner-labels> <github-token> <github-repo>"
    exit 1
fi

RUNNER_NAME_PREFIX=$1
RUNNER_COUNT=$2
RUNNER_LABELS=$3
GITHUB_TOKEN=$4
GITHUB_REPO=$5

echo "Deploying GitHub runners with the following parameters:"
echo "Runner Name Prefix: $RUNNER_NAME_PREFIX"
echo "Runner Count: $RUNNER_COUNT"
echo "Runner Labels: $RUNNER_LABELS"
echo "GitHub Repository: $GITHUB_REPO"

# Create temporary directory for runner manifests
TEMP_DIR=$(mktemp -d)
mkdir -p $TEMP_DIR

for (( i=1; i<=$RUNNER_COUNT; i++ ))
do
    RUNNER_NAME="${RUNNER_NAME_PREFIX}-${i}"
    
    # Create manifest for GitHub Runner
    cat > $TEMP_DIR/runner-${i}.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${RUNNER_NAME}
  namespace: github-runners
  labels:
    app: github-runner
spec:
  containers:
  - name: github-runner
    image: ghcr.io/actions/actions-runner:latest
    env:
    - name: RUNNER_NAME
      value: "${RUNNER_NAME}"
    - name: RUNNER_LABELS
      value: "${RUNNER_LABELS}"
    - name: RUNNER_TOKEN
      value: "${GITHUB_TOKEN}"
    - name: RUNNER_REPO
      value: "${GITHUB_REPO}"
    - name: RUNNER_WORK_DIRECTORY
      value: "_work"
    command:
    - "/bin/bash"
    - "-c"
    - |
      ./config.sh --url https://github.com/${GITHUB_REPO} --token ${GITHUB_TOKEN} --name ${RUNNER_NAME} --labels ${RUNNER_LABELS} --work _work --unattended --ephemeral
      ./run.sh
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
  restartPolicy: Always
EOF

    echo "Deploying runner: $RUNNER_NAME"
    kubectl apply -f $TEMP_DIR/runner-${i}.yaml
done

# Verify runner deployment
echo "Verifying runner deployment..."
kubectl get pods -n github-runners -l app=github-runner

# Cleanup
rm -rf $TEMP_DIR

echo "GitHub runners deployment completed!"

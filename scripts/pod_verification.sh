#!/bin/bash

SERVICE_CODE="mobius-utility-service"
GITHUB_SHA="54764c1031108a56add6ade4d0a5b03902930d26"
MAX_RETRIES=3
SLEEP_DURATION=120
RESULT_FILE="/tmp/pod_verification_result.json"

echo "Verifying pod status for service: $SERVICE_CODE with SHA: $GITHUB_SHA"

for ((i=1; i<=MAX_RETRIES; i++)); do
    RESPONSE=$(curl -s -X 'GET' "https://ig.aidtaas.com/gitactions/pod-status/?app_name=$SERVICE_CODE" -H 'accept: application/json')

    if [ -z "$RESPONSE" ]; then
        echo "Error: No response from the pod status API."
        if [ $i -lt $MAX_RETRIES ]; then
            echo "Retrying in $SLEEP_DURATION seconds..."
            sleep $SLEEP_DURATION
            continue
        else
            echo "{\"status\":\"failure\",\"message\":\"No response from the pod status API.\"}" > $RESULT_FILE
            exit 1
        fi
    fi

    POD_STATUS=$(echo "$RESPONSE" | jq -r .pod_status)
    CONTAINER_IMAGE=$(echo "$RESPONSE" | jq -r .container_image)

    echo "Attempt $i: Pod Status: $POD_STATUS, Container Image: $CONTAINER_IMAGE"

    if [[ "$POD_STATUS" == "Running" && "$CONTAINER_IMAGE" == "gaianmobius/$SERVICE_CODE:$GITHUB_SHA" ]]; then
        echo "{\"status\":\"success\",\"service_code\":\"$SERVICE_CODE\",\"github_sha\":\"$GITHUB_SHA\"}" > $RESULT_FILE
        exit 0
    fi

    if [ $i -lt $MAX_RETRIES ]; then
        echo "Pod status or image not as expected. Retrying in $SLEEP_DURATION seconds..."
        sleep $SLEEP_DURATION
    else
        echo "{\"status\":\"failure\",\"message\":\"Pod did not reach expected status.\"}" > $RESULT_FILE
        exit 1
    fi
done

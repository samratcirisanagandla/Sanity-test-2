#!/bin/bash

SERVICE_CODE="${SERVICE_CODE:-mobius-utility-service}"
WORKFLOW_STATUS="$2"
WEBHOOK_URL="${WEBHOOK_URL:-https://chat.googleapis.com/v1/spaces/AAAAbkkpaIU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=yYYoov7obNuUq86dW5E7RkHreUpcoROju45s_q7EIpM}"
ACTION_URL="${ACTION_URL:-https://github.com/my-repo/actions/runs/12345}"

if [ "$WORKFLOW_STATUS" == "success" ]; then
	MESSAGE="Workflow completed successfully for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
else
	MESSAGE="Workflow failed for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
fi

curl -X POST "$WEBHOOK_URL" \
 	-H 'Content-Type: application/json' \
 	-d "{\"text\": \"$MESSAGE\"}"

echo "Notification sent to Google Chat."

#!/bin/bash

set -e

# Elimina caracteres de control (como ^H) que PyYAML no puede leer
sanitize_input() {
  echo "$1" | tr -d '[:cntrl:]' | sed -E "s/^['\"]+//;s/['\"]+\$//"
}



echo "---------------------------------------------"
echo "Alert Integration Service - Installation Tool"
echo "---------------------------------------------"
read -rp "Enter the path in which the application will run (leave blank to use current directory): " INSTALL_DIR
if [[ -z "$INSTALL_DIR" ]]; then
  INSTALL_DIR="$(pwd)"
  echo "Using current directory: $INSTALL_DIR"
else
  INSTALL_DIR=$(realpath "$INSTALL_DIR")
fi

echo ""
echo "--------------------"
echo "Installation Summary"
echo "--------------------"
echo "Working directory that the application will run in: $INSTALL_DIR"
echo "Python binary to install: $(pwd)/ais-middleware"
echo ""

read -rp "Proceed with configuration and installation? [y/n] " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "Installation aborted." && exit 1

echo ""
echo "Starting install..."

# Crear estructura
mkdir -p "$INSTALL_DIR/Config"
mkdir -p "$INSTALL_DIR/Logs"
mkdir -p "$INSTALL_DIR/Database"

# Copiar binario si es necesario
if [[ "$(realpath ./ais-middleware)" != "$(realpath "$INSTALL_DIR/ais-middleware")" ]]; then
  cp ./ais-middleware "$INSTALL_DIR/"
  chmod +x "$INSTALL_DIR/ais-middleware"
else
  echo "Executable already present in destination, skipping copy."
fi

CONFIG_FILE="$INSTALL_DIR/Config/config.yaml"
echo "Generating config file at: $CONFIG_FILE"
echo ""

# Inicializar YAML
cat > "$CONFIG_FILE" <<EOF
app:
  version: 3.0

spring:
  mail:
    enabled: false
    host:
    username:
    password:
    properties:
      mail:
        transport:
          protocol: smtp
        smtp:
          port: 587
          auth: true
          starttls:
            enable: false
            required: true
        to:
        from:

serverMonitoring:
  emailNotificationCooldown: 3600

endpoints:
  transmissionRetry:
    numRetries: 3
    retryTimeout: 300
  services:
EOF

# Integraciones
while true; do
  echo ""
  echo "Select an endpoint to configure:"
  echo "1. alertsapi"
  echo "2. servicenow"
  echo "0. Finished"
  read -rp "Enter number: " endpoint

  case "$endpoint" in
    1)
      read -rp "alertsApi Webhook URL: " webhook
      read -rp "alertsApi Key (optional): " key
      read -rp "alertsApi OAuth Token (optional): " token
      read -rp "Custom Subject (optional): " subject
      read -rp "Custom Text (optional): " text

      {
        echo "    - name: alertsapi"
        echo "      alertsApiWebhookUrl: '$webhook'"
        [[ -n "$key" ]] && echo "      alertsApiKey: '$key'"
        [[ -n "$token" ]] && echo "      alertsApiOAuthToken: '$token'"
        echo "      alertsApiVersion: 'alertapi-0.1'"
        echo "      alertsApiType: 'ALERT'"
        echo "      alertsApiSeverityLevels:"
        echo "        - CRITICAL"
        echo "        - MAJOR"
        echo "        - MINOR"
        echo "        - WARNING"
        echo "        - INFO"
        echo "      alertsApiTriggerSeverityDefault: 'MAJOR'"
        echo "      alertsApiClearSeverityDefault: 'MINOR'"
        [[ -n "$subject" ]] && echo "      customAPSubject: '$subject'"
        [[ -n "$text" ]] && echo "      customAPText: '$text'"
      } >> "$CONFIG_FILE"
      ;;
    2)
      read -rp "ServiceNow URL (e.g. https://instance.service-now.com): " raw_snow_url
      snow_url=$(sanitize_input "$raw_snow_url")

      read -rp "ServiceNow Username: " snow_user
      read -rp "ServiceNow Password: " snow_pass
      read -rp "Custom Subject (optional): " snow_subject
      read -rp "Custom Text (optional): " snow_text

      {
        echo "    - name: servicenow"
        echo "      snowWebhookUrl: '$snow_url'"
        echo "      snowUsername: '$snow_user'"
        echo "      snowPassword: '$snow_pass'"
        [[ -n "$snow_subject" ]] && echo "      customAPSubject: '$snow_subject'"
        [[ -n "$snow_text" ]] && echo "      customAPText: '$snow_text'"
        echo "      snowConfigurationTemplate:"
        echo "        - field: '_use_severity_mapping'"
        echo "          value: true"
        echo "        - field: '_severity_mapping'"
        echo "          value:"
        echo "            critical:"
        echo "              impact: '1'"
        echo "              urgency: '1'"
        echo "              priority: '1'"
        echo "            major:"
        echo "              impact: '2'"
        echo "              urgency: '2'"
        echo "              priority: '2'"
        echo "            minor:"
        echo "              impact: '3'"
        echo "              urgency: '3'"
        echo "              priority: '3'"
        echo "            info:"
        echo "              impact: '4'"
        echo "              urgency: '4'"
        echo "              priority: '4'"
        echo "        - field: '_populate_work_notes'"
        echo "          value: true"
        echo "        - field: '_autoclose_ticket_on_clear'"
        echo "          value: true"
        echo "        - field: '_state_on_ticket_closed'"
        echo "          value: 'Resolved'"
        echo "        - field: '_state_on_alert_trigger'"
        echo "          value: 'New'"
        echo "        - field: '_default_agent_alert_assignment_group'"
        echo "          value: 'Default Agent Alert Assignment Group'"
        echo "        - field: '_default_test_alert_assignment_group'"
        echo "          value: 'Default Test Alert Assignment Group'"
        echo "        - field: '_default_agent_ci'"
        echo "          value: '%AGENT_NAME%'"
        echo "        - field: '_default_test_ci'"
        echo "          value: '%TEST_NAME%'"
        echo "        - field: 'caller_id'"
        echo "          value: 'ThousandEyes SA'"
        echo "        - field: 'category'"
        echo "          value: 'network'"
        echo "        - field: 'subcategory'"
        echo "          value: 'Alert'"
        echo "        - field: 'business_service'"
        echo "          value: 'Business Service'"
        echo "        - field: 'contact_type'"
        echo "          value: 'Monitoring System'"
        echo "        - field: 'work_notes'"
        echo "          value: 'Created by AIS version 3.0'"
        echo "          phase: 'New'"
        echo "        - field: 'close_notes'"
        echo "          value: 'Service restored by ThousandEyes engineers'"
        echo "          phase: 'Resolved'"
        echo "        - field: 'short_description'"
        echo "          value: '%RULE_NAME% is experiencing an issue with severity: %SEVERITY%. Please investigate.'"
        echo "        - field: 'close_code'"
        echo "          value: 'Resolved by Caller'"
        echo "          phase: 'Resolved'"
      } >> "$CONFIG_FILE"
      ;;
    0)
      break
      ;;
    *)
      echo "Invalid option."
      ;;
  esac
done

# Config de ThousandEyes Poller
echo ""
read -rp "Use API Poller to fetch ThousandEyes data? [Y/n]: " poller_use
[[ "$poller_use" =~ ^[nN]$ ]] && poller="false" || poller="true"

read -rp "Organization name (ThousandEyes): " org_name
read -rp "Bearer token: " token
read -rp "Account Groups to monitor (comma or wildcard): " ags

cat >> "$CONFIG_FILE" <<EOF

teapipoller:
  general-parameters:
    runApiPoller: $poller
    executionInterval: 20
    apiMaxRetries: 3
    apiSocketConnectTimeoutMs: 5000
    apiSocketReadTimeoutMs: 15
    organizationName: "$org_name"
    testEndpoint: 'https://api.thousandeyes.com/v7/status'
    apiVersion: 'v7'
    bearerToken: '$token'
    account-group-configuration:
      suppressAlertClearWebhooks:
        - "*-Prod"
      include:
        - "$ags"
      exclude:
        - "*-Prod*"

  queryAlertEndpoint:
    doQueryAlertEndpoint: true
    doMetadataEnrichment: false
    metadataFields: description,type,url,server,prefix,targetAgentId,domain,sipRegistrar

  enterpriseAgentChecks:
    doEnterpriseAgentsCheck: true
    enterpriseAgentOfflineMinutes: 2
    enterpriseAgentCheckIntervalMs: 120000
    agentCacheDataRefreshMs: 360000

  activityLogChecks:
    doQueryActivityLog: true
    activityLogDataWindow: 15m
    maxActivityLogEntryAgeSeconds: 600

  heartbeat:
    sendHeartbeat: false
    heartbeatUrl: ''
    heartbeatIntervalMs: 300000
    heartbeatPayload:
      - key: '@key'
        value: ''
      - key: '@type'
        value: 'HEARTBEAT'
      - key: '@version'
        value: 'alertapi-0.1'
      - key: 'occurtime'
        value: '__timestamp'
EOF

echo ""


# Crear archivo .service para systemd
SERVICE_NAME="alert-integration-service"
SERVICE_FILE="$INSTALL_DIR/$SERVICE_NAME.service"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Alert Integration Service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/ais-middleware
WorkingDirectory=$INSTALL_DIR
Restart=always
RestartSec=5
StandardOutput=append:$INSTALL_DIR/Logs/app.log
StandardError=append:$INSTALL_DIR/Logs/error.log

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Systemd service definition created at: $SERVICE_FILE"
echo "You can install and start the service by running:"
echo "  sudo cp $SERVICE_FILE /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable $SERVICE_NAME"
echo "  sudo systemctl start $SERVICE_NAME"



echo "Installation complete!"
echo "Executable located at: $INSTALL_DIR/ais-middleware"
echo "Configuration file located at: $CONFIG_FILE"

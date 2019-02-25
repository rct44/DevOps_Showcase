#!/bin/sh

echo "Grafana and Prometheus provisioning and config updates!"

sudo cp prometheus-files/prometheus /usr/local/bin/
sudo cp prometheus-files/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo cp -r prometheus-files/consoles /etc/prometheus
sudo cp -r prometheus-files/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

sudo cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
 
[Install]
WantedBy=multi-user.target
EOF

# edit prometheus configuration file which will pull metrics from node_exporter
# every 15 seconds time interval
sudo cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  
  - job_name: 'nodes'

    static_configs:
    - targets: ['10.0.0.10:9100']


EOF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

sudo systemctl daemon-reload

sudo systemctl stop prometheus

sudo systemctl start prometheus

sudo systemctl status prometheus

#create directory for grafana installation files
# so that we can extrac all the files into it
sudo mkdir -p /home/vagrant/Grafana/server
sudo cd /home/vagrant/Grafana/server

sudo yum -y install initscripts fontconfig urw-fonts

sudo wget https://dl.grafana.com/oss/release/grafana-5.4.3-1.x86_64.rpm


sudo rpm -Uvh grafana-5.4.3-1.x86_64.rpm


sudo cat <<EOF > /usr/share/grafana/conf/provisioning/datasources/datasource.yaml
# config file version
apiVersion: 1

# list of datasources that should be deleted from the database
deleteDatasources:
  - name: Prometheus
    orgId: 1

# list of datasources to insert/update depending
# whats available in the database
datasources:
# <string, required> name of the datasource. Required
- name: Prometheus
  # <string, required> datasource type. Required
  type: prometheus
  # <string, required> access mode. direct or proxy. Required
  access: direct
  # <int> org id. will default to orgId 1 if not specified
  orgId: 1
  # <string> url
  url: http://10.0.0.10:9090
  # <string> database password, if used
  password:
  # <string> database user, if used
  user:
  # <string> database name, if used
  database:
  # <bool> enable/disable basic auth
  basicAuth: false
  # <string> basic auth username
  #basicAuthUser: admin
  # <string> basic auth password
  #basicAuthPassword: foobar
  # <bool> enable/disable with credentials headers
  #withCredentials:
  # <bool> mark as default datasource. Max one per org
  isDefault: true
  # <map> fields that will be converted to json and stored in json_data
  #jsonData:
   #  graphiteVersion: "1.1"
   #  tlsAuth: false
   #  tlsAuthWithCACert: false
  # <string> json object of data that will be encrypted.
  #secureJsonData:
  #  tlsCACert: "..."
  #  tlsClientCert: "..."
  #  tlsClientKey: "..."
  version: 1
  # <bool> allow users to edit datasources from the UI.
  editable: true
EOF

sudo cat <<EOF > /usr/share/grafana/conf/provisioning/dashboards/dashboards.yaml
apiVersion: 1

providers:
- name: 'default'
  orgId: 1
  folder: ''
  type: file
  updateIntervalSeconds: 10 #how often Grafana will scan for changed dashboards
  options:
     path: '/var/lib/grafana/dashboards'
EOF

sudo mkdir -p /var/lib/grafana/dashboards/

sudo cat <<EOF > /var/lib/grafana/dashboards/dashboards.json
{
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": "-- Grafana --",
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          }
        ]
      },
      "description": "Dashboard to get an overview of one server",
      "editable": false,
      "gnetId": 704,
      "graphTooltip": 0,
      "id": null,
      "iteration": 1,
      "links": [],
      "panels": [
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 3,
            "x": 0,
            "y": 0
          },
          "height": "250",
          "id": 29,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{instance=~\"10.0.0.10:9100\", mode=\"idle\"}[2m])) * 100)",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A",
              "step": 120
            }
          ],
          "thresholds": "80,90",
          "title": "Current CPU Use",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "decimals": null,
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 3,
            "x": 3,
            "y": 0
          },
          "height": "250",
          "id": 30,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "100 - (node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"} - (node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_MemFree_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Cached_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Buffers_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Slab_bytes{instance=~\"10.0.0.10:9100\"})) / (node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"}) * 100",
              "format": "time_series",
              "instant": false,
              "intervalFactor": 2,
              "refId": "A",
              "step": 240
            }
          ],
          "thresholds": "80,90",
          "title": "Current Memory Use",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "decimals": 2,
          "description": "Used Swap",
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 3,
            "x": 6,
            "y": 0
          },
          "id": 43,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "minSpan": 4,
          "nullPointMode": "null",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "((node_memory_SwapTotal_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_SwapFree_bytes{instance=~\"10.0.0.10:9100\"}) / (node_memory_SwapTotal_bytes{instance=~\"10.0.0.10:9100\"} )) * 100",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A",
              "step": 900
            }
          ],
          "thresholds": "80,90",
          "title": "Used SWAP",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "decimals": null,
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 4,
            "x": 9,
            "y": 0
          },
          "height": "250",
          "id": 31,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "100 - ((node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",device=\"/dev/mapper/vg00-lv00\",fstype=\"ext4\",mountpoint=\"/\"} / node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",device=\"/dev/mapper/vg00-lv00\",fstype=\"ext4\",mountpoint=\"/\"})*100)",
              "format": "time_series",
              "intervalFactor": 2,
              "refId": "A",
              "step": 240
            }
          ],
          "thresholds": "85,90",
          "title": "used space on /",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "decimals": null,
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 4,
            "x": 13,
            "y": 0
          },
          "height": "250",
          "id": 32,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "100 - ((node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",device=\"/dev/mapper/vg00-lv02\",fstype=\"ext4\",mountpoint=\"/var\"} / node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",device=\"/dev/mapper/vg00-lv02\",fstype=\"ext4\",mountpoint=\"/var\"})*100)",
              "format": "time_series",
              "intervalFactor": 2,
              "refId": "A",
              "step": 240
            }
          ],
          "thresholds": "85,90",
          "title": "used space on /var",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "Prometheus",
          "decimals": null,
          "format": "percent",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": true,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 5,
            "w": 4,
            "x": 17,
            "y": 0
          },
          "height": "250",
          "id": 48,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "100 - ((node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",mountpoint=\"/export\",fstype!=\"rootfs\"} / node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",mountpoint=\"/export\",fstype!=\"rootfs\"})*100)",
              "format": "time_series",
              "instant": false,
              "intervalFactor": 2,
              "legendFormat": "",
              "refId": "A",
              "step": 240
            }
          ],
          "thresholds": "85,90",
          "title": "used space on /export",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "s",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 4,
            "w": 3,
            "x": 21,
            "y": 0
          },
          "id": 37,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "time() - node_boot_time_seconds{instance=~\"10.0.0.10:9100*\"}",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Uptime",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "description": "Total storage includes all local mountpoints on the system.",
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 21,
            "y": 4
          },
          "id": 40,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\",device=~\"/dev/.*\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Total Storage",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 0,
          "format": "none",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 3,
            "x": 0,
            "y": 5
          },
          "id": 39,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "count(node_cpu_seconds_total{instance=~\"10.0.0.10:9100\", mode=\"system\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "vCPU Assigned",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 0,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 3,
            "x": 3,
            "y": 5
          },
          "id": 38,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100*\"}",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "RAM Assigned",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "rgba(245, 54, 54, 0.9)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(50, 172, 45, 0.97)"
          ],
          "datasource": "Prometheus",
          "decimals": 2,
          "description": "Total SWAP",
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 3,
            "x": 6,
            "y": 5
          },
          "id": 45,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "minSpan": 4,
          "nullPointMode": "null",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "70%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "node_memory_SwapTotal_bytes{instance=~\"10.0.0.10:9100\"}",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A",
              "step": 900
            }
          ],
          "thresholds": "",
          "title": "Total SWAP",
          "type": "singlestat",
          "valueFontSize": "50%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 9,
            "y": 5
          },
          "id": 46,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",mountpoint=\"/\",fstype!=\"rootfs\"}",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Total Storage on /",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 11,
            "y": 5
          },
          "id": 52,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",mountpoint=\"/\",fstype!=\"rootfs\"}",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Free Storage on /",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 13,
            "y": 5
          },
          "id": 47,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\", device=~\"/dev/.*\",mountpoint=~\"/var\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Total Storage on /var",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 15,
            "y": 5
          },
          "id": 53,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\", device=~\"/dev/.*\",mountpoint=~\"/var\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Free Storage on /var",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 17,
            "y": 5
          },
          "id": 51,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\", device=~\"/dev/.*\",mountpoint=~\"/export\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Storage on /export",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "Prometheus",
          "decimals": 1,
          "format": "bytes",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 2,
            "w": 2,
            "x": 19,
            "y": 5
          },
          "id": 54,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\", device=~\"/dev/.*\",mountpoint=~\"/export\"})",
              "format": "time_series",
              "intervalFactor": 1,
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "Free on /export",
          "type": "singlestat",
          "valueFontSize": "70%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "avg"
        },
        {
          "alert": {
            "conditions": [
              {
                "evaluator": {
                  "params": [
                    90
                  ],
                  "type": "gt"
                },
                "operator": {
                  "type": "and"
                },
                "query": {
                  "params": [
                    "B",
                    "1h",
                    "now"
                  ]
                },
                "reducer": {
                  "params": [],
                  "type": "avg"
                },
                "type": "query"
              }
            ],
            "executionErrorState": "alerting",
            "frequency": "60s",
            "handler": 1,
            "name": "CPU Usage 10.0.0.10:9100 alert",
            "noDataState": "keep_state",
            "notifications": []
          },
          "alerting": {},
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Prometheus",
          "decimals": null,
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 0,
            "y": 7
          },
          "height": "300",
          "id": 9,
          "legend": {
            "alignAsTable": true,
            "avg": false,
            "current": false,
            "hideZero": true,
            "max": false,
            "min": false,
            "rightSide": true,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [
            {
              "targetBlank": true,
              "title": "CPU details for 10.0.0.10:9100",
              "type": "absolute",
              "url": "http://10.0.0.10/dashboard/db/drilldown-level-5-detailed-cpu?var-projName=&var-server=10.0.0.10:9100&var-cpu=All"
            }
          ],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [
            {
              "alias": "user cpu1",
              "yaxis": 1
            },
            {
              "alias": "Total"
            }
          ],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "(irate(node_cpu_seconds_total{instance=~\"10.0.0.10:9100\", mode!=\"idle\"}[5m]) * 100)",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "{{mode}} {{cpu}}",
              "refId": "A",
              "step": 30,
              "target": ""
            },
            {
              "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{instance=~\"10.0.0.10:9100\", mode=\"idle\"}[5m])) * 100 )",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "Average CPU Usage",
              "refId": "B"
            },
            {
              "expr": "100 - (irate(node_cpu_seconds_total{instance=~\"10.0.0.10:9100\", mode=\"idle\"}[5m]) * 100)",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "Total Usage {{cpu}}",
              "refId": "C"
            }
          ],
          "thresholds": [
            {
              "colorMode": "critical",
              "fill": true,
              "line": true,
              "op": "gt",
              "value": 90
            }
          ],
          "timeFrom": null,
          "timeShift": null,
          "title": "CPU Usage 10.0.0.10:9100",
          "tooltip": {
            "msResolution": false,
            "shared": true,
            "sort": 2,
            "value_type": "individual"
          },
          "transparent": false,
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "decimals": null,
              "format": "percent",
              "label": "",
              "logBase": 1,
              "max": null,
              "min": 0,
              "show": true
            },
            {
              "format": "percent",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "alert": {
            "conditions": [
              {
                "evaluator": {
                  "params": [
                    16
                  ],
                  "type": "gt"
                },
                "operator": {
                  "type": "and"
                },
                "query": {
                  "params": [
                    "B",
                    "1h",
                    "now"
                  ]
                },
                "reducer": {
                  "params": [],
                  "type": "avg"
                },
                "type": "query"
              }
            ],
            "executionErrorState": "alerting",
            "frequency": "60s",
            "handler": 1,
            "name": "Load Average 10.0.0.10:9100 alert",
            "noDataState": "keep_state",
            "notifications": []
          },
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Prometheus",
          "decimals": 2,
          "fill": 1,
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 8,
            "y": 7
          },
          "height": "300",
          "id": 23,
          "legend": {
            "alignAsTable": false,
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(node_load1{instance=~\"10.0.0.10:9100\"})",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "Load 1m",
              "metric": "",
              "refId": "A",
              "step": 30
            },
            {
              "expr": "sum(node_load5{instance=~\"10.0.0.10:9100\"})",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "Load 5m",
              "metric": "",
              "refId": "B",
              "step": 30
            },
            {
              "expr": "sum(node_load15{instance=~\"10.0.0.10:9100\"})",
              "format": "time_series",
              "interval": "30s",
              "intervalFactor": 1,
              "legendFormat": "Load 15m",
              "metric": "",
              "refId": "C",
              "step": 30
            }
          ],
          "thresholds": [
            {
              "colorMode": "critical",
              "fill": true,
              "line": true,
              "op": "gt",
              "value": 16
            }
          ],
          "timeFrom": null,
          "timeShift": null,
          "title": "Load Average 10.0.0.10:9100",
          "tooltip": {
            "shared": true,
            "sort": 1,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "alert": {
            "conditions": [
              {
                "evaluator": {
                  "params": [
                    90
                  ],
                  "type": "gt"
                },
                "operator": {
                  "type": "and"
                },
                "query": {
                  "params": [
                    "E",
                    "1h",
                    "now"
                  ]
                },
                "reducer": {
                  "params": [],
                  "type": "avg"
                },
                "type": "query"
              }
            ],
            "executionErrorState": "alerting",
            "frequency": "60s",
            "handler": 1,
            "name": "Memory usage 10.0.0.10:9100 alert",
            "noDataState": "keep_state",
            "notifications": []
          },
          "alerting": {},
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Prometheus",
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 16,
            "y": 7
          },
          "height": "300",
          "id": 4,
          "legend": {
            "alignAsTable": false,
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [
            {
              "alias": "Free",
              "zindex": 3
            },
            {
              "alias": "Memory % Used",
              "yaxis": 2
            }
          ],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_MemFree_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Cached_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Buffers_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Slab_bytes{instance=~\"10.0.0.10:9100\"}",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "Used",
              "metric": "memo",
              "refId": "A",
              "step": 15,
              "target": ""
            },
            {
              "expr": "node_memory_Buffers_bytes{instance=~\"10.0.0.10:9100\"}",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "Buffers",
              "refId": "C",
              "step": 15
            },
            {
              "expr": "node_memory_Cached_bytes{instance=~\"10.0.0.10:9100\"} + node_memory_Slab_bytes{instance=~\"10.0.0.10:9100\"}",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "Cached",
              "refId": "D",
              "step": 15
            },
            {
              "expr": "node_memory_MemFree_bytes{instance=~\"10.0.0.10:9100\"} + node_memory_Cached_bytes{instance=~\"10.0.0.10:9100\"} + node_memory_Slab_bytes{instance=~\"10.0.0.10:9100\"}",
              "format": "time_series",
              "hide": false,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "Free",
              "refId": "B",
              "step": 15
            },
            {
              "expr": "((node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_MemFree_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Cached_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Buffers_bytes{instance=~\"10.0.0.10:9100\"} - node_memory_Slab_bytes{instance=~\"10.0.0.10:9100\"}) / node_memory_MemTotal_bytes{instance=~\"10.0.0.10:9100\"}) * 100",
              "format": "time_series",
              "hide": true,
              "intervalFactor": 2,
              "legendFormat": "Memory % Used",
              "refId": "E",
              "step": 30
            }
          ],
          "thresholds": [
            {
              "colorMode": "critical",
              "fill": true,
              "line": true,
              "op": "gt",
              "value": 90
            }
          ],
          "timeFrom": null,
          "timeShift": null,
          "title": "Memory usage 10.0.0.10:9100",
          "tooltip": {
            "msResolution": false,
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": [
              "current"
            ]
          },
          "yaxes": [
            {
              "format": "decbytes",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "percent",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Prometheus",
          "decimals": 2,
          "editable": true,
          "error": false,
          "fill": 0,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 9,
            "x": 0,
            "y": 15
          },
          "id": 27,
          "legend": {
            "alignAsTable": false,
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": true,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "(node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"} - node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"})*.94",
              "format": "time_series",
              "interval": "1s",
              "intervalFactor": 1,
              "legendFormat": "{{mountpoint}}",
              "metric": "",
              "refId": "A",
              "step": 600
            }
          ],
          "thresholds": [],
          "timeFrom": "7d",
          "timeShift": null,
          "title": "File system Growth Rates 10.0.0.10:9100",
          "tooltip": {
            "msResolution": false,
            "shared": true,
            "sort": 2,
            "value_type": "cumulative"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "decimals": null,
              "format": "decbytes",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "columns": [
            {
              "text": "Current",
              "value": "current"
            },
            {
              "text": "Min",
              "value": "min"
            },
            {
              "text": "Max",
              "value": "max"
            }
          ],
          "datasource": "Prometheus",
          "fontSize": "80%",
          "gridPos": {
            "h": 8,
            "w": 6,
            "x": 9,
            "y": 15
          },
          "hideTimeOverride": false,
          "id": 24,
          "links": [],
          "pageSize": null,
          "scroll": true,
          "showHeader": true,
          "sort": {
            "col": 0,
            "desc": true
          },
          "styles": [
            {
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "pattern": "Time",
              "type": "date"
            },
            {
              "alias": "",
              "colorMode": "cell",
              "colors": [
                "rgba(50, 172, 45, 0)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(245, 54, 54, 0.9)"
              ],
              "decimals": 2,
              "pattern": "Current|Min|Max",
              "thresholds": [
                "85",
                "90"
              ],
              "type": "number",
              "unit": "percent"
            },
            {
              "colorMode": null,
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "/.*/",
              "thresholds": [],
              "type": "number",
              "unit": "short"
            }
          ],
          "targets": [
            {
              "expr": "100 - (node_filesystem_free_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"} / node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"} * 100)",
              "format": "time_series",
              "instant": true,
              "intervalFactor": 2,
              "legendFormat": "{{mountpoint}}",
              "refId": "A",
              "step": 40
            }
          ],
          "timeFrom": "7d",
          "timeShift": null,
          "title": "Filesystem Utilisation 10.0.0.10:9100",
          "transform": "timeseries_aggregations",
          "type": "table"
        },
        {
          "alert": {
            "conditions": [
              {
                "evaluator": {
                  "params": [
                    90
                  ],
                  "type": "gt"
                },
                "operator": {
                  "type": "and"
                },
                "query": {
                  "params": [
                    "A",
                    "10m",
                    "now"
                  ]
                },
                "reducer": {
                  "params": [],
                  "type": "avg"
                },
                "type": "query"
              }
            ],
            "executionErrorState": "alerting",
            "frequency": "60s",
            "handler": 1,
            "name": "Disk % Used on 10.0.0.10 alert",
            "noDataState": "keep_state",
            "notifications": []
          },
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Prometheus",
          "fill": 1,
          "gridPos": {
            "h": 8,
            "w": 9,
            "x": 15,
            "y": 15
          },
          "id": 50,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": true,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "100 - ((node_filesystem_avail_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"} * 100) / node_filesystem_size_bytes{instance=~\"10.0.0.10:9100\",fstype!=\"tmpfs\",fstype!=\"iso9660\",fstype!=\"nfs4\",fstype!=\"nfs\",fstype!=\"rpc_pipefs\",fstype!=\"rootfs\",fstype!=\"fuse.glusterfs\"})",
              "format": "time_series",
              "instant": false,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{mountpoint}}",
              "refId": "A"
            }
          ],
          "thresholds": [
            {
              "colorMode": "critical",
              "fill": true,
              "line": true,
              "op": "gt",
              "value": 90
            }
          ],
          "timeFrom": "7d",
          "timeShift": null,
          "title": "Disk % Used on 10.0.0.10:9100",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        }
      ],
      "refresh": "10s",
      "schemaVersion": 16,
      "style": "dark",
      "tags": [
        "RedHat",
        "NCL"
      ],
      "templating": {
        "list": [
          {
            "allValue": null,
            "current": {
              "text": "testVM1:9100",
              "value": "testVM1:9100"
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": "Host",
            "multi": false,
            "name": "server",
            "options": [],
            "query": "query_result(node_boot_time_seconds{instance=~\"rpt(ncl|ltc)+......:9100\",job=~\"\"})",
            "refresh": 1,
            "regex": "/instance=\"(.*?)\"/",
            "sort": 1,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": null,
            "current": {
              "selected": true,
              "text": "uc",
              "value": "uc"
            },
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "projName",
            "options": [
              {
                "selected": true,
                "text": "uc",
                "value": "uc"
              },
              {
                "selected": false,
                "text": "cl",
                "value": "cl"
              },
              {
                "selected": false,
                "text": "devarch",
                "value": "devarch"
              }
            ],
            "query": "uc,cl,devarch",
            "type": "custom"
          },
          {
            "allValue": null,
            "current": {
              "text": "51",
              "value": "51"
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "envName",
            "options": [],
            "query": "query_result(node_boot_time_seconds{job=~\"\"})",
            "refresh": 1,
            "regex": "/([0-9]+)..:/",
            "sort": 0,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": null,
            "current": {
              "text": "John Walton",
              "value": "John Walton"
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "ownerName",
            "options": [
              {
                "selected": true,
                "text": "Govind Pandurangan",
                "value": "Govind Pandurangan"
              }
            ],
            "query": "query_result(node_boot_time_seconds{job=~\"\", envname=~\"\"})",
            "refresh": 0,
            "regex": "/ownerName=\"(.*?)\"/",
            "sort": 0,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": null,
            "current": {
              "text": "john.t.walton@accenture.com",
              "value": "john.t.walton@accenture.com"
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "ownerContact",
            "options": [],
            "query": "query_result(node_boot_time_seconds{job=~\"\", envname=~\"\"})",
            "refresh": 1,
            "regex": "/ownerContact=\"(.*?)\"/",
            "sort": 0,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": null,
            "current": {
              "text": "12.3",
              "value": "12.3"
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "allocRelease",
            "options": [],
            "query": "query_result(node_boot_time_seconds{job=~\"\", envname=~\"\"})",
            "refresh": 1,
            "regex": "/allocRelease=\"(.*?)\"/",
            "sort": 0,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": null,
            "current": {
              "isNone": true,
              "text": "None",
              "value": ""
            },
            "datasource": "Prometheus",
            "hide": 2,
            "includeAll": false,
            "label": null,
            "multi": false,
            "name": "allocDates",
            "options": [],
            "query": "query_result(node_boot_time{job=~\"\", envname=~\"\"})",
            "refresh": 1,
            "regex": "/allocDates=\"(.*?)\"/",
            "sort": 0,
            "tagValuesQuery": "",
            "tags": [],
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          }
        ]
      },
      "time": {
        "from": "now-3h",
        "to": "now"
      },
      "timepicker": {
        "refresh_intervals": [
          "5s",
          "10s",
          "30s",
          "1m",
          "5m",
          "15m",
          "30m",
          "1h",
          "2h",
          "1d"
        ],
        "time_options": [
          "5m",
          "15m",
          "1h",
          "6h",
          "12h",
          "24h",
          "2d",
          "7d",
          "30d"
        ]
      },
      "timezone": "browser",
      "title": "DevopsShowcaseVM",
      "uid": "DevopsShowcaseVM",
      "version": 1
}
EOF


cat <<EOF > /var/lib/grafana/dashboards/alertsDashboard.json
{
    "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": false,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "dashboardFilter": "",
      "dashboardTags": [],
      "folderId": null,
      "gridPos": {
        "h": 25,
        "w": 8,
        "x": 0,
        "y": 0
      },
      "id": 6,
      "limit": "100",
      "links": [],
      "nameFilter": "",
      "onlyAlertsOnDashboard": false,
      "show": "current",
      "sortOrder": 1,
      "stateFilter": [
        "alerting",
        "no_data"
      ],
      "title": "Alerts",
      "transparent": false,
      "type": "alertlist"
    },
    {
      "dashboardFilter": "",
      "folderId": null,
      "gridPos": {
        "h": 25,
        "w": 8,
        "x": 8,
        "y": 0
      },
      "height": "1000",
      "id": 3,
      "limit": "50",
      "links": [],
      "nameFilter": "",
      "onlyAlertsOnDashboard": false,
      "show": "current",
      "sortOrder": 3,
      "stateFilter": [],
      "title": "Current status of all nodes",
      "type": "alertlist"
    },
    {
      "folderId": 0,
      "gridPos": {
        "h": 25,
        "w": 8,
        "x": 16,
        "y": 0
      },
      "headings": true,
      "id": 4,
      "limit": 15,
      "links": [],
      "query": "",
      "recent": true,
      "search": false,
      "starred": true,
      "tags": [],
      "title": "Dashboards",
      "type": "dashlist"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 16,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Alerts Dashboard",
  "uid": "DevopsShowcaseVMAlerts",
  "version": 1
}
EOF

sudo sed -i 's/;provisioning/provisioning/g' /etc/grafana/grafana.ini


sudo service grafana-server restart

sudo service grafana-server status


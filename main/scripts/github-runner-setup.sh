#!/bin/bash

# Update and install necessary packages
sudo apt-get update -y
sudo apt-get install -y curl jq unzip nodejs

# Variables from Terraform
GITHUB_TOKEN="${github_token}"
RUNNER_LABEL="${runner_label}"
REPO_URL="${repo_url}"
RUNNER_VERSION="2.311.0"

# Create a runner directory in the ubuntu user's home and navigate into it
mkdir -p /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner

# Download the latest runner package
curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# Set the correct ownership
sudo chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

# Switch to the ubuntu user to configure the runner
sudo -u ubuntu bash << EOF
# Configure the runner
./config.sh --url "$REPO_URL" --token "$GITHUB_TOKEN" --labels "$RUNNER_LABEL" --unattended --replace
EOF

# Create a systemd service file
cat << EOF | sudo tee /etc/systemd/system/actions-runner.service
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
ExecStart=/home/ubuntu/actions-runner/run.sh
User=ubuntu
WorkingDirectory=/home/ubuntu/actions-runner
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable actions-runner.service
sudo systemctl start actions-runner.service

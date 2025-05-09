#!/bin/bash
set -xe

# Prereqs
sudo apt update -y
sudo apt install -y openjdk-21-jre curl wget unzip

# Jenkins connection config
JENKINS_URL="${jenkins_url}"
SLAVE_NAME="${slave_name}"   # Passed from Terraform
JENKINS_USER="admin"
JENKINS_PASS="admin"
WORKDIR="/home/ubuntu/jenkins-agent"
MAX_RETRIES=30

# Wait for Jenkins master to be ready
count=0
until curl -sL "$JENKINS_URL/login" > /dev/null; do
  echo "Waiting for Jenkins to be ready..."
  sleep 10
  count=$((count+1))
  [ "$count" -ge "$MAX_RETRIES" ] && echo "Jenkins not ready after $MAX_RETRIES tries." && exit 1
done

# Wait for this specific slave to be defined in Jenkins
count=0
until curl -s -u "$JENKINS_USER:$JENKINS_PASS" \
    "$JENKINS_URL/computer/$SLAVE_NAME/api/json" \
    | grep -q "\"displayName\":\"$SLAVE_NAME\""; do
  echo "Waiting for $SLAVE_NAME to appear..."
  sleep 10
  count=$((count+1))
  [ "$count" -ge "$MAX_RETRIES" ] && echo "$SLAVE_NAME not registered in Jenkins after $MAX_RETRIES tries." && exit 1
done

# Prepare work directory
mkdir -p "$WORKDIR"
chown ubuntu:ubuntu "$WORKDIR"
cd /home/ubuntu

# Download Jenkins agent
wget -q "$JENKINS_URL/jnlpJars/agent.jar" -O agent.jar
[ ! -f agent.jar ] && echo "agent.jar download failed." && exit 1
chmod 755 agent.jar

# Extract the secret (authentication token)
SECRET=$(curl -sL -u "$JENKINS_USER:$JENKINS_PASS" \
  "$JENKINS_URL/computer/$SLAVE_NAME/slave-agent.jnlp" \
  | grep -oP '(?<=<argument>)[^<]+(?=</argument>)')

# Start the Jenkins agent and redirect output
nohup java -jar agent.jar \
  -jnlpUrl "$JENKINS_URL/computer/$SLAVE_NAME/slave-agent.jnlp" \
  -secret "$SECRET" \
  -workDir "$WORKDIR" \
  > /var/log/jenkins-agent.log 2>&1 &

chmod 644 /var/log/jenkins-agent.log

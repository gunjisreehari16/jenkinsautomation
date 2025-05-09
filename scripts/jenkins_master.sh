#!/bin/bash
set -xe

# Ensure Jenkins user exists
id -u jenkins &>/dev/null || sudo useradd -m -s /bin/bash jenkins

# Update & install dependencies
sudo apt update -y
sudo apt install -y wget unzip git curl fontconfig openjdk-21-jre gnupg2 xmlstarlet python3-pip netcat-openbsd

# Add Jenkins repo
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# Disable setup wizard (JVM argument)
echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' | sudo tee /etc/default/jenkins

# Stop Jenkins before config
sudo systemctl disable jenkins
sudo systemctl stop jenkins

# Init scripts directory
sudo mkdir -p /var/lib/jenkins/init.groovy.d

# Admin user setup
sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy > /dev/null <<'EOF'
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF

# Disable setup wizard via Groovy
sudo tee /var/lib/jenkins/init.groovy.d/disable-setup-wizard.groovy > /dev/null <<'EOF'
import jenkins.model.*
import jenkins.install.*
Jenkins.instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
EOF

# Inject dynamic public IP into Groovy (provided by Terraform)
JENKINS_URL="http://${public_ip}:8080"

# Create slave nodes
sudo tee /var/lib/jenkins/init.groovy.d/create-slave.groovy > /dev/null <<EOF
import jenkins.model.*
import hudson.model.*
import hudson.slaves.*
import hudson.slaves.RetentionStrategy
import hudson.plugins.sshslaves.SSHLauncher

def instance = Jenkins.getInstance()
JenkinsLocationConfiguration.get().setUrl("${JENKINS_URL}")

(1).each { i ->
    def name = "slave-\${i}"
    def home = "/home/jenkins-agent-\${i}"
    def launcher = new JNLPLauncher()
    def node = new DumbSlave(name, home, launcher)
    node.setNumExecutors(1)
    node.setMode(Node.Mode.NORMAL)
    node.setLabelString("slave")
    node.setRetentionStrategy(new RetentionStrategy.Always())
    instance.addNode(node)
}

instance.save()
EOF

# Fix JNLP port
sudo tee /var/lib/jenkins/init.groovy.d/fix-jnlp-port.groovy > /dev/null <<'EOF'
import jenkins.model.Jenkins
Jenkins.instance.setSlaveAgentPort(50000)
Jenkins.instance.save()
EOF

# Set number of master executors and URL
sudo tee /var/lib/jenkins/init.groovy.d/set-executors-and-url.groovy > /dev/null <<EOF
import jenkins.model.*
def instance = Jenkins.getInstance()
instance.setNumExecutors(2)
JenkinsLocationConfiguration.get().setUrl("${JENKINS_URL}")
instance.save()
EOF

# Create install marker files
echo "2.440" | sudo tee /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion
echo "2.440" | sudo tee /var/lib/jenkins/jenkins.install.UpgradeWizard.state

# Fix permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins port
timeout=300
elapsed=0
until nc -z localhost 8080 || [ $elapsed -ge $timeout ]; do
  echo "⏳ Waiting for Jenkins port..."
  sleep 10
  elapsed=$((elapsed + 10))
done

# Wait for Jenkins API to be ready
elapsed=0
until curl -s -u admin:admin http://localhost:8080/api/json | grep -q '"mode"' || [ $elapsed -ge $timeout ]; do
  echo "⌛ Jenkins API not ready yet..."
  sleep 10
  elapsed=$((elapsed + 10))
done

# Download CLI jar
cli_timeout=180
cli_elapsed=0
while [ $cli_elapsed -lt $cli_timeout ]; do
  if curl -sLo /var/lib/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar; then
    break
  fi
  echo "⏳ Waiting for CLI jar to download..."
  sleep 5
  cli_elapsed=$((cli_elapsed + 5))
done

# Download agent.jar (optional)
curl -sLo /var/lib/jenkins/agent.jar http://localhost:8080/jnlpJars/agent.jar

# Link CLI jar
sudo ln -sf /var/lib/jenkins/jenkins-cli.jar /usr/local/bin/jenkins-cli.jar
sudo chown jenkins:jenkins /var/lib/jenkins/jenkins-cli.jar

# Plugin installation with retries
PLUGIN_LIST="git-client git github-api github-oauth github ssh-slaves workflow-aggregator ws-cleanup matrix-auth"
for plugin in $PLUGIN_LIST; do
  echo "🔌 Installing plugin: $plugin"
  retry=0
  until java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin install-plugin "$plugin" -deploy || [ $retry -ge 5 ]; do
    echo "🔁 Retry installing $plugin..."
    sleep 5
    retry=$((retry + 1))
  done
done

# Safe restart Jenkins
echo "♻️ Restarting Jenkins..."
java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin safe-restart

# Wait for Jenkins to come back online
restart_timeout=300
restart_elapsed=0
until nc -z localhost 8080 || [ $restart_elapsed -ge $restart_timeout ]; do
  echo "⏳ Waiting for Jenkins to restart..."
  sleep 10
  restart_elapsed=$((restart_elapsed + 10))
done

echo "✅ Jenkins setup completed successfully!"

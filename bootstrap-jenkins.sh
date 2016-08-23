#!/bin/sh

# Install Jenkins
if ps aux | grep "pjenkins" | grep -v grep 2> /dev/null
then
    echo "Jenkins is already installed. Exiting..."
else
    echo "Installing Jenkins...."
    wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-get -y update
    sudo apt-get install -y openjdk-7-jre-headles
    sudo apt-get install -y default-jdk
    sudo apt-get -y install jenkins
fi

# Fix java.io.StreamCorruptedException
#echo "Editing jenkins config file............."
#sudo sed -i 's/^JAVA_ARGS=[^\n]*/JAVA_ARGS="-Dhudson.diyChunking=false"/' /etc/default/jenkins
#sudo service jenkins restart

# Download jenkins.jar to be able to access Jenkins through a command line tool
echo "Download jenkins-cli.jar..."
wget "http://localhost:8080/jnlpJars/jenkins-cli.jar"

# Turn security off to unlock jenkins
#sudo sed -i 's/<useSecurity>true<\/useSecurity>/<useSecurity>false<\/useSecurity>/' /var/lib/jenkins/config.xml
#sudo perl -i -p0e "s/<authorizationStrategy[\s|\S]*authorizationStrategy>//" /var/lib/jenkins/config.xml
#sudo perl -i -p0e "s/<securityRealm[\s|\S]*securityRealm>//" /var/lib/jenkins/config.xml
#sudo service jenkins restart

#sudo cat /var/lib/jenkins/config.xml


# Install required Jenkins plugins
echo "Installing Jenkins plugin...."
java -jar jenkins.cli.jar -s http://localhost:8080/ install-plugin github
java -jar jenkins.cli.jar -s http://localhost:8080/ install-plugin scp

# Configure Jenkins jobs:
echo "Creating Jenkins jobs....."

# one is for main application (basic ping server)
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job app < jenkins/jobs/app.conf.xml

# the other one is for puppet manifests
java -jar jenkins.cli.jar -s http://localhost:8080/ create-job puppet < jenkins/job/puppet.conf.xml




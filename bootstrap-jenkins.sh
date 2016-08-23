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
    sudo apt-get install -y openjdk-7-jre
    sudo apt-get -y install jenkins
fi

JENKINSVERSION=$(cat /var/lib/jenkins/config.xml | grep version\>.*\<\/version | grep -o [0-9\.]*)
echo $JENKINSVERSION >> /var/lib/jenkins/jenkins.install.UpgradeWizard.state

# Install required Jenkins plugins
echo "Installing Jenkins plugin...."
sudo wget http://mirrors.jenkins-ci.org/plugins/git/latest/git.hpi -P /var/lib/jenkins/plugins/
sudo wget http://mirrors.jenkins-ci.org/plugins/git/latest/scp.hpi -P /var/lib/jenkins/plugins/

# Setting Jenkins config
echo "Setting Jenkins config ..... "
sudo wget -O /var/lib/jenkins/config.xml https://github.com/ozzann/my-vagrant/blob/master/jenkins/config.xml

# Configure Jenkins jobs:
echo "Creating Jenkins jobs....."

# one is for main application (basic ping server)
sudo mkdir -p /var/lib/jenkins/jobs/app
sudo wget -O /var/lib/jenkins/jobs/app/config.xml https://github.com/ozzann/my-vagrant/blob/master/jenkins/jobs/app.config.xml

# the other one is for puppet manifests
sudo mkdir -p /var/lib/jenkins/jobs/puppet
sudo wget -O /var/lib/jenkins/jobs/puppet/config.xml https://github.com/ozzann/my-vagrant/blob/master/jenkins/jobs/puppet.config.xml

sudo /etc/init.d/jenkins restart


#!/bin/bash

restart_jenkins(){
    sudo /etc/init.d/jenkins restart

    while [[ $(curl -s -w "%{http_code}"  http://localhost:8080 -o /dev/null) != "200" ]]; do
       sleep 1
    done
}

# Install git
echo "Installing git .........................................................................."
sudo apt-get -y update
sudo apt-get -y install git

# Install docker
echo "Installing docker ......................................................................."
sudo wget -O install_docker.sh https://raw.github.com/ozzann/my-vagrant/master/install_docker.sh
sudo chmod +x install_docker.sh
sudo ./install_docker.sh

# Download docker mono image in advance
# otherwice it does timeout Jenkins app job's build
echo "Download mono image ....................................................................."
sudo mkdir mono-docker
echo "FROM mono" > mono-docker/Dockerfile
sudo docker build -t mono mono-docker/

# Install Jenkins
if ps aux | grep "jenkins" | grep -v grep 2> /dev/null
then
    echo "Jenkins is already installed. Exiting..."
else
    echo "Installing Jenkins......................................................................"
    wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-get -y update
    sudo apt-get -y install openjdk-7-jre
    sudo apt-get -y install jenkins
fi

# Setting Jenkins config
echo "Setting Jenkins config ..................................................................... "
sudo wget -O /var/lib/jenkins/config.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/config.xml

JENKINSVERSION=$(cat /var/lib/jenkins/config.xml | grep version\>.*\<\/version | grep -o [0-9\.]*)
echo $JENKINSVERSION >> /var/lib/jenkins/jenkins.install.UpgradeWizard.state

restart_jenkins

# Download jenkins command line tool
sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar

sudo sed -i 's/^JAVA_ARGS=.*/JAVA_ARGS="-Dhudson.diyChunking=false"/' /etc/default/jenkins

restart_jenkins

# Install required Jenkins plugins
echo "Installing Jenkins plugins ....................................................................."

echo "Installing Github and SCP plugins and its dependencies ........................................ "
# Download file containing list of required Jenkins plugins
sudo wget -O plugins-list https://raw.github.com/ozzann/my-vagrant/master/plugins-list

while read line           
do
    PLUGINNAME=$line
    sudo wget http://mirrors.jenkins-ci.org/plugins/$PLUGINNAME/latest/$PLUGINNAME.hpi -P /var/lib/jenkins/plugins/
done <plugins-list

sudo wget -O /var/lib/jenkins/be.certipost.hudson.plugin.SCPRepositoryPublisher.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/be.certipost.hudson.plugin.SCPRepositoryPublisher.xml

#echo "Creating credentials .......................................................................... "
#sudo wget -O /var/lib/jenkins/credentials.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/credentials.xml

echo "Setting github plugin configuration ........................................................... "
sudo wget -O /var/lib/jenkins/github-plugin-configuration.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/github-plugin-configuration.xml

# Configure Jenkins jobs:
echo "Creating Jenkins jobs............................................................................"

# one is for puppet manifests
sudo wget -O puppet.config.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/jobs/puppet.config.xml
sudo java -jar jenkins-cli.jar -s http://localhost:8080/ create-job puppet < puppet.config.xml

# the other one is for main application (basic ping server)
sudo wget -O app.config.xml https://raw.github.com/ozzann/my-vagrant/master/jenkins/jobs/app.config.xml
sudo java -jar jenkins-cli.jar -s http://localhost:8080/ create-job app < app.config.xml

# Adding jenkins user to docker group
sudo gpasswd -a jenkins docker
sudo service docker restart

restart_jenkins


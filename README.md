## Vagrant to provision a CI pipeline with Docker, Jenkins and Puppet

This repo contains Vagrantfile and bootstrap shell scripts, and some configs required for all VMs to set up correctly. 

The goal of this Vagrant file is to create a simplified real environment, including Jenkins server for CI and a production server. More detailed, it should put together a pipeline from a GitHub repository through a Jenkins build to deploy an application running in a Docker container, with a redeployment every time a change is checked in that builds and tests correctly. The application deployed at the production is a simple C# network application. It listens on a port and send back "Hello, world!" message.

The Vagrantfile creates three virtual machines. One of them is for Jenkins Server. Also because the production should be managed by Puppet, there are also Puppet Master VM and Production VM is a Puppet Agent at the same time. All of the machines are Ubuntu Desktop 14.04 based development boxes.


## Prerequisites

In order to provision this system one has to have only [Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed.


## Usage


After cloning this directory to set up the environment run a command:
      
      vagrant up


Then after all VMs had successfully set up, one should build Jenkins 'app' job and after that synchronize Puppet master and Puppet Client manually by running these commands:

  - run puppet agent at production.puppet.node.vm
    
    	sudo puppet agent -t

  - at puppet.master.vm to reassure there is a certificate for 'production.puppet.node.vm'
    
    	sudo puppet cert list --all     

  - sign all certificates at puppet.master including just created certificate from 'production.puppet.node.vm'
  
    	sudo puppet cert sign --all
        
  - run agent to apply puppet manifests at 'production.puppet.node.vm'
  
    	sudo puppet agent -t


As a result three virtual machines: **jenkins.server.vm, puppet.master.vm, production.puppet.node.vm** should be running.

In order to check if everything is set up correct call curl command at 'production.puppet.node':

    curl localhost:9000

or ping a server from any other VM using its IP address:

    curl 192.168.56.106:9000
    
    
    
    
## What's inside and how it works

### GitHub repositories
   
   There are three GitHub repos taking part in the whole process.
   
   First and foremost is [C# Ping server app](https://github.com/ozzann/basic-ping-server). It containes C# source code, some tests which will be run on Jenkins and a Docker file.
   The good test for the app like this is just call a curl command checking a response from a server. So, the tests are bash scripts which run a Docker container and then curl the server.
   
   Puppet manifests have a special [repository](https://github.com/ozzann/my-puppet). A configuration of production puppet node is described by a puppet module called **production**. Also the puppet repo containes main manifest with description of all nodes. In our case there is just one node for production.

   The third part in the process is this repository containing Vagrant file and some scripts, and configuration files. 
   

### Docker
   
   Docker is the open platform to build, ship and run applications, anywhere. Any application wrapped into a Docker container can be run on any environment because it’d contain all essential things: code, system tools, system libraries, runtime. It makes Docker very powerful tool for Continuous Deployment.
   
   Docker file used in this project makes C# app runnable on any environment. In order to do this Docker file pulls Mono docker image and .. that's all :) Also it exposes 9000 port, because the app is using it. So, the Docker file is very simple:
   
   		FROM mono
		ADD . /usr/src/app
      	WORKDIR /usr/src/app
      	RUN mcs SimplePingServer/Program.cs

      	EXPOSE 9000
      	CMD [ "mono", "SimplePingServer/Program.exe" ]
    

   
### Jenkins

   Jenkins is a powerful for Continuous Integration. It allows run tests almost immediately after commiting changes. Moreover, Jenkins has just a huge set of different plugins for any purpose you'd like.
   
   In this case Jenkins is bound to GitHub repositories by using just one plugin called **GitHub Plugin.** 
   
   There are two ways to detect commits and then run jobs: polling SCM and set GitHub webhook so after every commit Jenkins build could run immediately. In our case polling SCM is chosen, it's scheduled to poll GitHub repo every 5 minutes:
   
   	H/5 * * * *
   
   There two jobs in Jenkins: app job is for running C# app's test and puppet job is responsible for continuous integration of puppet project. Both of these jobs are bound to corresponding GitHub repositories. Moreover, they're bound between each other.
   
   App job has two post-build actions which run only after stable, or succesfull builds. Firstly other project puppet will be run. It should be mentioned that successfull running of application depends on server's configuration which puppet scripts provide. So without successfull build of puppet project there is no sense to deploy the application to production.
   Then Jenkins copies application files to Puppet master with another Jenkins plugin **Hudson SCP publisher plugin.**
   
   Docker does already provide a useful tool for deploying any application, it does already contain everything necessary for deployment, so there is no need to use other tools and therefore it's enough just send a source code and a Dockerfile to production.
   
   So far there are no tests for puppet manifests. But after succesfull build of puppet job Jenkins copies last version of puppet project to Puppet master again by using Jenkins plugin **Hudson SCP publisher plugin.**
   
   
### Puppet

   With Puppet, one can define the state of an IT infrastructure, and Puppet automatically enforces the desired state. Puppet automates every step of the software delivery process, from provisioning of physical and virtual machines to orchestration and reporting; from early-stage code development through testing, production release and updates.
   
   In this case Puppet installs docker to the production, then it copies application's source code inluding Dockerfile to the production and after that it runs deployment script. 
   
   In order to store app's file and then send them to the production, Puppet master has a static mount point **/etc/puppet/files**. Creation of this point is managed by **/etc/puppet/fileserver.conf** configuration file.
   
   
### The pipeline in action
   
   
   

## What Vagrant does

   Firstly Vagrant creates three virtual machines. The information about machines' names, IPs and provisioning scripts is stored in JSON file **nodes.json**.
   All of them are based on Ubuntu 14.04 Desktop OS and have descriptive names. Also, each of them is assigned with specisific IP address, because they need to communicate between each other. This is obviously not enought to build VMs required fot the pipeline, but Vagrant allows us to install any packages and configure a system by provisioners. In this case shell scripts for each of VM are used:

   - **bootstrap-puppet-master.sh**
   
   The script installs puppetmaster to this machine. Beside that it also configure **/etc/hosts** file by adding information about puppet master and puppet agent hosts.
   Also, some puppet modules, such as ntp, docker and vcsrepo, are installed. The docker module is used then in main puppet manifest site.pp.
   Because puppet master sends application's files to puppet agent, a static mount point is configured. It is managed in another puppet config file **/etc/puppet/fileserver.conf** where the file source is set.
   
   
   - **bootstrap-production.sh**
   
   The provision script for Production VM performs three tasks. Firstly, it installs puppet agent. Then it configures /etc/hosts file by adding information about Puppet Master host. Also it makes puppet config /etc/puppet/puppet.conf aware of the Puppet Master by adding server and certname parameters. Now puppet.conf should contain:
   
   	server=puppet.master.vm
    certname=production.puppet.node.vm
    

   - **bootstrap-jenkins.sh**
   
   In the beginning the script installs git and docker packages. Then it pulls Mono docker image because it's quite heavy and while running tests it could result in timeout error. 
   Second step is to install Jenkins. The script uses files from shared folder, particularly Jenkins global config file, config files for each of jobs and plugins list file. In order to create all jobs and install all neccessray plugins, Jenkins command line tool is used, like this:
   
   	sudo java -jar jenkins-cli.jar -s http://localhost:8080/ create-job puppet < puppet.config.xml

    File **jenkins-cli.jar** should be preliminary downloaded from http://localhost:8080

	  sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar

   Installed Jenkins plugins also have specific configuration with information about sCP servers and GitHub repositories described in **be.certipost.hudson.plugin.SCPRepositoryPublisher.xml** and **github-plugin-configuration.xml**
   




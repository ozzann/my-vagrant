## Vagrant to provision a CI pipeline with Docker, Jenkins and Puppet

This repo contains Vagrantfile and bootstrap shell scripts, and some configs required for all VMs to set up correctly. 

The goal of this Vagrant file is to create a simplified real environment, including Jenkins server for CI and a production server. More detailed, it should put together a pipeline from a GitHub repository through a Jenkins build to deploy an application running in a Docker container, with a redeployment every time a change is checked in that builds and tests correctly. The application deployed at the production is a simple C# network application. It listens on a port and sends back "Hello, world!" message.

The Vagrantfile creates three virtual machines. One of them is for Jenkins Server, the second one is for Production. Because the production should be managed by Puppet, there is also Puppet Master VM and Production VM is a Puppet Agent at the same time. All of the machines are Ubuntu Desktop 14.04 based development boxes.


## Prerequisites

In order to provision this system you only have to have [Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed.


## Usage


After cloning this directory, to set up the environment run a command:
      
      vagrant up


Then after all VMs had successfully set up, you have to build Jenkins 'app' job and after that synchronize Puppet master and Puppet Client manually by running these commands:

  - run puppet agent at **production.puppet.node.vm**
    
    	sudo puppet agent -t

  - at **puppet.master.vm** to reassure there is a certificate for **production.puppet.node.vm**
    
    	sudo puppet cert list --all     

  - sign all certificates at **puppet.master** including just created certificate from **production.puppet.node.vm**
  
    	sudo puppet cert sign --all
        
  - run agent to apply puppet manifests at **production.puppet.node.vm**
  
    	sudo puppet agent -t


As a result three virtual machines: **jenkins.server.vm, puppet.master.vm, production.puppet.node.vm** should be running.

In order to check if everything is set up correctly call curl command at **production.puppet.node**:

    curl localhost:9000

or ping a server from any other VM using production VM's IP address:

    curl 192.168.56.106:9000
    
    
    
 
    
## What's inside and how it works

### GitHub repositories
   
   There are three GitHub repos taking part in the pipeline.
   
   First and foremost is [C# Ping server app](https://github.com/ozzann/basic-ping-server). It contains C# source code and some tests which should be run at Jenkins, and a Docker file.
   The good test for the app is just call a curl command to check a response from a server. So, the tests are bash scripts which run a Docker container and then curl the server.
   
   Puppet manifests have a separate [repository](https://github.com/ozzann/my-puppet). A configuration of the production VM is described in a puppet module called **production**. Also the puppet repo contains main manifest with description of all nodes. In our case there are just one node for production and one node is default:
   	
    	node default {
        }

        node 'production.puppet.node.vm' {
            include production
        }


   The third part in the process is this repository containing Vagrant file and provisioning scripts, and configuration files. 
   

### Docker
   
   Docker is the open platform to build, ship and run applications, anywhere. Any application wrapped into a Docker container can be run on any environment because it’d contain all essential things: code, system tools, system libraries, runtime. It makes Docker very powerful tool for Continuous Deployment.
   
   Docker file used in this project makes C# app runnable on any environment. In order to do this Docker file pulls Mono docker image and runs the app. That's it :) Also it exposes 9000 port, because the app uses it. So, the Docker file is very simple:
   
   		FROM mono
		ADD . /usr/src/app
      	WORKDIR /usr/src/app
      	RUN mcs SimplePingServer/Program.cs

      	EXPOSE 9000
      	CMD [ "mono", "SimplePingServer/Program.exe" ]
    

   
### Jenkins

   Jenkins is a powerful tool for Continuous Integration. It allows you run tests almost immediately after commiting changes. Moreover, Jenkins has just a huge set of different plugins for any purpose.
   
   In this case Jenkins is bound to GitHub repositories by using just one plugin called **GitHub Plugin.** 
   
   There are two ways to detect commits and then run builds: polling SCM or set GitHub webhook so after every commit Jenkins build could run immediately. In our case polling SCM is chosen, it's scheduled to poll the GitHub repo every 5 minutes:
   
   	H/5 * * * *
   
   There are two jobs in Jenkins: 'app' job is for running C# app's test and puppet job is responsible for continuous integration of the 'puppet' project. Both of these jobs are bound to corresponding GitHub repositories. 
   
   'App' job has two post-build actions which run only after stable builds. The first action is to build 'puppet' job. It is necessary because successfull running of the application depends on server's configuration which puppet manifests provide. So without stable build of 'puppet' project there is no sense to deploy the application to production.
   Then Jenkins copies application files to Puppet master via SCP by using another Jenkins plugin **Hudson SCP publisher plugin.**
   
   Docker does already provide a useful tool for deploying any application, everything necessary for deployment is already embedded in a docker container, so there is no need to use other tools and therefore it's enough just send a source code and a Dockerfile to production.
   
   So far there are no tests for puppet manifests, so every 'puppet' build is stable. After that Jenkins copies last version of puppet project to the Puppet master by using Jenkins plugin **Hudson SCP publisher plugin.**
   
   
### Puppet

   With Puppet, you can define the state of an IT infrastructure, and Puppet automatically enforces the desired state. Puppet automates every step of the software delivery process, from provisioning of physical and virtual machines to orchestration and reporting; from early-stage code development through testing, production release and updates.
   
   In this case Puppet installs docker to the production, then it copies the application's source code inluding Dockerfile to the production and after that it runs a deployment script. 
   
   In order to store app's file and then send them to the production, Puppet master has a static mount point **/etc/puppet/files**. Creation of this point is managed by **/etc/puppet/fileserver.conf** configuration file.
   
   
### The pipeline in action
   
  1. Developer pushes changes to the [GitHub repo](https://github.com/ozzann/basic-ping-server).
  2. Jenkins polls SCM and if it finds any changes it builds 'app' job.
  3. If a build is succsefull, then another 'puppet' job is built and also Jenkins copies application's source code files to the Puppet Master VM by SCP.
  4. If a build for 'puppet' project is stable, then all puppet manifests are copied to Puppet Master VM by SCP as well.
  5. Now all actions required to deploy the app to the Production VM are described in puppet manifests and in order to apply all these changes to the production you have just to sync Puppet Master and Agent by running commands descript in the Usage section.
            
  Now the application is running in a docker container at the Production VM.

   
   
   

## What Vagrant does

   Firstly Vagrant creates three virtual machines. The information about machines' names, IPs and provisioning scripts is stored in JSON file **nodes.json**.
   
   All of them are based on Ubuntu 14.04 Desktop and have descriptive names. Also, each of them is assigned with specific IP address, because they need to communicate between each other. This is obviously not enought to build VMs required fot the pipeline, so Vagrant allows us to install any packages and configure a system by using provisioners. 
   Each of the machines has a different configuration: Jenkins VM has significant differences, whilst puppet VMs just slightly differ from each other. 

   - **puppet.master.vm**
      
   The provisioning script **bootstrap-puppet-master.sh** installs puppetmaster to this machine. Beside that it also configures **/etc/hosts** file by adding information about puppet master and puppet agent hosts.
   Also, some puppet modules, such as ntp, docker and vcsrepo, are installed.
   
   Because puppet master sends application's files to puppet agent, a static mount point is configured. It is managed in another puppet config file **/etc/puppet/fileserver.conf**.
   
   In order not to hardcode Puppet Master's and Puppet Agent's IPs, the description of the Puppet Master in **nodes.json** contains a reference to Puppet Agent.
   
   
   - **production.puppet.node.vm**
   
   The provisioning script **bootstrap-production.sh** for Production VM performs three tasks. Firstly, it installs puppet agent. Then it configures **/etc/hosts** file by adding information about Puppet Master host. Also it makes puppet config **/etc/puppet/puppet.conf** aware of the Puppet Master by adding server and certname parameters. 
   After that **/etc/puppet/puppet.conf** should contain:
   
   		server=puppet.master.vm
    	certname=production.puppet.node.vm
        
   In order not to hardcode Puppet Master's and Puppet Agent's IPs, the description of the Production puppet node in **nodes.json** contains a reference to Puppet Master.
    

   - **jenkins.server.vm**
   
   Jenkins VM uses not only shell, but also docker and file provisioning. Vagrant automatically installs Docker and pulls required Mono image:
   
   		nodeconfig.vm.provision "docker", images: ["mono"]
   
   Jenkins VM has **bootstrap-jenkins.sh** provisioning script.
   Firstly, this script installs git. Second step is to install Jenkins. The script uses files from shared folder, particularly Jenkins global config file, config files for each of the jobs and the file containing list of all required plugins and its dependencies. In order to create all jobs and install all neccessray plugins, Jenkins command line tool is used, like this:
   
   		sudo java -jar jenkins-cli.jar -s http://localhost:8080/ create-job puppet < puppet.config.xml

     But before creating Jenkins jobs, file **jenkins-cli.jar** should be preliminary downloaded from **http://localhost:8080**

	  	sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar
        
    Essential Jenkins plugins (Git and SCP) and its dependencies are installing by downloading corresponding files from [Jenkins plugins repository](https://updates.jenkins-ci.org/latest):
    
    	curl -L --silent --output ${plugin_dir}/${1}.hpi  https://updates.jenkins-ci.org/latest/${1}.hpi

   Installed Jenkins plugins also have specific configuration with information about SCP servers and GitHub repositories described in **be.certipost.hudson.plugin.SCPRepositoryPublisher.xml** and **github-plugin-configuration.xml**

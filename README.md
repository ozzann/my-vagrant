## Vagrant to provision a CI pipeline with Docker, Jenkins and Puppet

This repo contains Vagrantfile and bootstrap shell scripts, and some configs required for all VMs to set up correctly. 

The goal of this Vagrant file is to create a simplified real environment, including Jenkins server for CI and a production server. More detailed, it should put together a pipeline from a GitHub repository through a Jenkins build to deploy an application running in a Docker container, with a redeployment every time a change is checked in that builds and tests correctly. The application deployed at the production is a simple C# network application. It listens on a port and send back "Hello, world!" message.

The Vagrantfile creates three virtual machines. One of them is for Jenkins Server. Also because the production should be managed by Puppet, there are also Puppet Master VM and Production VM is a Puppet Agent at the same time. All of the machines are Ubuntu Desktop 14.04 based development boxes.

This project contains Vagrant file which creates an environment
and some shell scripts and required configuration files.

## Prerequisites

In order to provision this system one has to have only Vagrant and VirtualBox installed.

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
    
    
## What's inside

### GitHub repositories
   
   There are three GitHub repos take part in the whole process.
   
   First and foremost is [C# Ping server app](https://github.com/ozzann/basic-ping-server). It containes C# source code, some tests which will be run on Jenkins and a Docker file.
   The good test for the app like this is just call a curl command checking a response from a server. So, the tests are bash scripts which run a Docker container and then curl the server.
   
   Puppet manifests have a special [repository](https://github.com/ozzann/my-puppet). A configuration of production puppet node is described by a puppet module called **production**. Also the puppet repo containes main manifest with description of all nodes. In our case there is just one node for production.

   The third part in the process is this repository containing Vagrant file and some scripts, and configuration files. 
   

### Docker
   
   Docker is the open platform to build, ship and run applications, anywhere. Any application wrapped into a Docker container can be run on any environment because it’d contain all essential things: code, system tools, system libraries, runtime. It makes Docker very powerful tool for Continuous Deployment.
   

   
### Jenkins
   
   
### Puppet






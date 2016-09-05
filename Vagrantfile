nodes = (JSON.parse(File.read("nodes.json")))['nodes']

Vagrant.configure("2") do |config|
    config.vm.box = "box-cutter/ubuntu1404-desktop"

    nodes.each do |node|
        node_name   = node[0]
        node_config = node[1]

        config.vm.define node_name do |nodeconfig|
            nodeconfig.vm.hostname = node_name

            nodeconfig.vm.network :private_network, ip: node_config[':ip']
            
            if node_name == 'jenkins.server.vm'
                nodeconfig.vm.network :forwarded_port, guest: 8080, host: 1234
				
	        nodeconfig.vm.provision "docker", images: ["mono"]

                # Sync folder containing config and scripts to Jenkins VM
                nodeconfig.vm.synced_folder "shared/", "/vagrant"
            end

            nodeconfig.vm.provider :virtualbox do |vb|
                vb.name = node_name
                vb.gui = true
                vb.memory = 4096
            end
            
            nodeconfig.vm.provision :shell, :path => node_config[':bootstrap']
        end
    end
end

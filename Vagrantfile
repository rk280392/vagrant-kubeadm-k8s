N=1
M=1
IMAGE="bento/ubuntu-22.04"
IP_NW="192.168.1."
IP_START=50

$infoScript = <<SCRIPT
  echo 'IP-addresses of the vm ...'
  rm -rf /vagrant/file.txt
  for m in $(seq 1 $M); do
    ipaddr=$(ip -br a | grep eth1 | awk '{print $3}'| awk -F '/' '{print $1}')
    echo "`hostname -s` $ipaddr" >> /vagrant/file.txt
  done
  
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: {"IP_NW" => IP_NW, "IP_START" => IP_START}, inline: <<-SHELL
      apt-get update -y
      echo "$IP_NW$((IP_START)) master-1" >> /etc/hosts
      echo "$IP_NW$((IP_START_W)) worker-1" >> /etc/hosts
      echo "$IP_NW$((IP_START_W+1)) worker-2" >> /etc/hosts
  SHELL

  (1..M).each do |i|
    config.vm.define "master-#{i}" do |master|
      master.vm.box = IMAGE
      master.vm.hostname = "master-#{i}"
      master.vm.network "public_network", ip: IP_NW + "#{IP_START}", use_dhcp_assigned_default_route: true, bridge: "enp19s0"
      master.vm.provision "shell", inline: $infoScript,
        run: "always"
      master.vm.provision "shell", path: "scripts/k8s-containerd-master.sh"
      master.vm.provider :virtualbox do |v|
        v.memory = 2000
        v.cpus = 2
      end
    end
  end
  (1..N).each do |i|
     config.vm.define "worker-#{i}" do |worker|
        worker.vm.box = IMAGE
	worker.vm.hostname = "worker-#{i}"
	worker.vm.network "public_network", ip: IP_NW + "#{IP_START + 50}", use_dhcp_assigned_default_route: true, bridge: "enp19s0"
        worker.vm.provision "shell", path: "scripts/k8s-containerd-worker.sh"
        worker.vm.provision "shell", inline: $infoScript,
	   run: "always"
        worker.vm.provider :virtualbox do |v|
          v.memory = 1024
          v.cpus = 1
        end
     end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :

def generate_code(number)
  charset = Array('A'..'Z') + Array('a'..'z') + Array(0..9)
  Array.new(number) { charset.sample }.join
end

VAGRANTFILE_API_VERSION = '2'

# declare the machine config in a hash
HOST_CONFIG = {
  'gitlab_server' => {'box' => 'bento/debian-10', 'memory' => '4096'},
  'front_server' => {'box' => 'bento/debian-10', 'memory' => '1024'},
  'back_server' => {'box' => 'bento/debian-10', 'memory' => '1024'},
  'database_server' => {'box' => 'bento/debian-10', 'memory' => '1024'}
}

# create the vms
N = 3
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  HOST_CONFIG.each_with_index do |(hostname, basebox), index|
    config.vm.define hostname do |hname|
      hname.vm.box = basebox['box']
      hname.vm.network 'private_network', ip: "192.168.0.#{2+index}", netmask: '255.255.255.248'
      hname.vm.provider 'virtualbox' do |v|
        v.name = hostname
        v.memory = basebox['memory']
      end
        if index == N
        config.vm.provision :ansible do |ansible|
          ansible.limit = 'all'
          ansible.inventory_path = './ansible/hosts.yml'
          ansible.extra_vars = {
            "token" => generate_code(10),
            "gitlab_root_password" => ENV['GITLAB_ROOT_PASSWORD'],
          }
          ansible.playbook = 'ansible/playbook.yml'
        end
      end
    end
  end
end
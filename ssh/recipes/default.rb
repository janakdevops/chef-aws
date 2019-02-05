# Cookbook Name:: ssh
# Recipe:: default

include_recipe "s3cmd"
s3cmd_secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
ssh_creds = Chef::EncryptedDataBagItem.load("keys", "ubuntu", s3cmd_secret)
ssh_key = ssh_creds['ssh_key']

template "/home/ubuntu/.ssh/config" do
  source "config.erb"
  owner "ubuntu"
  group "ubuntu"
  mode  "0600"
end

file "/home/ubuntu/.ssh/id_rsa" do
  owner   "ubuntu"
  group   "ubuntu"
  mode    "0400"
  content ssh_key
  notifies  :reload, "service[ssh]"
end

service "ssh" do
  supports :start => true, :stop => true, :status => true, :restart => true, :reload => true
  action :enable
end


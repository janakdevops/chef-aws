# Cookbook Name:: s3cmd
# Recipe:: default

aws_secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
aws_creds = Chef::EncryptedDataBagItem.load("bot", node.chef_environment + "_bot", aws_secret)
s3cfg_passphrase = Chef::EncryptedDataBagItem.load("passwords", "passphrase", aws_secret)
passphrase = s3cfg_passphrase['passphrase']
access_key = aws_creds['access_key']
secret_key = aws_creds['secret_key']

package "s3cmd"
package "unzip"

execute "install_aws_cli" do
  user "ubuntu"
  group "ubuntu"
  cwd "/home/ubuntu"
  command <<-EOH
  wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip ; unzip -o awscli-bundle.zip ; sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  mkdir ~/.aws
  echo "[default]\noutput = table\nregion = us-east-1" > ~/.aws/config
  echo "[default]\naws_access_key_id = #{access_key}\naws_secret_access_key = #{secret_key}" > ~/.aws/credentials
  sudo apt-get remove unzip -y
  EOH
  not_if { File.exists?("/home/ubuntu/.aws/credentials") }
end

template "/home/ubuntu/.s3cfg" do
  source "s3cfg.erb"
  owner "ubuntu"
  group "ubuntu"
  mode  "0440"
  variables (
    {
    :key  => access_key,
    :secret => secret_key,
    :passphrase => passphrase
    })
end

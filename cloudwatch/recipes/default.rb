#
# Cookbook Name:: cloudwatch
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
aws_secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")

aws_creds = Chef::EncryptedDataBagItem.load("bot", node.chef_environment + "_bot", aws_secret)
access_key = aws_creds['access_key']
secret_key = aws_creds['secret_key']

bash "download_and_install_require_prerequisites" do
	user "ubuntu"
	cwd "/home/ubuntu"
	code <<-EOH
	sudo apt-get install libdatetime-perl -y
	sudo apt-get update
	sudo apt-get install unzip libwww-perl libdatetime-perl -y
	wget http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip
	unzip CloudWatchMonitoringScripts-1.2.1.zip
	rm -rf CloudWatchMonitoringScripts-1.2.1.zip
	EOH
	not_if { File.exists?("/home/ubuntu/aws-scripts-mon/awscreds.template") }
end

template "/home/ubuntu/aws-scripts-mon/awscreds.template" do
  source "awscreds.template.erb"
  owner  "ubuntu"
  group  "ubuntu"
  mode  "0644"
  variables (
  {
    :access_key => access_key,
    :secret_key => secret_key
  })
end


cron 'setup_cron_to_send_statistics' do
  minute '*/5'
  command '/home/ubuntu/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --aws-credential-file=/home/ubuntu/aws-scripts-mon/awscreds.template'
end

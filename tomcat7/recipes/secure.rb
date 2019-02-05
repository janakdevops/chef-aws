# Cookbook Name:: tomcat7
# Recipe:: tomcat

include_recipe "s3cmd"
include_recipe "jre7"

s3cmd_secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
tomcat_creds = Chef::EncryptedDataBagItem.load("passwords", "tomcat", s3cmd_secret)
tomcat_manager_user = tomcat_creds['tomcat_manager_user']
tomcat_manager_passwd = tomcat_creds['tomcat_manager_passwd']
tomcat_keystore_passwd = tomcat_creds['tomcat_keystore_passwd']

min_perm_size = "%.0f" % "#{node['memory']['total'][0..-3].to_i / 1024 * 0.10 }"
max_perm_size = "%.0f" % "#{node['memory']['total'][0..-3].to_i / 1024 * 0.50 }"
min_app_memory = "%.0f" % "#{node['memory']['total'][0..-3].to_i / 1024 * 0.40 }"
max_app_memory = "%.0f" % "#{node['memory']['total'][0..-3].to_i / 1024 * 0.70 }"

execute "get_apache_tomcat_source_package" do
  user "ubuntu"
  cwd  "/usr/local"
  command "sudo s3cmd get #{node['tomcat7']['s3_ezcac_common_package_path']}/#{node['tomcat7']['s3_apache-tomcat_source_package_dir']}/#{node['tomcat7']['s3_apache-tomcat_source_package']} -c /home/ubuntu/.s3cfg"
  not_if { File.exists?("/usr/local/#{node['tomcat7']['s3_apache-tomcat_source_package']}") }
end

directory "/usr/local/#{node['tomcat7']['tomcat_dirname']}" do
  recursive true
  owner "ubuntu"
  group "ubuntu"
  not_if { File.directory?("/usr/local/#{node['tomcat7']['tomcat_dirname']}") }
end

execute "extract_apache_tomcat_source_package" do
  user "ubuntu"
  group "ubuntu"
  cwd  "/usr/local"
  command "tar xzf #{node['tomcat7']['s3_apache-tomcat_source_package']}  -C #{node['tomcat7']['tomcat_dirname']}/ --strip-components=1"
  not_if { File.exists?("/usr/local/#{node['tomcat7']['tomcat_dirname']}/bin/startup.sh") }
end

bash "remove_docs_and_examples_source_package" do
  user "root"
  cwd  "/usr/local/#{node['tomcat7']['tomcat_dirname']}/webapps"
  code <<-EOH
  rm -rf docs
  rm -rf examples
  EOH
end

cookbook_file "/home/ubuntu/ezdi-cloud-com-keystore.jks" do
  source  "ezdi-cloud-com-keystore.jks"
  owner "ubuntu"
  group "ubuntu"
  mode  "0777"
end

template "/usr/local/#{node['tomcat7']['tomcat_dirname']}/conf/server.xml" do
  source  "server.xml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode  "0600"
  variables (
       {
         :tomcat_keystore_passwd => tomcat_keystore_passwd
       })
end

template "/usr/local/#{node['tomcat7']['tomcat_dirname']}/bin/catalina.sh" do
  source "catalina.sh.erb"
  owner "ubuntu"
  group "ubuntu"
  mode  "0755"
  variables({
        :min_perm_size => min_perm_size,
        :max_perm_size => max_perm_size,
        :min_app_memory => min_app_memory,
        :max_app_memory => max_app_memory
  })
end

template "/usr/local/#{node['tomcat7']['tomcat_dirname']}/conf/tomcat-users.xml" do
  source  "secure-tomcat-users.xml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode  "0600"
  variables (
    {
      :tomcat_manager_user => tomcat_manager_user,
      :tomcat_manager_passwd => tomcat_manager_passwd
    })
end

template "/etc/init.d/tomcat" do
  source  "tomcat.erb"
  owner "root"
  group "root"
  mode  "0777"
end

execute "add_tomcat_service" do
  action :run
  user "root"
  group "root"
  cwd  "/etc/init.d"
  command "update-rc.d tomcat defaults"
end

service "tomcat" do
  action [:enable, :start]
  supports :status => true, :start => true, :stop => true, :restart => true
  subscribes :restart, "template[/etc/init.d/tomcat]", :immediately
end

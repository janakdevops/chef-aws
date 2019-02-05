# Cookbook Name:: jre7
# Recipe:: default

#include_recipe "s3cmd"
#include_recipe "jre7::jvm_monitoring"

## JDK Installation ##

bash "download_and_install_oracle_java_7" do
	user "root"
	cwd "/home/ubuntu"
	code <<-EOH
	add-apt-repository ppa:webupd8team/java -y
	apt-get update
	echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
	apt-get install oracle-java7-installer -y
	find /usr/lib/jvm/java-7-oracle/bin/ ! -name jps ! -name jstat -type f -delete
	EOH
	not_if { File.exists?("/usr/lib/jvm/java-7-oracle/jre/bin/java") }
end

ruby_block  "set-env-java-home" do
  block do
    ENV["JAVA_HOME"] = node['jdk7']['java_home']
  end
  not_if { ENV["JAVA_HOME"] == node['jdk7']['java_home'] }
end

directory "/etc/profile.d" do
  mode 00755
end

file "/etc/profile.d/jdk.sh" do
  content "export JAVA_HOME=#{node['jdk7']['java_home']}"
  mode 00755
end

if node['jdk7']['set_etc_environment']
  ruby_block "Set JAVA_HOME in /etc/environment" do
    block do
      file = Chef::Util::FileEdit.new("/etc/environment")
      file.insert_line_if_no_match(/^JAVA_HOME=/, "JAVA_HOME=#{node['jdk7']['java_home']}")
      file.search_file_replace_line(/^JAVA_HOME=/, "JAVA_HOME=#{node['jdk7']['java_home']}")
      file.write_file
    end
  end
end

include_recipe "sensu::client"

execute "Add Sensu User in Sudo file" do
command <<-EOH
user "root"
group "root"
echo "sensu     ALL = ALL, NOPASSWD: ALL" >> /etc/sudoers
EOH
not_if "grep -ri sensu /etc/sudoers"
end

execute "Add Subscriptions" do
	command <<-EOH
	owner "root"
	group "root"
	echo `sed -i "/subscriptions/ s/ ]/, \\"ezdi_jvm_servers\\" ]/" /etc/sensu/conf.d/sensu_client.json`
	EOH
end

# script files to collect results/ metrics
%w{ java-heap-graphite.sh }.each do |r|
  cookbook_file "/etc/sensu/plugins/#{r}" do
    source  "#{r}"
    owner   "root"
    group   "root"
    mode    "0755"
  end
end

# subscribe client for checks
%w{ jvm_metrics.json }.each do |r|
  cookbook_file "/etc/sensu/conf.d/#{r}" do
    source  "#{r}"
    owner   "root"
    group   "root"
    mode    "0644"
    notifies :restart, "service[sensu-client]"
  end
end
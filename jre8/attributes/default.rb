node.default['jdk8']['s3_common_package_path'] = "s3://ezcac/common"
node.default['jdk8']['s3_jdk_source_package_dir'] = "source"
node.default['jdk8']['s3_jdk_source_package'] = "oracle-java8-installer_7u80_all.deb"
node.default['jdk8']['java_home'] = "/usr/lib/jvm/java-8-oracle/jre"
node.default['jdk8']['sys_path'] = "$JAVA_HOME/bin:$PATH"
node.default['jdk8']['set_etc_environment'] = false

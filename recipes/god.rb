#
# Cookbook Name:: practicingruby
# Recipe:: god
#
# Installs God
#

# Install Ruby first
include_recipe "practicingruby::ruby"

# Install god gem
gem_package "god" do
  gem_binary node["practicingruby"]["ruby"]["gem"]["binary"]
  options    node["practicingruby"]["ruby"]["gem"]["options"]
  action     :install
end

# Add god to default PATH for sudo and startup script
link "/usr/local/bin/god" do
  to        "/opt/rubies/#{node["practicingruby"]["ruby"]["version"]}/bin/god"
  link_type :symbolic
  action    :create
end

# Create config directory
directory "/etc/god" do
  owner  "root"
  group  "root"
  mode   "0755"
  action :create
end

# Create config file
file "/etc/god/master.conf" do
  owner   "root"
  group   "root"
  mode    "0644"
  content "load '/home/deploy/current/config/delayed_job.god'\n"
  action  :create
end

# Install startup script
cookbook_file "/etc/init.d/god" do
  source "god.sh"
  owner  "root"
  group  "root"
  mode   "0755"
  action :create
end

# Start god
service "god" do
  supports :status => true, :restart => true
  action   [:enable, :start]
end

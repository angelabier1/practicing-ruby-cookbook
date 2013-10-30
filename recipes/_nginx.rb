#
# Cookbook Name:: practicingruby
# Recipe:: nginx
#
# Installs and configures Nginx
#

# Override default Nginx attributes
node.set["nginx"]["worker_processes"]     = 4
node.set["nginx"]["worker_connections"]   = 768
node.set["nginx"]["default_site_enabled"] = false

# Install Nginx and set up nginx.conf
include_recipe "nginx::default"

# Create directory to store SSL files
ssl_dir = File.join(node["nginx"]["dir"], "ssl")
directory ssl_dir do
  owner  "root"
  group  "root"
  mode   "0600"
  action :create
end

# Generate SSL private key and certificate for domain name
guard_file = File.join(ssl_dir, node["practicingruby"]["rails"]["host"] + ".crt")
bash "generate-ssl-files" do
  user  "root"
  cwd   ssl_dir
  flags "-e"
  code <<-EOS
    DOMAIN=#{node["practicingruby"]["rails"]["host"]}
    openssl genrsa -out $DOMAIN.key 4096
    openssl req -new -batch -subj "/CN=$DOMAIN" -key $DOMAIN.key -out $DOMAIN.csr
    openssl x509 -req -days 365 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
    rm $DOMAIN.csr
  EOS
  notifies :reload, "service[nginx]"
  not_if { ::File.exists?(guard_file) }
end

# Create practicingruby site config
template "#{node["nginx"]["dir"]}/sites-available/practicingruby" do
  source "practicingruby_nginx.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :create
  variables(
    :domain_name => node["practicingruby"]["rails"]["host"]
  )
end

# Enable practicingruby site
nginx_site "practicingruby" do
  enable true
end

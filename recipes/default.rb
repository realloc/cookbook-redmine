#
# Cookbook Name:: redmine
# Recipe:: default
#

directory node['redmine']['app_path'] do
  action :create
  recursive true
  owner node['redmine']['owner']
  group node['redmine']['group']
end

tar_extract node['redmine']['tarball_url'] do
  target_dir node['redmine']['app_path']
  user node['redmine']['owner']
  group node['redmine']['group']
  tar_flags ['--strip-components=1']
end

service "unicorn_redmine" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
end

template "/etc/init.d/unicorn_redmine" do
  source "unicorn_init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  notifies :restart, 'service[unicorn_redmine]'
end

template "#{node['redmine']['app_path']}/config/configuration.yml" do
  source 'configuration.yml.erb'
  owner node['redmine']['owner']
  group node['redmine']['group']
  mode  '0644'
  notifies :restart, 'service[unicorn_redmine]', :delayed
end

template "#{node['redmine']['app_path']}/config/unicorn.rb" do
  source "unicorn.rb.erb"
  owner node['redmine']['owner']
  group node['redmine']['group']
  mode  '0644'
  notifies :restart, 'service[unicorn_redmine]', :delayed
end

directory "#{node['redmine']['app_path']}/public/plugin_assets" do
  recursive true
  owner node['redmine']['owner']
  group node['redmine']['group']
  mode  "0755"
end

template "#{node['redmine']['app_path']}/config/database.yml" do
  source "database.yml.erb"
  owner node['redmine']['owner']
  group node['redmine']['group']
  mode  "0600"
end

template "#{node['redmine']['app_path']}/Gemfile.local" do
  action :create_if_missing
  source "Gemfile.local.erb"
  owner node['redmine']['owner']
  group node['redmine']['group']
  mode "0744"
end
  
bash "bundle install" do
  code "sudo -i -u #{node['redmine']['owner']} bash -c 'cd #{node['redmine']['app_path']} && bundle install --without test'"
end

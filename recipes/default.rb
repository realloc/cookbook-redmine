#
# Cookbook Name:: redmine
# Recipe:: default
#

directory node['redmine']['app_path'] do
  action :create
  owner 'www-data'
  group 'www-data'
end

tar_extract node['redmine']['tarball_url'] do
  target_dir node['redmine']['app_path']
  user node['redmine']['owner']
  group node['redmine']['group']
end

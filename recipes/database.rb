#
# Cookbook Name:: redmine
# Recipe:: database
#

mysql_root_connection_info = {
  :host => node['redmine']['db']['db_host'],
  :username => node['redmine']['db']['db_root'],
  :password => node['redmine']['db']['db_root_pass']
}

# create a mysql database for redmine
mysql_database node['redmine']['db']['db_name'] do
  connection mysql_root_connection_info
  action :create
end

# create a mysql user for redmine
mysql_database_user node['redmine']['db']['db_user'] do
  action        :create
  password      node['redmine']['db']['db_pass']
  connection    mysql_root_connection_info
end

# grant all privileges on the newly created DB to the redmine user
mysql_database_user node['redmine']['db']['db_user'] do
  action          :grant
  password        node['redmine']['db']['db_pass']
  database_name   node['redmine']['db']['db_name']
  host            node['redmine']['db']['db_host']
  connection      mysql_root_connection_info
end

bash "rake_task:generate_secret_token" do
  code "sudo -i -u #{node['redmine']['rvm_user']} bash -c 'cd #{node['redmine']['app_path']} && rake generate_secret_token'"
end

# expression to check if DB is empty. We assume that if the settings table exists, nonempty.
db_user = node['redmine']['db']['db_user']
db_pass = node['redmine']['db']['db_pass']
db_name = node['redmine']['db']['db_name']
mysql_client_cmd = "mysql -u #{db_user} -p#{db_pass} #{db_name}"
mysql_empty_check_cmd = "echo 'SHOW TABLES' | #{mysql_client_cmd} | wc -l | xargs test 0 -eq"

bash "rake_task: db:migrate and other initialization" do
  code <<-EOH
    sudo -i -u #{node['redmine']['rvm_user']} bash -c 'cd #{node['redmine']['app_path']} && RAILS_ENV=#{node['redmine']['rails_env']} rake db:migrate'
    sudo -i -u #{node['redmine']['rvm_user']} bash -c 'cd #{node['redmine']['app_path']} && RAILS_ENV=#{node['redmine']['rails_env']} rake redmine:plugins:migrate'
    sudo -i -u #{node['redmine']['rvm_user']} bash -c 'cd #{node['redmine']['app_path']} && RAILS_ENV=#{node['redmine']['rails_env']} rake redmine:load_default_data REDMINE_LANG=#{node['redmine']['lang']}'
  EOH
  only_if mysql_empty_check_cmd
end

# Start unicorn (must happen after mysql is setup)
service "unicorn_redmine" do
  action [:enable, :start]
end

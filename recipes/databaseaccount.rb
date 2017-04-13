#
# Cookbook Name:: windowsservicebus
# Recipe:: default
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

if node['windowsservicebus']['database']['account'] == ""
    raise "Please configure Windows Service Bus database account attribute is configured"
end

sql_server_connection_info = {
  :host     => node['windowsservicebus']['database']['host'],
  :port     => node['windowsservicebus']['database']['port'],
  :username => node['windowsservicebus']['database']['username'],
  :password => node['windowsservicebus']['database']['password']
}

# database cookbook made it sql_server cookbook problem. sql_server cookbook as made it the callers problem now
# Need to limit to 1.0.5 to work in ChefDK https://github.com/rails-sqlserver/tiny_tds/issues/354
chef_gem 'tiny_tds' do
    action :install
    version '1.0.5'
    options '--no-user-install'
end

sql_server_database_user node['windowsservicebus']['database']['account'] do
  connection sql_server_connection_info
  sql_sys_roles node['windowsservicebus']['database']['sys_roles']
  windows_user node['windowsservicebus']['database']['windows_user']
  action :create
end
#
# Cookbook Name:: windowsservicebus
# Recipe:: default
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'sql_server::server'

if node['windowsservicebus']['service']['account'] == ""
    raise "Please configure Windows Service Bus service_account attribute is configured"
end

sql_server_connection_info = {
  :host     => node['windowsservicebus']['database']['host'],
  :port     => node['windowsservicebus']['database']['port'],
  :username => node['windowsservicebus']['database']['username'],
  :password => node['windowsservicebus']['database']['password']
}

sql_server_database_user node['windowsservicebus']['service']['account'] do
  connection sql_server_connection_info
  sql_roles node['windowsservicebus']['database']['roles']
  windows_user true
  action :create
end
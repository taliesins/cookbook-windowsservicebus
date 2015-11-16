#
# Cookbook Name:: windowsservicebus
# Recipe:: default
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

if node['windowsservicebus']['service']['account'] == ""
    raise "Please configure Windows Service Bus service_account attribute is configured"
end

sql_server_connection_info = {
  :host     => node['windowsservicebus']['database']['host'],
  :port     => node['windowsservicebus']['database']['port'],
  :username => node['windowsservicebus']['database']['username'],
  :password => node['windowsservicebus']['database']['password']
}

username = node['windowsservicebus']['service']['account']
domain = ""

if username.include? '\\'
	domain = username.split('\\')[0]
	username = username.split('\\')[1]
end

if username.include? '@'
	domain = username.split('@')[1]
	username = username.split('@')[0]
end

if domain == ""  || domain == "."
	domain = node["hostname"]
end

sql_server_database_user domain + '\\' + username do
  connection sql_server_connection_info
  sql_sys_roles node['windowsservicebus']['database']['sys_roles']
  windows_user true
  action :create
end
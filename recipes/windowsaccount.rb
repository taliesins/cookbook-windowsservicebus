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

if node['windowsservicebus']['service']['password'] == ""
    raise "Please configure Windows Service Bus service_account_password attribute is configured"
end

user node['windowsservicebus']['service']['account']  do
	action :create
	password node['windowsservicebus']['service']['password']
end

group node['windowsservicebus']['service']['group'] do
	action :modify
	members node['windowsservicebus']['service']['account']
	append true
end
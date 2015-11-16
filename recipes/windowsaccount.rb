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

user domain + '\\' + username do
	action :create
	password node['windowsservicebus']['service']['password']
	only_if { domain == node["hostname"] }
end

group node['windowsservicebus']['service']['group'] do
	action :modify
	members domain + '\\' + username
	append true
end
#
# Cookbook Name:: windowsservicebus
# Recipe:: node
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

include_recipe "webpi::install-msi"

registry_key 'Use relative directory for Local AppData' do
    key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => "%~dp0appdata"
        }]
        action :create
end

webpi_product 'ServiceBus_1_1,ServiceBus_1_1_CU1' do
    accept_eula true
    action :install
end

windows_package 'Update for Service Bus 1.1 (KB3086798)GDR' do
	installer_type :custom
	options '/f /q /z'
	source node['windowsservicebus']['installer']['ServiceBus_1_1_NETFramework46_Update']
end

registry_key 'Use profile\AppData\Local for Local AppData' do
    key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => '%USERPROFILE%\AppData\Local'
        }]
end
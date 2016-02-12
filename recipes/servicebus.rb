#
# Cookbook Name:: windowsservicebus
# Recipe:: node
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

include_recipe "webpi::install-msi"

registry_key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' do
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => "%~dp0appdata"
        }]
        action :create
end

webpi_product 'ServiceBus_1_1' do
    accept_eula true
    action :install
end

webpi_product 'ServiceBus_1_1_CU1' do
    accept_eula true
    action :install
end

windows_package 'Update for Service Bus 1.1 (KB3086798)GDR' do
    checksum node['windowsservicebus']['KB3086798']['checksum']
    options '/quiet /w /norestart'
    source node['windowsservicebus']['KB3086798']['url']
    action :install
    installer_type :custom
end

registry_key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' do
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => '%%USERPROFILE%%\AppData\Local'
        }]
end
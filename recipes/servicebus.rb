#
# Cookbook Name:: windowsservicebus
# Recipe:: node
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

registry_key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' do
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => "%~dp0appdata"
        }]
        action :create
end

#webpi_product 'ServiceBus_1_1' do
#    accept_eula true
#    action :install
#end

webpi_product 'ServiceBus_1_1_CU1' do
    accept_eula true
    action :install
end

registry_key 'HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' do
    values [{
        :name => "Local AppData",
        :type => :expand_string,
        :data => '%%USERPROFILE%%\AppData\Local'
        }]
end
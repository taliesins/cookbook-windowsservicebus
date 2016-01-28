#
# Author:: Taliesin Sisson (<taliesins@yahoo.com>)
# Cookbook Name:: windowsservicebus
# Attributes:: default
# Copyright 2014-2015, Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



default['windowsservicebus']['service']['account'] = '.\ServiceBus' # e.g. ServiceBus. This account is used to access the database server, so ensure that database permission have been configured. This account is used to run service, so ensure that it has the correct permissions on each node. If using multiple nodes, active directory is required.
default['windowsservicebus']['service']['password'] = 'P@ssw0rd' # e.g. P@ssw0rd. This is the password to use if creating a windows account locally to use.
default['windowsservicebus']['service']['group'] = 'Administrators'

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

default['windowsservicebus']['service']['enablefirewalls'] = true

default['windowsservicebus']['database']['sys_roles'] = {:sysadmin => :ADD}
default['windowsservicebus']['database']['host'] = '127.0.0.1'
default['windowsservicebus']['database']['port'] = node['sql_server']['port']
default['windowsservicebus']['database']['username'] = nil
default['windowsservicebus']['database']['password'] = nil

default['windowsservicebus']['database']['windows_user'] = true
default['windowsservicebus']['database']['account'] = "#{domain}\\#{username}"

default['windowsservicebus']['instance']['FarmDns'] = node['fqdn']  # e.g. servicebus.localtest.me
default['windowsservicebus']['instance']['FarmCertificateThumbprint'] = '' # if windowsservicebus::certificate is called it will populate this field e.g. wildcard certificate *.localtest.me thumbprint 
default['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] = '' # if windowsservicebus::certificate is called it will populate this field e.g. wildcard certificate *.localtest.me thumbprint

default['windowsservicebus']['certificate']['CaCertificate']['common_name'] = node['windowsservicebus']['instance']['FarmDns'] + '.ca'
default['windowsservicebus']['certificate']['CaCertificate']['key_source'] = 'self-signed'
default['windowsservicebus']['certificate']['CaCertificate']['pkcs12_path'] = File.join(Chef::Config[:file_cache_path], node['windowsservicebus']['certificate']['CaCertificate']['common_name'] + '.pfx')
default['windowsservicebus']['certificate']['CaCertificate']['pkcs12_passphrase'] = nil
default['windowsservicebus']['certificate']['CaCertificate']['private_key_acl'] = ["#{domain}\\#{username}", "#{domain}\\vagrant"]
default['windowsservicebus']['certificate']['CaCertificate']['store_name'] = "ROOT"
default['windowsservicebus']['certificate']['CaCertificate']['user_store'] = false
default['windowsservicebus']['certificate']['CaCertificate']['cert_path'] = File.join(Chef::Config[:file_cache_path], node['windowsservicebus']['certificate']['CaCertificate']['common_name'] + '.pem')
default['windowsservicebus']['certificate']['CaCertificate']['key_path'] = File.join(Chef::Config[:file_cache_path], node['windowsservicebus']['certificate']['CaCertificate']['common_name'] + '.key')

default['windowsservicebus']['certificate']['FarmCertificate']['common_name'] = node['windowsservicebus']['instance']['FarmDns']
default['windowsservicebus']['certificate']['FarmCertificate']['cert_source'] = 'with_ca'
default['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path'] = File.join(Chef::Config[:file_cache_path], node['windowsservicebus']['certificate']['FarmCertificate']['common_name'] + '.pfx')
default['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase'] = nil
default['windowsservicebus']['certificate']['FarmCertificate']['private_key_acl'] = ["#{domain}\\#{username}", "#{domain}\\vagrant"]
default['windowsservicebus']['certificate']['FarmCertificate']['store_name'] = "MY"
default['windowsservicebus']['certificate']['FarmCertificate']['user_store'] = false
default['windowsservicebus']['certificate']['FarmCertificate']['ca_cert_path'] = node['windowsservicebus']['certificate']['CaCertificate']['cert_path']
default['windowsservicebus']['certificate']['FarmCertificate']['ca_key_path'] = node['windowsservicebus']['certificate']['CaCertificate']['key_path']

default['windowsservicebus']['certificate']['EncryptionCertificate']['common_name'] = node['windowsservicebus']['instance']['FarmDns'] + '.encyption'
default['windowsservicebus']['certificate']['EncryptionCertificate']['cert_source'] = 'with_ca'
default['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path'] = File.join(Chef::Config[:file_cache_path], node['windowsservicebus']['certificate']['EncryptionCertificate']['common_name'] + '.pfx')
default['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase'] = nil
default['windowsservicebus']['certificate']['EncryptionCertificate']['private_key_acl'] = ["#{domain}\\#{username}", "#{domain}\\vagrant"]
default['windowsservicebus']['certificate']['EncryptionCertificate']['store_name'] = "MY"
default['windowsservicebus']['certificate']['EncryptionCertificate']['user_store'] = false
default['windowsservicebus']['certificate']['EncryptionCertificate']['ca_cert_path'] = node['windowsservicebus']['certificate']['CaCertificate']['cert_path']
default['windowsservicebus']['certificate']['EncryptionCertificate']['ca_key_path'] = node['windowsservicebus']['certificate']['CaCertificate']['key_path']


dsn = "Data Source=#{node['windowsservicebus']['database']['host']};Integrated Security=True;Encrypt=False"
default['windowsservicebus']['instance']['connectionstring']['SbManagementDB'] = "#{dsn};Initial Catalog=SbManagementDB"
default['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase'] = "#{dsn};Initial Catalog=SbGatewayDatabase"

default['windowsservicebus']['instance']['SBMessageContainers'] = [
	{
		:DatabaseName=>"SBMessageContainer01",
		:ConnectionString=>"#{dsn};Initial Catalog=SBMessageContainer01"
	}, 
	{
		:DatabaseName=>"SBMessageContainer02",
		:ConnectionString=>"#{dsn};Initial Catalog=SBMessageContainer02"
	}, 
	{
		:DatabaseName=>"SBMessageContainer03",
		:ConnectionString=>"#{dsn};Initial Catalog=SBMessageContainer03"
	}
]

default['windowsservicebus']['instance']['ServiceBusNamespaces'] = [
	{
		:Namespace=>'ServiceBusDefaultNamespace', 
		:PrimaryKey=>'GiutFN4v7rgwdDPdeo2sV9o0+gn4YtOPsI1r5q1B3RU=', 
		:SecondaryKey=>'GiutFN4v7rgwdDPdeo2sV9o0+gn4YtOPsI1r5q1B3RU='
	},
	{
		:Namespace=>'Application',
		:PrimaryKey=>'GiutFN4v7rgwdDPdeo2sV9o0+gn4YtOPsI1r5q1B3RU=', 
		:SecondaryKey=>'GiutFN4v7rgwdDPdeo2sV9o0+gn4YtOPsI1r5q1B3RU='
	}
]


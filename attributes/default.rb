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

default['windowsservicebus']['database']['roles'] = ['sysadmin']
default['windowsservicebus']['database']['host'] = '127.0.0.1'
default['windowsservicebus']['database']['port'] = node['sql_server']['port']
default['windowsservicebus']['database']['username'] = nil
default['windowsservicebus']['database']['password'] = nil

default['windowsservicebus']['service']['account'] = 'ServiceBus' # e.g. ServiceBus. This account is used to access the database server, so ensure that database permission have been configured. This account is used to run service, so ensure that it has the correct permissions on each node. If using multiple nodes, active directory is required.
default['windowsservicebus']['service']['password'] = 'P@ssw0rd' # e.g. P@ssw0rd. This is the password to use if creating a windows account locally to use.
default['windowsservicebus']['service']['group'] = 'Administrators'
default['windowsservicebus']['service']['enablefirewalls'] = true

default['windowsservicebus']['instance']['FarmDns'] = node['fqdn']  # e.g. servicebus.localtest.me
default['windowsservicebus']['instance']['FarmCertificateThumbprint'] = '' # e.g. wildcard certificate *.localtest.me thumbprint
default['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] = '' # e.g. wildcard certificate *.localtest.me thumbprint

dsn = "Data Source=#{default['windowsservicebus']['database']['host']};Integrated Security=True;Encrypt=False"
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
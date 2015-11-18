#
# Cookbook Name:: windowsservicebus
# Recipe:: certificate
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

ca_cert = ssl_certificate node['windowsservicebus']['certificate']['CaCertificate']['common_name'] do
	common_name node['windowsservicebus']['certificate']['CaCertificate']['common_name']
	cert_source node['windowsservicebus']['certificate']['CaCertificate']['cert_source']
	key_source node['windowsservicebus']['certificate']['CaCertificate']['key_source']
	cert_path node['windowsservicebus']['certificate']['CaCertificate']['cert_path']
	key_path node['windowsservicebus']['certificate']['CaCertificate']['key_path']
	pkcs12_path node['windowsservicebus']['certificate']['CaCertificate']['pkcs12_path']
	pkcs12_passphrase node['windowsservicebus']['certificate']['CaCertificate']['pkcs12_passphrase']
	namespace node['windowsservicebus']['certificate']['CaCertificate']
	only_if { node['windowsservicebus']['instance']['FarmCertificateThumbprint'] == '' ||  node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] == '' }
end

windows_certificate node['windowsservicebus']['certificate']['CaCertificate']['common_name'] do
	source node['windowsservicebus']['certificate']['CaCertificate']['pkcs12_path']
	pfx_password node['windowsservicebus']['certificate']['CaCertificate']['pkcs12_passphrase']
	private_key_acl node['windowsservicebus']['certificate']['CaCertificate']['private_key_acl']
	store_name node['windowsservicebus']['certificate']['CaCertificate']['store_name']
	user_store node['windowsservicebus']['certificate']['CaCertificate']['user_store']
	only_if { node['windowsservicebus']['instance']['FarmCertificateThumbprint'] == '' ||  node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] == '' }
end	

ssl_certificate node['windowsservicebus']['certificate']['FarmCertificate']['common_name'] do
	common_name node['windowsservicebus']['certificate']['FarmCertificate']['common_name']
	cert_source node['windowsservicebus']['certificate']['FarmCertificate']['cert_source']
	ca_cert_path node['windowsservicebus']['certificate']['FarmCertificate']['ca_cert_path']
	ca_key_path node['windowsservicebus']['certificate']['FarmCertificate']['ca_key_path']	
	pkcs12_path node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']
	pkcs12_passphrase node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']
	namespace node['windowsservicebus']['certificate']['FarmCertificate']
	only_if { node['windowsservicebus']['instance']['FarmCertificateThumbprint'] == '' }
end

windows_certificate node['windowsservicebus']['certificate']['FarmCertificate']['common_name'] do
	source node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']
	pfx_password node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']
	private_key_acl node['windowsservicebus']['certificate']['FarmCertificate']['private_key_acl']
	store_name node['windowsservicebus']['certificate']['FarmCertificate']['store_name']
	user_store node['windowsservicebus']['certificate']['FarmCertificate']['user_store']
	only_if { node['windowsservicebus']['instance']['FarmCertificateThumbprint'] == '' }
end	

ssl_certificate node['windowsservicebus']['certificate']['EncryptionCertificate']['common_name'] do
	common_name node['windowsservicebus']['certificate']['EncryptionCertificate']['common_name']
	cert_source node['windowsservicebus']['certificate']['EncryptionCertificate']['cert_source']
	ca_cert_path node['windowsservicebus']['certificate']['EncryptionCertificate']['ca_cert_path']
	ca_key_path node['windowsservicebus']['certificate']['EncryptionCertificate']['ca_key_path']
	pkcs12_path node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']
	pkcs12_passphrase node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']
	namespace node['windowsservicebus']['certificate']['EncryptionCertificate']	
	only_if { node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] == '' }
end

windows_certificate node['windowsservicebus']['certificate']['EncryptionCertificate']['common_name'] do
	source node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']
	pfx_password node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']
	private_key_acl node['windowsservicebus']['certificate']['EncryptionCertificate']['private_key_acl']
	store_name node['windowsservicebus']['certificate']['EncryptionCertificate']['store_name']
	user_store node['windowsservicebus']['certificate']['EncryptionCertificate']['user_store']
	only_if { node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] == '' }
end

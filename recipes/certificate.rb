#
# Cookbook Name:: windowsservicebus
# Recipe:: certificate
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

if (node['windowsservicebus']['instance']['FarmCertificateThumbprint'] != '')
	cert = ssl_certificate 'FarmCertificate' do
		namespace node['windowsservicebus']['certificate']['FarmCertificate']
	end

	windows_certificate certificate_path do
		source cert.pkcs12_path
	    pfx_password cert.pkcs12_passphrase
		private_key_acl default['windowsservicebus']['certificate']['FarmCertificate']['private_key_acl']
	    store_name default['windowsservicebus']['certificate']['FarmCertificate']['store_name']
	    user_store default['windowsservicebus']['certificate']['FarmCertificate']['user_store']
	end

	ruby_block 'load thumbprint for FarmCertificateThumbprint' do
	  block do
	    file_data = File.open(cert.pkcs12_path, 'rb') { |io| io.read }
		cert_for_thumbprint = OpenSSL::PKCS12.new(file_data, cert.pkcs12_passphrase)
		thumbprint = OpenSSL::Digest::SHA1.new(cert_for_thumbprint.to_der).to_s
		
		node.default['windowsservicebus']['instance']['FarmCertificateThumbprint'] = thumbprint # e.g. wildcard certificate *.localtest.me thumbprint		
	  end
	  action :run
	end
end

if (node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] != '')
	cert = ssl_certificate 'EncryptionCertificate' do
		namespace node['windowsservicebus']['certificate']['EncryptionCertificate']
	end

	windows_certificate certificate_path do
		source cert.pkcs12_path
	    pfx_password cert.pkcs12_passphrase
		private_key_acl default['windowsservicebus']['certificate']['EncryptionCertificate']['private_key_acl']
	    store_name default['windowsservicebus']['certificate']['EncryptionCertificate']['store_name']
	    user_store default['windowsservicebus']['certificate']['EncryptionCertificate']['user_store']
	end

	ruby_block 'load thumbprint for EncryptionCertificateThumbprint' do
	  block do
	    file_data = File.open(cert.pkcs12_path, 'rb') { |io| io.read }
		cert_for_thumbprint = OpenSSL::PKCS12.new(file_data, cert.pkcs12_passphrase)
		thumbprint = OpenSSL::Digest::SHA1.new(cert_for_thumbprint.to_der).to_s
		
		node.default['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] = thumbprint # e.g. wildcard certificate *.localtest.me thumbprint		
	  end
	  action :run
	end
end

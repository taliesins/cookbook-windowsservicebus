#
# Cookbook Name:: windowsservicebus
# Recipe:: certificate
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

certificate_path = File.join(Chef::Config[:file_cache_path], '/windowsservicebus/certificate.pfx') 
certificate_password = nil

ssl_certificate node['windowsservicebus']['instance']['FarmDns'] do
	common_name node['windowsservicebus']['instance']['FarmDns']
	source 'self-signed'
	pkcs12_path certificate_path
	pkcs12_passphrase certificate_password
	not_if { ::File.file?(download_path) }
end

ruby_block 'load thumbprint' do
  block do
    file_data = File.read(certificate_path)
	cert = OpenSSL::X509::Certificate.new(file_data)
	thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der).to_s

	Chef::Log.Info("thumbprint for certificate is: #{thumbprint}")

	node['windowsservicebus']['instance']['FarmCertificateThumbprint'] = thumbprint # e.g. wildcard certificate *.localtest.me thumbprint
	node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] = node['windowsservicebus']['instance']['FarmCertificateThumbprint'] # e.g. wildcard certificate *.localtest.me thumbprint
  end
  action :run
end
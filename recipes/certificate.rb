#
# Cookbook Name:: windowsservicebus
# Recipe:: certificate
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

ca_cert = ssl_certificate '*.localtest.me' do
  common_name 'ca.localtest.me'
  source 'chef-vault'
  bag 'ssl'
  item 'ca_cert'
  key_item_key 'key_content'
  cert_item_key 'cert_content'
end

ssl_certificate '*.localtest.me' do
  cert_source 'with_ca'
  ca_cert_path ca_cert.cert_path
  ca_key_path ca_cert.key_path
end
#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require

#repodir = "/usr/local/kickstart/vc/staging"
repodir = '/home/nishiki'
#update_repo = 'createrepo --update /var/www/html/repos'
deploy_package = Dir.glob("#{ENV['HOME']}/rpmbuild/RPMS/noarch/*").max_by {|f| File.mtime(f)}
puts deploy_package
reposerver = '192.168.201.241'
cmd = 'ls -al'
body = ''

Net::SCP.start(reposerver, 'nishiki',:keys => ['/tmp/key']) do |scp|
  scp.upload!("#{deploy_package}", "#{repodir}") do |ch, name, sent, total|
    puts "#{name}: #{sent}/#{total}"
  end
    puts "finished."
end

Net::SSH.start(reposerver, 'nishiki', :keys => ['/tmp/key']) do |ssh|
  ssh.exec!("#{cmd}") do |channel, stream, data|
    puts data
  end
end

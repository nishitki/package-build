#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'open3'
Bundler.require

ENV['HOME'] = ENV['WORKSPACE']
ENV['JAVA_HOME'] = '/usr/local/java'
ENV['ANT_HOME'] = '/usr/local/apache-ant-1.7.0'
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['ANT_HOME']}/bin"


package_dir = '/usr/local/kickstart/vc'
branch = "#{ENV['GIT_BRANCH']}"
environment = branch.match(/(deploy\/[a-z0-9.]*)\.([0-9a-z]*)\.([0-9a-z]*)$/)[2]
rpmdir = "#{ENV['HOME']}/rpmbuild/RPMS/noarch"
repodir = "/usr/local/kickstart/vc/#{environment}"
reposerver = "192.168.201.241"
update_repo = 'createrepo --update /var/www/html/repos'
deploy_package = Dir.glob("#{ENV['HOME']}/rpmbuild/RPMS/noarch/*").max_by {|f| File.mtime(f)}

def post(text)
  data = {
    "channel"  => '#infra',
    "username" => 'vcbot',
    "icon_url" => 'https://avatars3.githubusercontent.com/u/13045145?v=3&s=400',
    "text" => text
  }
  request_url = ENV['SLACK_INCOMING_WEBHOOK']
  uri = URI.parse(request_url)
  http = Net::HTTP.post_form(uri, {"payload" => data.to_json})
end

Open3.popen3("rpmdev-setuptree") do |stdin, stdout, stderr, wait_thr|
  unless stderr.read.empty?
    puts "ERROR: Can\'t create build environment"
    exit (1)
  end
end

Open3.popen3("rpmbuild --clean -bb `ls -t *.spec |head -1`") do |stdin, stdout, stderr, wait_thr|
  while output = stdout.gets
     output.chomp!
     puts output 
  end 
  unless wait_thr.value.success?
    puts 'Build Failed'
    exit (1)
  end
end

Net::SCP.start("#{reposerver}", "jenkins", :keys => ['~/.ssh/id_rsa']) do |scp|
  scp.upload!("#{rpmdir}/#{deploy_package}", "#{repodir}") do |channel, stream, data|
    body << data if stream == :stdout
  end

 # if body.include?("hoge")
 #   puts "fail"
 # else
 #   Net::SSH.start("#{host}", "jenkins", :keys => ['~/.ssh/id_rsa']) do |ssh|
 #   ssh.exec!("#{update_repo}") do |channel, stream, data|  
 #     body << data if stream == :stdout 
 #   end
 #   if body.include?("package(s) needed for security")  
 #      puts "error"
 #      exit (1)
 #   end
end

body = <<-"EOC" 
Pull Request: master -> ENV['GIT_BRANCH'] build successfully finished
continue manual merge ENV['BUILD_URL'] to deploy
just close pull request to cancel
EOC

#post(body)

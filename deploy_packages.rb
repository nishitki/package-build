#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require

ENV['HOME'] = ENV['WORKSPACE']
ENV['JAVA_HOME'] = '/usr/local/java'
ENV['ANT_HOME'] = '/usr/local/apache-ant-1.7.0'
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['ANT_HOME']}/bin"

puts ENV['HOME'] 

Open3.popen3("rpmdev-setuptree") do |stdin, stdout, stderr, wait_thr|
  unless stderr.read.empty?
    puts 'ERROR'
    exit (1)
  end
end


Open3.popen3("rpmbuild --clean -ba `ls -t *.spec |head -1`") do |stdin, stdout, stderr, wait_thr|
  puts stdout.read
  unless wait_thr.value.success?
    puts 'Build Failed'
    exit (1)
  end
end

def post(text)
  data = {
    "channel"  => '#infra',
    "username" => 'bot',
    "icon_url" => 'https://avatars3.githubusercontent.com/u/7507421?v=3&s=400',
    "text" => text
  }
  request_url = ENV['SLACK_INCOMING_WEBHOOK']
  uri = URI.parse(request_url)
  http = Net::HTTP.post_form(uri, {"payload" => data.to_json})
end

body = <<-"EOC" 
Pull Request: master -> ENV['GIT_BRANCH'] build successfully finished
continue manual merge ENV['BUILD_URL'] to deploy
just close pull request to cancel
EOC

post(body)

#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require


ENV['HOME'] = ENV['WORKSPACE']
ENV['JAVA_HOME'] = '/usr/local/java'
ENV['ANT_HOME'] = '/usr/local/apache-ant-1.7.0'
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['ANT_HOME']}/bin"

create_rpmdir = 'rpmdev-setuptree'
build_rpm = 'rpmbuild -ba `ls -t *.spec |head -1`'

if $?.exitstatus == 1
  STDERR.print "  "
  exit 1
end


create_rpmdir.exitstatus
build_rpm.exitstatus

def post(text)
  data = {
    "channel"  => '#infra',
    "username" => 'vcbot',
    "text" => text
  }
  request_url = ENV['SLACK_INCOMING_WEBHOOK']
  uri = URI.parse(request_url)
  http = Net::HTTP.post_form(uri, {"payload" => data.to_json})
end

"Pull Request: master -> ENV['GIT_BRANCH'] build successfully finished"
"continue manual merge ENV['BUILD_URL'] to deploy"
"just close pull request to cancel"

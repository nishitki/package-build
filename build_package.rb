#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'open3'
Bundler.require

ENV['HOME'] = ENV['WORKSPACE']
ENV['JAVA_HOME'] = '/usr/local/java'
ENV['ANT_HOME'] = '/usr/local/apache-ant-1.7.0'
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['ANT_HOME']}/bin"
ENV['GITHUB_ACCESS_TOKEN'] = 'mytoken'
ENV['SLACK_INCOMING_WEBHOOK'] = 'https://hooks.slack.com/services/mytoken'

repo = 'vcjp/packages'
branch = ENV['GIT_BRANCH']
pullrequesturl = ''
environment = branch.match(/(deploy\/[a-z0-9.]*)\.([0-9a-z]*)\.([0-9a-z]*)$/)[2]

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

client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
pull = client.pull_requests(repo, :state => 'open')
pull.each do |p|
  pullrequesturl = p.html_url.gsub(/api.github.com\/repos/, 'github.com').gsub(/pulls/, 'pull')
  head = p.head.ref

  if !head.eql?(branch) 
    puts "branch name does not mutch git head"
    exit (1)
  end

end

Open3.popen3("rpmdev-setuptree") do |stdin, stdout, stderr, wait_thr|
  unless stderr.read.empty?
    puts "ERROR: Can\'t create build environment"
    exit (1)
  end
end

Open3.popen3("rpmbuild --clean -ba `ls -t *.spec |head -1`") do |stdin, stdout, stderr, wait_thr|
  while output = stdout.gets
    output.chomp!
    puts output 
  end 
  unless wait_thr.value.success?
    exit (1)
  end
end

body = <<-"EOC" 
Pull Request: master -> #{ENV['GIT_BRANCH']} build successfully finished
continue manual merge #{pullrequesturl} to deploy
just close pull request to cancel
EOC

post(body)

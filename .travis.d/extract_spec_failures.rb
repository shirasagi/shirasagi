#!/usr/bin/env ruby

body = []
STDIN.each_line do |line|
  STDOUT.write(line)
  line =~ /^rspec (\.\/spec\/\S+)/
  next if $1.nil?
  body << $1
end
File.write("failures", body.join("\n"))

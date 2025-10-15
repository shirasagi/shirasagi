#!/usr/bin/env ruby

require "set"

# Collect failing spec paths from RSpec output regardless of ANSI colors or indentation.
failures = Set.new

STDIN.each_line do |line|
  STDOUT.write(line)

  sanitized = line.gsub(/\e\[[0-9;]*m/, "")
  next unless sanitized.include?("./spec/")

sanitized.scan(/(?:rspec|#)\s+(\.\/spec\/\S+)/) do |match|
  candidate = match.first
  normalized = candidate[/\.\/spec\/[^\s:#]+\.rb(?::\d+(?::\d+)*)?/]
  failures << normalized if normalized
end
end

File.write("failures", failures.to_a.sort.join("\n"))

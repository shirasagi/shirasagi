#!/usr/bin/env ruby
require "optparse"

parallelism = 6
index = 0
includes = []
excludes = []

OptionParser.new do |opt|
  opt.on('-p', '--parallelism val', Integer) { |v| parallelism = v }
  opt.on('-i', '--index val', Integer) { |v| index = v }
  opt.on('-e', '--exclude val', String) { |v| excludes << v }
  opt.on('--include val', String) { |v| includes << v }
  opt.parse!(ARGV)
end

count = `find spec -name '*.rb' | fgrep -v spec/factories/ | fgrep -v spec/support/ | fgrep -v _spec.rb | wc -l`
count = count.strip.to_i
if count > 1
  STDERR.puts "there are spec files which aren't ended with \"_spec.rb\""
  exit!
end

all_spec_files = Dir.glob("#{ARGV.first || "spec"}/**/*_spec.rb")
if includes.empty?
  spec_files = all_spec_files
else
  spec_files = []
  includes.each do |inc|
    spec_files += all_spec_files.select { |file| file.include?(inc) }
  end
end
excludes.each do |exclude|
  spec_files.reject! { |file| file.include?(exclude) }
end
spec_files.sort! do |lhs, rhs|
  diff = ::File.size(rhs) <=> ::File.size(lhs)
  next diff if diff != 0

  lhs <=> rhs
end

puts spec_files.select.with_index { |_, i| i % parallelism == index }.join(' ')

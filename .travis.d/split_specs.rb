#!/usr/bin/env ruby
require "optparse"

parallelism = 6
index = 0
excludes = []

OptionParser.new do |opt|
  opt.on('-p', '--parallelism val', Integer) { |v| parallelism = v }
  opt.on('-i', '--index val', Integer) { |v| index = v }
  opt.on('-e', '--exclude val', String) { |v| excludes << v }
  opt.parse!(ARGV)
end

spec_files = Dir.glob("#{ARGV.first || "spec"}/**/*.rb")
excludes.each do |exclude|
  spec_files.reject! { |file| file.include?(exclude) }
end
spec_files.sort! do |lhs, rhs|
  diff = ::File.size(rhs) <=> ::File.size(lhs)
  next diff if diff != 0

  lhs <=> rhs
end

puts spec_files.select.with_index { |_, i| i % parallelism == index }.join(' ')

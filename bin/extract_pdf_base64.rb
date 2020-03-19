#!/usr/bin/env ruby

path = ARGV[0]
limit = ARGV[1].to_i

require 'rmagick'
require 'base64'

images = []

begin
  0.upto(limit - 1) do |n|
    image = Magick::Image.read(path + "[#{n}]") do
      self.quality = 100
      self.density = 200
    end.first

    break if image.nil?
    image.format = "PNG"
    images << Base64.strict_encode64(image.to_blob)
  end
rescue => e
  STDERR.puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
end

STDOUT.print images.join("\n")

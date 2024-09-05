#!/usr/bin/env ruby

path = ARGV[0]
limit = ARGV[1].to_i

require 'mini_magick'
require 'base64'

images = []

begin
  image = MiniMagick::Image.new(path)
  image.pages.each_with_index do |page, n|
    break if n >= limit
    Tempfile.open(['extract_pdf_base64', '.png'], binmode: true) do |temp|
      MiniMagick.convert do |convert|
        convert.quality 100
        convert.density 200
        convert << page.path
        convert << temp.path
      end
      images << Base64.strict_encode64(temp.read)
    end
  end
rescue => e
  STDERR.puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
end

STDOUT.print images.join("\n")

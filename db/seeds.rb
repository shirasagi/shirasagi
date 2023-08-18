# seed entry point

seed = ENV['name']
file = "#{Rails.root}/db/seeds/#{seed}/load.rb"

puts "Please input seed name: name=[seed_name]" or exit if seed.blank?
puts "Seed file not found: #{seed}" or exit unless File.exist?(file)

require "#{Rails.root}/db/seeds/#{seed}/load.rb"

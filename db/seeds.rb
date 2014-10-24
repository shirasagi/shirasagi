if ENV["name"].blank?
  puts "Please input seed name. ( name= )"
  exit
end

if ENV["site"].blank?
  puts "Please input site name. ( site= )"
  exit
end

if name = ENV["name"].presence
  require "#{Rails.root}/db/seeds/#{name}/load.rb"
end

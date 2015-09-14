## -------------------------------------
# Require

puts "Please input site_name: site=[group_name]" or exit if ENV['site'].blank?

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"

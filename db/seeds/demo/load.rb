## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?
Dir.chdir @root = File.dirname(__FILE__)

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
@link_url = "http://#{@site.domains.first}"

require "#{Rails.root}/db/seeds/cms/contents/users"

@g_seisaku = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first

require "#{Rails.root}/db/seeds/cms/contents/workflow"
require "#{Rails.root}/db/seeds/cms/contents/members"
load "#{Rails.root}/db/seeds/cms/contents/files.rb"
load "#{Rails.root}/db/seeds/cms/contents/layouts.rb"
load "#{Rails.root}/db/seeds/cms/contents/parts.rb"
load "#{Rails.root}/db/seeds/cms/contents/forms.rb"
load "#{Rails.root}/db/seeds/cms/contents/nodes.rb"
load "#{Rails.root}/db/seeds/cms/contents/inquiry.rb"
load "#{Rails.root}/db/seeds/cms/contents/body_layouts.rb"
load "#{Rails.root}/db/seeds/cms/contents/articles.rb"
load "#{Rails.root}/db/seeds/cms/contents/sitemap.rb"
load "#{Rails.root}/db/seeds/cms/contents/faq.rb"
load "#{Rails.root}/db/seeds/cms/contents/ads.rb"
load "#{Rails.root}/db/seeds/cms/contents/facility.rb"
load "#{Rails.root}/db/seeds/cms/contents/member_blog.rb"
load "#{Rails.root}/db/seeds/cms/contents/member_photo.rb"
load "#{Rails.root}/db/seeds/cms/contents/key_visual.rb"
load "#{Rails.root}/db/seeds/cms/contents/editor_templates.rb"
load "#{Rails.root}/db/seeds/cms/contents/theme_templates.rb"
load "#{Rails.root}/db/seeds/cms/contents/board.rb"
load "#{Rails.root}/db/seeds/cms/contents/anpi.rb"
load "#{Rails.root}/db/seeds/cms/contents/weather_xml.rb"
load "#{Rails.root}/db/seeds/cms/contents/cms_garbage_node.rb"
load "#{Rails.root}/db/seeds/cms/contents/max_file_size.rb"
load "#{Rails.root}/db/seeds/cms/contents/source_cleaner_templates.rb"
load "#{Rails.root}/db/seeds/cms/contents/postal_code.rb"
load "#{Rails.root}/db/seeds/cms/contents/word_dictionary.rb"

## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?
Dir.chdir @root = File.dirname(__FILE__)

@site = Cms::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
@link_url = "http://#{@site.domains.first}"

load "#{Rails.root}/db/seeds/cms/users.rb"

@g_ss = SS::Group.where(name: "シラサギ市").first
@g_seisaku = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first

if @site.translate_api_limit_exceeded_html.blank?
  @site.translate_api_limit_exceeded_html = File.read("translate/limit_exceeded.html") rescue nil
  @site.save
end

@contact_group = Cms::Group.where(name: "シラサギ市/企画政策部/政策課").first
@contact_group_id = @contact_group.id if @contact_group
@contact_sub_group1 = Cms::Group.where(name: "シラサギ市/企画政策部/政策課/経営戦略係").first
@contact_sub_group_ids1 = [@contact_sub_group1.id] if @contact_sub_group1
@contact_sub_group2 = Cms::Group.where(name: "シラサギ市/企画政策部/政策課/デジタル戦略係").first
@contact_sub_group_ids2 = [@contact_sub_group2.id] if @contact_sub_group2
@contact = @contact_group.contact_groups.first

load "#{Rails.root}/db/seeds/cms/workflow.rb"
load "#{Rails.root}/db/seeds/cms/members.rb"
load "#{Rails.root}/db/seeds/demo/contents/files.rb"
load "#{Rails.root}/db/seeds/demo/contents/layouts.rb"
load "#{Rails.root}/db/seeds/demo/contents/parts.rb"
load "#{Rails.root}/db/seeds/demo/contents/forms.rb"
load "#{Rails.root}/db/seeds/demo/contents/nodes.rb"
load "#{Rails.root}/db/seeds/demo/contents/inquiry.rb"
load "#{Rails.root}/db/seeds/demo/contents/body_layouts.rb"
load "#{Rails.root}/db/seeds/demo/contents/articles.rb"
load "#{Rails.root}/db/seeds/demo/contents/sitemap.rb"
load "#{Rails.root}/db/seeds/demo/contents/faq.rb"
load "#{Rails.root}/db/seeds/demo/contents/ads.rb"
load "#{Rails.root}/db/seeds/demo/contents/facility.rb"
load "#{Rails.root}/db/seeds/demo/contents/member_blog.rb"
load "#{Rails.root}/db/seeds/demo/contents/member_photo.rb"
load "#{Rails.root}/db/seeds/demo/contents/key_visual.rb"
load "#{Rails.root}/db/seeds/demo/contents/editor_templates.rb"
load "#{Rails.root}/db/seeds/demo/contents/theme_templates.rb"
load "#{Rails.root}/db/seeds/demo/contents/board.rb"
load "#{Rails.root}/db/seeds/demo/contents/anpi.rb"
load "#{Rails.root}/db/seeds/demo/contents/weather_xml.rb"
load "#{Rails.root}/db/seeds/demo/contents/cms_garbage_node.rb"
load "#{Rails.root}/db/seeds/demo/contents/guide.rb"
load "#{Rails.root}/db/seeds/demo/contents/chat.rb"
load "#{Rails.root}/db/seeds/demo/contents/max_file_size.rb"
load "#{Rails.root}/db/seeds/demo/contents/source_cleaner_templates.rb"
load "#{Rails.root}/db/seeds/demo/contents/postal_code.rb"
load "#{Rails.root}/db/seeds/demo/contents/word_dictionary.rb"
load "#{Rails.root}/db/seeds/demo/contents/translate_lang.rb"
load "#{Rails.root}/db/seeds/demo/contents/line.rb"
load "#{Rails.root}/db/seeds/demo/contents/image_map.rb"
load "#{Rails.root}/db/seeds/demo/contents/cms_notices.rb"

if @site.subdir.present?
  # rake cms:set_subdir_url site=@site.host
  require 'rake'
  Rails.application.load_tasks
  ENV["site"]=@site.host
  Rake::Task['cms:set_subdir_url'].invoke
end

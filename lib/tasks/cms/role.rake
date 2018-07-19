namespace :cms do
  task set_admin_role: :environment do
    puts "Please input user name: user=[user_name]" or exit if ENV['user'].blank?
    puts "Please input site_name: site=[site_name]" or exit if ENV['site'].blank?

    user = Cms::User.flex_find ENV['user']
    puts "User not found: #{ENV['user']}" or exit unless user

    site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    role = Cms::Role.find_or_create_by name: I18n.t('cms.roles.admin'), site_id: site.id
    role.update permissions: Cms::Role.permission_names, permission_level: 3
    user.add_to_set cms_role_ids: role.id

    puts "#{user.name}: #{role.name}"
  end
end

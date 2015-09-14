namespace :gws do
  task :set_admin_role => :environment do
    puts "Please input user name: user=[user_name]" or exit if ENV['user'].blank?
    puts "Please input site_name: site=[site_name]" or exit if ENV['site'].blank?

    user = Gws::User.flex_find ENV['user']
    puts "User not found: #{ENV['user']}" or exit unless user

    site = Gws::Group.where(name: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    role = Gws::Role.find_or_create_by name: I18n.t('gws.roles.admin'), site_id: site.id
    role.update permissions: Gws::Role.permission_names, permission_level: 3
    user.add_to_set gws_role_ids: role.id

    puts "#{user.name}: #{role.name}"
  end
end

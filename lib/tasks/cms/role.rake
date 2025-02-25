namespace :cms do
  task set_admin_role: :environment do
    ::Tasks::Cms.with_site(ENV['site']) do |site|
      puts "Please input user name: user=[user_name]" or exit if ENV['user'].blank?

      user = Cms::User.flex_find ENV['user']
      puts "User not found: #{ENV['user']}" or exit unless user

      role = Cms::Role.find_or_create_by name: I18n.t('cms.roles.admin'), site_id: site.id
      role.update permissions: Cms::Role.permission_names
      user.add_to_set cms_role_ids: role.id

      puts "#{user.name}: #{role.name}"
    end
  end
end

namespace :sys do
  task :set_admin_role => :environment do
    puts "Please input user name: user=[user_name]" or exit if ENV['user'].blank?

    user = SS::User.flex_find ENV['user']
    puts "User not found: #{ENV['user']}" or exit unless user

    role = Sys::Role.find_or_create_by name: I18n.t('sys.roles.admin')
    role.update permissions: Sys::Role.permission_names
    user.add_to_set sys_role_ids: role.id

    puts "#{user.name}: #{role.name}"
  end
end

namespace :webmail do
  task set_admin_role: :environment do
    puts "Please input user name: user=[user_name]" or exit if ENV['user'].blank?

    user = Webmail::User.flex_find ENV['user']
    puts "User not found: #{ENV['user']}" or exit unless user

    role = Webmail::Role.find_or_create_by name: I18n.t('webmail.roles.admin')
    role.update permissions: Webmail::Role.permission_names
    user.add_to_set webmail_role_ids: role.id

    puts "#{user.name}: #{role.name}"
  end
end

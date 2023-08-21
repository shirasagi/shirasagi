namespace :gws do
  task set_admin_role: :environment do
    ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
      ::Tasks::Gws::Base.with_user(ENV['user']) do |user|
        role = Gws::Role.find_or_create_by name: I18n.t('gws.roles.admin'), site_id: site.id
        role.update permissions: Gws::Role.permission_names, permission_level: 3
        user.add_to_set gws_role_ids: role.id

        puts "#{user.name}: #{role.name}"
      end
    end
  end
end

namespace :gws do
  namespace :ldap do
    task sync: :environment do
      ::Tasks::Gws::Ldap.sync
    end
  end
end

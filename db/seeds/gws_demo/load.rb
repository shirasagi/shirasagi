# --------------------------------------
# Require

require "#{Rails.root}/db/seeds/ss/users"
@site = Gws::Group.where(name: 'シラサギ市').first

# --------------------------------------
# Seed

def save_role(data)
  if item = Gws::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Gws::Role.new(data)
  item.save
  item
end

puts "# roles"
user_permissions = Gws::Role.permission_names.select {|n| n =~ /_private_/ }
r01 = save_role name: I18n.t('gws.roles.admin'), site_id: @site.id, permissions: Gws::Role.permission_names, permission_level: 3
r02 = save_role name: I18n.t('gws.roles.user'), site_id: @site.id, permissions: user_permissions, permission_level: 1

Gws::User.find_by(uid: "sys").add_to_set(gws_role_ids: r01.id)
Gws::User.find_by(uid: "admin").add_to_set(gws_role_ids: r01.id)
Gws::User.find_by(uid: "user1").add_to_set(gws_role_ids: r02.id)
Gws::User.find_by(uid: "user2").add_to_set(gws_role_ids: r02.id)
Gws::User.find_by(uid: "user3").add_to_set(gws_role_ids: r02.id)

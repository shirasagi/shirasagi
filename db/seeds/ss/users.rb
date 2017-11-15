
site_name = defined?(ENV['group']) ? ENV['group'] : 'シラサギ市'

# --------------------------------------
# Users Seed

def save_group(data)
  if item = SS::Group.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update_attributes! data
    return item
  end

  puts "create #{data[:name]}"
  item = SS::Group.new(data)
  item.save
  item
end

puts "# groups"
g00 = save_group name: site_name, order: 10
g10 = save_group name: "#{site_name}/企画政策部", order: 20
g11 = save_group name: "#{site_name}/企画政策部/政策課", order: 30
g12 = save_group name: "#{site_name}/企画政策部/広報課", order: 40
g20 = save_group name: "#{site_name}/危機管理部", order: 50
g21 = save_group name: "#{site_name}/危機管理部/管理課", order: 60
g22 = save_group name: "#{site_name}/危機管理部/防災課", order: 70

def save_role(data)
  if item = Sys::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Sys::Role.new(data)
  item.save
  item
end

puts "# roles"
r01 = save_role name: I18n.t('sys.roles.admin'), permissions: Sys::Role.permission_names

def save_user(data)
  if item = SS::User.where(email: data[:email]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = SS::User.new(data)
  item.save
  item
end

puts "# users"
sys = save_user name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass"
adm = save_user name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass"
u01 = save_user name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass"
u02 = save_user name: "一般ユーザー2", uid: "user2", email: "user2@example.jp", in_password: "pass"
u03 = save_user name: "一般ユーザー3", uid: "user3", email: "user3@example.jp", in_password: "pass"

sys.add_to_set group_ids: [g11.id], sys_role_ids: [r01.id]
adm.add_to_set group_ids: [g11.id]
u01.add_to_set group_ids: [g11.id]
u02.add_to_set group_ids: [g21.id]
u03.add_to_set group_ids: [g12.id, g22.id]

## -------------------------------------
# Gws Roles

def save_gws_role(data)
  if item = Gws::Role.where(site_id: data[:site_id], name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Gws::Role.new(data)
  item.save
  item
end

puts "# gws roles"
user_permissions = Gws::Role.permission_names.select { |n| n =~ /_private_/ }
r01 = save_gws_role name: I18n.t('gws.roles.admin'), site_id: g00.id, permissions: Gws::Role.permission_names, permission_level: 3
r02 = save_gws_role name: I18n.t('gws.roles.user'), site_id: g00.id, permissions: user_permissions, permission_level: 1

Gws::User.find_by(uid: "sys").add_to_set(gws_role_ids: r01.id)
Gws::User.find_by(uid: "admin").add_to_set(gws_role_ids: r01.id)
Gws::User.find_by(uid: "user1").add_to_set(gws_role_ids: r02.id)
Gws::User.find_by(uid: "user2").add_to_set(gws_role_ids: r02.id)
Gws::User.find_by(uid: "user3").add_to_set(gws_role_ids: r02.id)

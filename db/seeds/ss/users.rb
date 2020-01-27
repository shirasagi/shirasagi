puts 'ss/users.rb'
site_name = SS::Db::Seed.site_name || 'シラサギ市'

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
  puts item.errors.full_messages unless item.save
  item
end

puts "# roles"
sys_r01 = save_role name: I18n.t('sys.roles.admin'), permissions: Sys::Role.permission_names
sys_r02 = save_role name: I18n.t('sys.roles.user'), permissions: %w(use_cms use_gws use_webmail)

def save_user(data, only_on_creates = {})
  if item = SS::User.where(uid: data[:uid]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = SS::User.find_or_create_by!(email: data[:email]) do |item|
    item.attributes = data.merge(only_on_creates)
  end
  item
end

puts "# users"
sys = save_user(
  { name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass", kana: "システムカンリシャ" },
  { group_ids: [g11.id], sys_role_ids: [sys_r01.id], organization_id: g00.id, organization_uid: "0000001", deletion_lock_state: "locked" }
)
adm = save_user(
  { name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass", kana: "サイトカンリシャ " },
  { group_ids: [g11.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000000", deletion_lock_state: "locked" }
)
u01 = save_user(
  { name: "鈴木 茂", uid: "user1", email: "user1@example.jp", in_password: "pass", kana: "スズキ シゲル" },
  { group_ids: [g11.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000002" }
)
u02 = save_user(
  { name: "渡辺 和子", uid: "user2", email: "user2@example.jp", in_password: "pass", kana: "ワタナベ カズコ" },
  { group_ids: [g21.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000003" }
)
u03 = save_user(
  { name: "斎藤　拓也", uid: "user3", email: "user3@example.jp", in_password: "pass", kana: "サイトウ　タクヤ" },
  { group_ids: [g12.id, g22.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000005" }
)
u04 = save_user(
  { name: "伊藤 幸子", uid: "user4", email: "user4@example.jp", in_password: "pass", kana: "イトウ サチコ" },
  { group_ids: [g21.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000006" }
)
u05 = save_user(
  { name: "高橋 清", uid: "user5", email: "user5@example.jp", in_password: "pass", kana: "タカハシ キヨシ" },
  { group_ids: [g12.id], sys_role_ids: [sys_r02.id], organization_id: g00.id, organization_uid: "0000007" }
)

sys.add_to_set(group_ids: [g11.id], sys_role_ids: [sys_r01.id])
adm.add_to_set(group_ids: [g11.id], sys_role_ids: [sys_r02.id])
u01.add_to_set(group_ids: [g11.id], sys_role_ids: [sys_r02.id])
u02.add_to_set(group_ids: [g21.id], sys_role_ids: [sys_r02.id])
u03.add_to_set(group_ids: [g12.id, g22.id], sys_role_ids: [sys_r02.id])
u04.add_to_set(group_ids: [g21.id], sys_role_ids: [sys_r02.id])
u05.add_to_set(group_ids: [g12.id], sys_role_ids: [sys_r02.id])

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

def load_gws_permissions(path)
  File.read("#{Rails.root}/db/seeds/#{path}").split(/\r?\n/).map(&:strip) & Gws::Role.permission_names
end

puts "# gws roles"
gws_r01 = save_gws_role name: I18n.t('gws.roles.admin'), site_id: g00.id, permissions: Gws::Role.permission_names, permission_level: 3
gws_r02 = save_gws_role name: I18n.t('gws.roles.user'), site_id: g00.id, permissions: load_gws_permissions('gws/roles/user_permissions.txt'), permission_level: 1
gws_r03 = save_gws_role name: '部課長', site_id: g00.id, permissions: load_gws_permissions('gws/roles/manager_permissions.txt'), permission_level: 1

Gws::User.find_by(uid: "sys").add_to_set(gws_role_ids: gws_r01.id)
Gws::User.find_by(uid: "admin").add_to_set(gws_role_ids: gws_r01.id)
Gws::User.find_by(uid: "user1").add_to_set(gws_role_ids: gws_r02.id)
Gws::User.find_by(uid: "user2").add_to_set(gws_role_ids: gws_r02.id)
Gws::User.find_by(uid: "user3").add_to_set(gws_role_ids: gws_r03.id)
Gws::User.find_by(uid: "user4").add_to_set(gws_role_ids: gws_r03.id)
Gws::User.find_by(uid: "user5").add_to_set(gws_role_ids: gws_r02.id)


## -------------------------------------
# Webmail Roles

def save_webmail_role(data)
  if item = Webmail::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Webmail::Role.new(data)
  item.save
  item
end

def load_webmail_permissions(path)
  File.read("#{Rails.root}/db/seeds/#{path}").split(/\r?\n/).map(&:strip) & Webmail::Role.permission_names
end

puts "# webmail roles"
webmail_r01 = save_webmail_role(
  name: I18n.t('webmail.roles.admin'), permissions: Webmail::Role.permission_names, permission_level: 3
)
webmail_r02 = save_webmail_role(
  name: I18n.t('webmail.roles.user'), permissions: load_webmail_permissions('webmail/roles/user_permissions.txt'), permission_level: 1
)

Webmail::User.find_by(uid: "sys").add_to_set(webmail_role_ids: webmail_r01.id)
Webmail::User.find_by(uid: "admin").add_to_set(webmail_role_ids: webmail_r01.id)
Webmail::User.find_by(uid: "user1").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user2").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user3").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user4").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user5").add_to_set(webmail_role_ids: webmail_r02.id)

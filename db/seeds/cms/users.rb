# --------------------------------------
# Require
# inherit params: @site

require "#{Rails.root}/db/seeds/ss/users"

@group = Cms::Group.find_by name: 'シラサギ市'
@site.add_to_set group_ids: @group.id

# --------------------------------------
# Seed

def save_role(data)
  if item = Cms::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Cms::Role.new(data)
  item.save
  item
end

puts "# roles"
user_permissions = Cms::Role.permission_names.select {|n| n =~ /_(private|other)_/ }
r01 = save_role name: I18n.t('cms.roles.admin'), site_id: @site.id, permissions: Cms::Role.permission_names, permission_level: 3
r02 = save_role name: I18n.t('cms.roles.user'), site_id: @site.id, permissions: user_permissions, permission_level: 1

Cms::User.find_by(uid: "sys").add_to_set(cms_role_ids: r01.id)
Cms::User.find_by(uid: "admin").add_to_set(cms_role_ids: r01.id)
Cms::User.find_by(uid: "user1").add_to_set(cms_role_ids: r02.id)
Cms::User.find_by(uid: "user2").add_to_set(cms_role_ids: r02.id)
Cms::User.find_by(uid: "user3").add_to_set(cms_role_ids: r02.id)

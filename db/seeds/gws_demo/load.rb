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

## -------------------------------------
puts "# max file size"

def save_max_file_size(data)
  # 100 MiB
  data = {size: 100 * 1_024 * 1_024}.merge(data)

  puts data[:name]
  cond = { name: data[:name] }

  item = SS::MaxFileSize.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_max_file_size name: '画像ファイル', extensions: %w(gif png jpg jpeg bmp), order: 1, state: 'enabled'
save_max_file_size name: '音声ファイル', extensions: %w(wav wma mp3 ogg), order: 2, state: 'enabled'
save_max_file_size name: '動画ファイル', extensions: %w(wmv avi mpeg mpg flv mp4), order: 3, state: 'enabled'
save_max_file_size name: 'Microsoft Office', extensions: %w(doc docx ppt pptx xls xlsx), order: 4, state: 'enabled'
save_max_file_size name: 'PDF', extensions: %w(pdf), order: 5, state: 'enabled'
save_max_file_size name: 'その他', extensions: %w(*), order: 9999, state: 'enabled'

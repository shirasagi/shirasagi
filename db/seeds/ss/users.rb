# --------------------------------------
# Seed

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
g00 = save_group name: "シラサギ市", order: 10
g10 = save_group name: "シラサギ市/企画政策部", order: 20
g11 = save_group name: "シラサギ市/企画政策部/政策課", order: 30
g12 = save_group name: "シラサギ市/企画政策部/広報課", order: 40
g20 = save_group name: "シラサギ市/危機管理部", order: 50
g21 = save_group name: "シラサギ市/危機管理部/管理課", order: 60
g22 = save_group name: "シラサギ市/危機管理部/防災課", order: 70

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
sys = save_user name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass", group_ids: [g11.id]
adm = save_user name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass", group_ids: [g11.id]
u01 = save_user name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass", group_ids: [g11.id]
u02 = save_user name: "一般ユーザー2", uid: "user2", email: "user2@example.jp", in_password: "pass", group_ids: [g21.id]
u03 = save_user name: "一般ユーザー3", uid: "user3", email: "user3@example.jp", in_password: "pass", group_ids: [g12.id, g22.id]

sys.add_to_set group_ids: [g11.id]
adm.add_to_set group_ids: [g11.id]
u01.add_to_set group_ids: [g11.id]
u02.add_to_set group_ids: [g21.id]
u03.add_to_set group_ids: [g12.id, g22.id]

#
# Webmail demo
#

domain = 'demo.ss-proj.org'
uids = %w(sys admin user1 user2 user3 user4 user5)
users = SS::User.where(:uid.in => uids)

def u(uid)
  SS::User.find_by(uid: uid)
end

def create_item(model, user, data)
  puts data[:name]
  cond = { user_id: user.id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

# --------------------------------------
puts "# Convet users"

users.each do |user|
  user.email = user.email.sub(/@.*/, "@#{domain}")
  #user.imap_account = ''
  #user.in_imap_password = 'pass'
  user.save!

  puts "#{user.name}: #{user.email}"
end

# --------------------------------------
puts "# Create group"

def create_group(user, data)
  create_item(Webmail::AddressGroup, user, data)
end

@address_group = [
  create_group(u('sys'), name: '株式会社シラサギ', order: 20),
  create_group(u('sys'), name: '地域振興イベント', order: 10),
]

# --------------------------------------
puts "# Create addresses"

# users.each do |user|
#   others = uids.select { |c| c != user.uid }
#   others.each do |uid|
#     other = SS::User.find_by(uid: uid)
#     cond = { user_id: user.id, name: other.name, email: other.email }
#     Webmail::Address.find_or_create_by(cond)
#   end
#
#   puts "#{user.name}: [" + others.join(',') + "]"
# end

def create_address(user, data)
  create_item(Webmail::Address, user, data)
end

create_address(
  u('sys'), address_group_id: @address_group[1].id, name: "サイト管理者", kana: "サイトカンリシャ",
  email: 'admin@demo.ss-proj.org'
)
# create_address(u('sys'), address_group_id: @address_group[0].id, name: "システム管理者", kana: "システムカンリシャ",
#                email: 'sys@demo.ss-proj.org', user_id: '2'
# )
create_address(
  u('sys'), address_group_id: @address_group[0].id, name: "伊藤　幸子", kana: "イトウ　サチコ",
  email: 'user4@demo.ss-proj.org'
)
create_address(
  u('sys'), address_group_id: @address_group[1].id, name: "斉藤　拓也", kana: "サイトウ　タクヤ",
  email: 'user3@demo.ss-proj.org'
)
create_address(
  u('sys'), address_group_id: @address_group[0].id, name: "渡辺　和子", kana: "ワタナベ　カズコ",
  email: 'user２@demo.ss-proj.org'
)
create_address(
  u('sys'), address_group_id: @address_group[1].id, name: "鈴木　茂", kana: "スズキ　シゲル",
  email: 'user1@demo.ss-proj.org'
)
create_address(
  u('sys'), address_group_id: @address_group[1].id, name: "高橋　清", kana: "タカハシ　キヨシ",
  email: 'user5@demo.ss-proj.org'
)
create_address(
  u('sys'), address_group_id: @address_group[0].id, name: "黒鷺　晋三", kana: "クロサギ　シンゾウ",
  email: 'kurosagi@example.jp', company: '株式会社シラサギ', tel: '080-0000-0001'
)
create_address(
  u('sys'), address_group_id: @address_group[0].id, name: "白鷺　次郎", kana: "シロサギ　ジロウ",
  email: 'shirosagi@example.jp', company: '株式会社シラサギ', tel: '080-0000-0000', title: '代表取締役社長'
)

# --------------------------------------
puts "# Create signatures"

users.each do |user|
  cond = { user_id: user.id, name: 'Default Signature', default: 'enabled' }
  item = Webmail::Signature.find_or_create_by(cond)
  item.text = ("=" * 30) + "\n#{user.name} <#{user.email}>"
  item.save

  puts "#{user.name}: #{item.name}"

end

# --------------------------------------

puts "#Create filters"

def create_filters(user, data)
  create_item(Webmail::Filter, user, data)
end

@create_filtes = [
  create_filters(
    u("sys"), name: '広報シラサギ', state: 'enabled', order: '10',
    conditions: [
      {field: "subject", operator: "include", value: "広報シラサギ"},
      {field: "subject", operator: "include", value: "広報誌"},
      {field: "subject", operator: "include", value: "シラサギ印刷"}],
    action: 'move', mailbox: '&XoNYMTC3MOkwtTCu-',
    host: 'localhost', account: 'user3@demo.ss-proj.org', conjunction: 'or'
  )
]

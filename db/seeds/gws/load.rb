# --------------------------------------
# Require

require "#{Rails.root}/db/seeds/ss/users"
@site = Gws::Group.where(name: 'シラサギ市').first

## -------------------------------------
# Prepare

@users = [
  Gws::User.find_by(uid: "admin"),
  Gws::User.find_by(uid: "user1"),
  Gws::User.find_by(uid: "user2"),
  Gws::User.find_by(uid: "user3")
]

@today = Time.zone.today
@today_ym = @today.strftime('%Y-%m')

## -------------------------------------
# Role

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
puts "# notice"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Notice.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

create name: "お知らせです。", text: ("お知らせです。\n" * 10)
create name: "重要なお知らせです。", text: ("重要なお知らせです。\n" * 10), severity: 'high'

## -------------------------------------
puts "# link"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Link.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

create name: "オープンソース", html: %(<a href="http://ss-proj.org/">SHIRASAGI</a>)

## -------------------------------------
puts "# facility/category"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Facility::Category.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@fc_cate = [
  create(name: "会議室", order: 1),
  create(name: "公用車", order: 2)
]

## -------------------------------------
puts "# facility/item"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Facility::Item.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@fc_item = [
  create(name: "会議室101", order: 1, category_id: @fc_cate[0].id),
  create(name: "会議室102", order: 2, category_id: @fc_cate[0].id),
  create(name: "乗用車1", order: 10, category_id: @fc_cate[1].id),
  create(name: "乗用車2", order: 11, category_id: @fc_cate[1].id)
]

## -------------------------------------
puts "# schedule/category"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Gws::Schedule::Category.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@sc_cate = [
  create(name: "会議", color: "#002288"),
  create(name: "出張", color: "#EE00DD"),
  create(name: "休暇", color: "#CCCCCC")
]

## -------------------------------------
puts "# schedule/plan"

def create(data)
  #puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Schedule::Plan.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

base_date = Date.parse("#{@today_ym}-01")

puts "予定1..50"
1.upto(50) do |i|
  params = {
    name: "予定#{i}",
    member_ids: @users.sample(2).map(&:id),
    category_id: @sc_cate.sample.id
  }
  date = base_date + (i * 3).days
  if i.odd?
    params.merge! start_at: date.strftime('%Y-%m-%d 10:00'),
                  end_at: date.strftime('%Y-%m-%d 11:00'),
                  facility_ids: [@fc_item.sample.id]
  else
    params.merge! start_on: date.strftime('%Y-%m-%d'),
                  end_on: (date + 1.day).strftime('%Y-%m-%d'),
                  allday: 'allday'
  end
  create params
end

create name: "繰り返し予定", member_ids: @users.map(&:id),
       start_at: base_date.strftime('%Y-%m-%d 14:00'),
       end_at: base_date.strftime('%Y-%m-%d 16:00'),
       repeat_type: 'weekly', interval: 1, wdays: [],
       repeat_start: base_date.strftime('%Y-%m-%d'),
       repeat_end: (base_date + 5.months).strftime('%Y-%m-%d')

## -------------------------------------
puts "# board/category"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Category.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

@bd_cate = [
  create(name: "告知", color: "#002288", order: 1),
  create(name: "質問", color: "#EE00DD", order: 2),
  create(name: "募集", color: "#CCCCCC", order: 3)
]

## -------------------------------------
puts "# board/post"

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Topic.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

@bd_topic = [
  create(name: "スレッド形式トピック", text: "内容です。", mode: "thread", category_ids: [@bd_cate[0].id]),
  create(name: "ツリー形式トピック", text: "内容です。", mode: "tree", category_ids: [@bd_cate[1].id])
]

def create(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Post.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

create(name: "返信1", text: "内容です。", topic_id: @bd_topic[0].id, parent_id: @bd_topic[0].id)
res = create(name: "返信2", text: "内容です。", topic_id: @bd_topic[1].id, parent_id: @bd_topic[1].id)
res = create(name: "返信3", text: "内容です。", topic_id: @bd_topic[1].id, parent_id: res.id)

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

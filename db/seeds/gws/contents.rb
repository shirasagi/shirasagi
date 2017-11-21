## -------------------------------------

@site = Gws::Group.where(name: SS::Db::Seed.site_name).first

@users = [
  Gws::User.find_by(uid: "admin"),
  Gws::User.find_by(uid: "user1"),
  Gws::User.find_by(uid: "user2"),
  Gws::User.find_by(uid: "user3")
]

@today = Time.zone.today
@today_ym = @today.strftime('%Y-%m')

## -------------------------------------
puts "# staff_record"

def create_staff_record_year(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::StaffRecord::Year.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

def create_staff_record_group(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], name: data[:name] }
  item = Gws::StaffRecord::Group.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

def create_staff_record_user(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], section_name: data[:section_name], name: data[:name] }
  item = Gws::StaffRecord::User.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

[
  create_staff_record_year(name: "平成27年度", code: 2015, start_date: '2015/4/1', close_date: '2016/3/31'),
  create_staff_record_year(name: "平成28年度", code: 2016, start_date: '2016/4/1', close_date: '2017/3/31'),
  create_staff_record_year(name: "平成29年度", code: 2017, start_date: '2017/4/1', close_date: '2018/3/31')
].each do |year|
  sections = [
    create_staff_record_group(year_id: year.id, name: "政策課", order: 1, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: "広報課", order: 2, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: "管理課", order: 3, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: "防災課", order: 4, seating_chart_url: ''),
  ]

  create_staff_record_user(year_id: year.id, section_name: sections[0].name,
    name: "佐藤 博", kana: 'サトウ ヒロシ', code: '101', charge_name: '庶務担当', title_name: '課長',
    divide_duties: "出張・研修関係\n文書収受",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[0].name,
    name: "鈴木 茂", kana: 'スズキ シゲル', code: '102', charge_name: '庶務担当',
    divide_duties: "出張・研修関係\n文書収受",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[1].name,
    name: "高橋 清", kana: 'タカハシ キヨシ', code: '103', charge_name: '庶務担当',
    divide_duties: "郵便発送\n掲示物",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[1].name,
    name: "田中 進", kana: 'タナカ ススム', code: '104', charge_name: '庶務担当',
    divide_duties: "郵便発送\n掲示物",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[2].name,
    name: "伊藤 幸子", kana: 'イトウ サチコ', code: '201', charge_name: '会計担当', title_name: '課長',
    divide_duties: "予算・決算関係\n営繕関係",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[2].name,
    name: "渡辺 和子", kana: 'ワタナベ カズコ', code: '202', charge_name: '会計担当',
    divide_duties: "安全衛生・環境保全関係\n情報・ネットワーク関係",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[3].name,
    name: "山本 洋子", kana: 'ヤマモト ヒロコ', code: '203', charge_name: '企画調整担当',
    divide_duties: "安全衛生・環境保全関係\n施設、設備の維持管理に関すること",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
  create_staff_record_user(year_id: year.id, section_name: sections[3].name,
    name: "中村 節子", kana: 'ナカムラ セツコ', code: '204', charge_name: '企画調整担当',
    divide_duties: "地域社会との連携に関すること\n防火管理に関すること",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000')
end

## -------------------------------------
puts "# notice"

def create_notice(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Notice.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

create_notice name: "#{@site.name}のお知らせです。", text: ("お知らせです。\n" * 10)
create_notice name: "重要なお知らせです。", text: ("重要なお知らせです。\n" * 10), severity: 'high'

## -------------------------------------
puts "# link"

def create_link(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Link.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

create_link name: "#{@site.name}について", html: %(<a href="http://ss-proj.org/">SHIRASAGI</a>)

## -------------------------------------
puts "# facility/category"

def create_facility_category(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Facility::Category.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@fc_cate = [
  create_facility_category(name: "会議室", order: 1),
  create_facility_category(name: "公用車", order: 2)
]

## -------------------------------------
puts "# facility/item"

def create_facility_item(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Facility::Item.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@fc_item = [
  create_facility_item(name: "会議室101", order: 1, category_id: @fc_cate[0].id),
  create_facility_item(name: "会議室102", order: 2, category_id: @fc_cate[0].id),
  create_facility_item(name: "乗用車1", order: 10, category_id: @fc_cate[1].id),
  create_facility_item(name: "乗用車2", order: 11, category_id: @fc_cate[1].id)
]

## -------------------------------------
puts "# schedule/category"

def create_schedule_category(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Gws::Schedule::Category.find_or_create_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  item.update
  item
end

@sc_cate = [
  create_schedule_category(name: "会議", color: "#002288"),
  create_schedule_category(name: "出張", color: "#EE00DD"),
  create_schedule_category(name: "休暇", color: "#CCCCCC")
]

## -------------------------------------
puts "# schedule/plan"

def create_schedule_plan(data)
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
    name: "#{@site.name}の予定#{i}",
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
  create_schedule_plan params
end

create_schedule_plan name: "繰り返し予定", member_ids: @users.map(&:id),
       start_at: base_date.strftime('%Y-%m-%d 14:00'),
       end_at: base_date.strftime('%Y-%m-%d 16:00'),
       repeat_type: 'weekly', interval: 1, wdays: [],
       repeat_start: base_date.strftime('%Y-%m-%d'),
       repeat_end: (base_date + 5.months).strftime('%Y-%m-%d')

## -------------------------------------
puts "# board/category"

def create_board_category(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Category.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

@bd_cate = [
  create_board_category(name: "告知", color: "#002288", order: 1),
  create_board_category(name: "質問", color: "#EE00DD", order: 2),
  create_board_category(name: "募集", color: "#CCCCCC", order: 3)
]

## -------------------------------------
puts "# board/post"

def create_board_topic(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Topic.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

@bd_topic = [
  create_board_topic(name: "#{@site.name}のスレッド形式トピック", text: "内容です。", mode: "thread", category_ids: [@bd_cate[0].id]),
  create_board_topic(name: "#{@site.name}のツリー形式トピック", text: "内容です。", mode: "tree", category_ids: [@bd_cate[1].id])
]

def create_board_post(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Gws::Board::Post.find_or_initialize_by(cond)
  item.attributes = data.merge(cur_site: @site, cur_user: @users[0])
  puts item.errors.full_messages unless item.save
  item
end

create_board_post(name: "返信1", text: "内容です。", topic_id: @bd_topic[0].id, parent_id: @bd_topic[0].id)
res = create_board_post(name: "返信2", text: "内容です。", topic_id: @bd_topic[1].id, parent_id: @bd_topic[1].id)
res = create_board_post(name: "返信3", text: "内容です。", topic_id: @bd_topic[1].id, parent_id: res.id)

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

## -------------------------------------

@site = Gws::Group.where(name: SS::Db::Seed.site_name).first

def u(uid)
  @users_hash ||= {}
  @users_hash[uid.to_s] ||= Gws::User.find_by(uid: uid)
end

def g(name)
  @groups_hash ||= {}
  @groups_hash[name.to_s] ||= Gws::Group.where(name: /\/#{::Regexp.escape(name)}$/).first
end

@users = %w[admin user1 user2 user3 user4 user5].map { |uid| u(uid) }

@today = Time.zone.today
@today_ym = @today.strftime('%Y-%m')

def create_item(model, data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

def create_column(type, data)
  case type
  when :text
    model = Gws::Column::TextField
  when :text_area
    model = Gws::Column::TextArea
  when :number
    model = Gws::Column::NumberField
  when :date
    model = Gws::Column::DateField
  when :url
    model = Gws::Column::UrlField
  when :checkbox
    model = Gws::Column::CheckBox
  when :radio
    model = Gws::Column::RadioButton
  when :select
    model = Gws::Column::Select
  when :file_upload
    model = Gws::Column::FileUpload
  end
  puts data[:name]
  cond = { site_id: @site._id, form_id: data[:form].id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

## -------------------------------------
puts "# custom_group"

def create_custom_group(data)
  create_item(Gws::CustomGroup, data)
end

@cgroups = [
  create_custom_group(
    name: 'シラサギプロジェクト', member_ids: %w[admin user1 user3].map { |uid| u(uid).id },
    readable_setting_range: 'select',
    readable_group_ids: %w[政策課 広報課].map { |n| g(n).id }
  )
]

## -------------------------------------
puts "# staff_record"

def create_staff_record_year(data)
  create_item(Gws::StaffRecord::Year, data)
end

def create_staff_record_group(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], name: data[:name] }
  item = Gws::StaffRecord::Group.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

def create_staff_record_user(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], section_name: data[:section_name], name: data[:name] }
  item = Gws::StaffRecord::User.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

staff_record_years = [
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
  create_item(Gws::Notice, data)
end

create_notice name: "#{@site.name}のお知らせです。", text: ("お知らせです。\n" * 10)
create_notice name: "重要なお知らせです。", text: ("重要なお知らせです。\n" * 10), severity: 'high'

## -------------------------------------
puts "# link"

def create_link(data)
  create_item(Gws::Link, data)
end

create_link name: "#{@site.name}について", links: [ { name: "SHIRASAGI", url: "http://ss-proj.org/" } ]

## -------------------------------------
puts "# discussion/forum"

def create_discussion_forum(data)
  create_item(Gws::Discussion::Forum, data)
end

@ds_forums = [
  create_discussion_forum(
    name: 'サイト改善プロジェクト', order: 0, member_ids: @users.map(&:id), user_ids: [u('admin').id]
  ),
  create_discussion_forum(
    name: 'シラサギプロジェクト', order: 10, member_custom_group_ids: [@cgroups.first.id], user_ids: [u('admin').id]
  )
]

def create_discussion_topic(data)
  # puts data[:name]
  cond = { site_id: @site._id, forum_id: data[:forum_id], parent_id: data[:parent_id], text: data[:text] }
  item = Gws::Discussion::Topic.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(
    cur_site: @site, cur_user: u('admin'),
    contributor_name: u('admin').long_name,
    contributor_id: u('admin').id,
    contributor_model: "Gws::User"
  )
  puts item.errors.full_messages unless item.save
  item
end

@ds_topics = [
  create_discussion_topic(
    name: 'メインスレッド', text: 'サイト改善プロジェクトのメインスレッドです。', order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id, user_ids: [u('admin').id]
  ),
  create_discussion_topic(
    name: '問い合わせフォームの改善', text: '問い合わせフォームの改善について意見をお願いします。', order: 10,
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id, user_ids: [u('admin').id]
  ),
  create_discussion_topic(
    name: 'メインスレッド', text: 'シラサギプロジェクトのメインスレッドです。', order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[1].id, parent_id: @ds_forums[1].id, user_ids: [u('admin').id]
  ),
]

def create_discussion_post(data)
  # puts data[:name]
  cond = { site_id: @site._id, forum_id: data[:forum_id], parent_id: data[:parent_id], text: data[:text] }
  item = Gws::Discussion::Post.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(
    cur_site: @site, cur_user: u('admin'),
    contributor_name: u('admin').long_name,
    contributor_id: u('admin').id,
    contributor_model: "Gws::User"
  )
  puts item.errors.full_messages unless item.save
  item
end

create_discussion_post(
  name: 'メインスレッド', text: 'シラサギ市のサイト改善を図りたいと思いますので、皆様のご意見をお願いします。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user4'), name: 'メインスレッド', text: '全体的なデザインの見直しを行いたいです。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user5'), name: 'メインスレッド', text: '観光コンンテンツは別途観光サイトを設けたいと思います。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user3'), name: '問い合わせフォームの改善', text: '投稿時に問い合わせ先の課を選択でき、投稿通知が対象課に届くと良いと思います。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[1].id, parent_id: @ds_topics[1].id, user_ids: [u('admin').id]
)
create_discussion_post(
  name: 'メインスレッド', text: 'シラサギの改善要望について議論を交わしたいと思います。',
  forum_id: @ds_forums[1].id, topic_id: @ds_topics[2].id, parent_id: @ds_topics[2].id, user_ids: [u('admin').id]
)

## -------------------------------------
puts "# facility/category"

def create_facility_category(data)
  create_item(Gws::Facility::Category, data)
end

@fc_cate = [
  create_facility_category(name: "会議室", order: 1),
  create_facility_category(name: "公用車", order: 2)
]

## -------------------------------------
puts "# facility/item"

def create_facility_item(data)
  create_item(Gws::Facility::Item, data)
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
  create_item(Gws::Schedule::Category, data)
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
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

base_date = @today.beginning_of_month

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

@sch_plan1 = create_schedule_plan(
  name: 'シラサギ会議', start_at: base_date.strftime('%Y-%m-%d 15:00'), end_at: base_date.strftime('%Y-%m-%d 16:00'),
  repeat_type: 'weekly', interval: 1, repeat_start: base_date, repeat_end: base_date + 1.month, wdays: [3],
  member_ids: [u('admin').id], member_custom_group_ids: [@cgroups[0].id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  readable_member_ids: [u('sys').id]
)

create_schedule_plan(
  name: '定例報告会', start_at: (base_date + 1.day).strftime('%Y-%m-%d 14:00'),
  end_at: (base_date + 1.day).strftime('%Y-%m-%d 16:00'),
  repeat_type: 'weekly', interval: 1, repeat_start: base_date + 1.day, repeat_end: base_date + 1.day + 6.month, wdays: [],
  member_ids: %w[admin user1 user2 user3].map { |uid| u(uid).id },
  readable_setting_range: 'select'
)

create_schedule_plan(
  name: '株式会社シラサギ来社', start_at: (base_date + 2.day).strftime('%Y-%m-%d 10:00'),
  end_at: (base_date + 1.day).strftime('%Y-%m-%d 11:00'),
  member_ids: %w[admin user1].map { |uid| u(uid).id },
  facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
)

@sch_plan2 = create_schedule_plan(
  cur_user: u('user1'), name: '東京出張',
  allday: 'allday', start_on: base_date + 13.day + 9.hours, end_on: base_date + 13.day + 9.hours,
  start_at: base_date + 13.days, end_at: base_date.end_of_day,
  member_ids: %w[user1].map { |uid| u(uid).id },
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  category_id: @sc_cate[1].id
)

## -------------------------------------
puts "# schedule/todo"

def create_schedule_todo(data)
  create_item(Gws::Schedule::Todo, data)
end

create_schedule_todo(
  name: '[サイト改善プロジェクト]要求仕様提出', member_ids:  @users.map(&:id),
  start_at: Time.zone.now + 7.days, end_at: Time.zone.now + 7.days + 1.hour,
  todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id
)

## -------------------------------------
puts "# board/category"

def create_board_category(data)
  create_item(Gws::Board::Category, data)
end

@bd_cate = [
  create_board_category(name: "告知", color: "#002288", order: 10),
  create_board_category(name: "質問", color: "#EE00DD", order: 20),
  create_board_category(name: "募集", color: "#CCCCCC", order: 30)
]

## -------------------------------------
puts "# board/post"

def create_board_topic(data)
  create_item(Gws::Board::Topic, data)
end

@bd_topics = [
  create_board_topic(
    name: "業務説明会を開催します。", text: "シラサギについても業務説明会を開催します。", mode: "thread",
    category_ids: [@bd_cate[0].id]
  ),
  create_board_topic(
    name: "会議室の増設について",
    text: "会議室の利用率が高いので増設を考えています。\n特に希望される内容などあればお願いします。", mode: "tree",
    category_ids: [@bd_cate[1].id]
  )
]

def create_board_post(data)
  create_item(Gws::Board::Post, data)
end

create_board_post(
  cur_user: u('user1'), name: "Re: 業務説明会を開催します。", text: "参加は自由ですか。",
  topic_id: @bd_topics[0].id, parent_id: @bd_topics[0].id
)
res = create_board_post(
  cur_user: u('user1'), name: "Re: 会議室の増設について", text: "政策課フロアに増設いただけると助かります。",
  topic_id: @bd_topics[1].id, parent_id: @bd_topics[1].id
)
res = create_board_post(
  cur_user: u('admin'), name: "Re: Re: 会議室の増設について", text: "検討します。",
  topic_id: @bd_topics[1].id, parent_id: res.id
)

## -------------------------------------
puts "# circular/category"

def create_circular_category(data)
  create_item(Gws::Circular::Category, data)
end

@cr_cate = [
  create_circular_category(name: "必読", color: "#FF0000", order: 10),
  create_circular_category(name: "案内", color: "#09FF00", order: 20)
]

## -------------------------------------
puts "# circular/post"

def create_circular_post(data)
  create_item(Gws::Circular::Post, data)
end

@cr_posts = [
  create_circular_post(
    name: "年末年始休暇について", text: "年末年始の休暇は12月29日から1月3日までとなります。\nお間違えないようお願いします。",
    see_type: "normal", state: 'public', due_date: Time.zone.now.beginning_of_day + 7.days,
    member_ids: %w[sys admin user1 user2 user3 user4 user5].map { |u| u(u).id },
    seen: { u('user2').id.to_s => Time.zone.now, u('user5').id.to_s => Time.zone.now },
    category_ids: [@cr_cate[0].id]
  ),
  create_circular_post(
    name: "システム説明会のお知らせ", text: "システム説明会を開催します。\n万障お繰り合わせの上ご参加願います。",
    see_type: "normal", state: 'public', due_date: Time.zone.now.beginning_of_day + 7.days,
    member_ids: %w[sys admin user1 user3 user5].map { |u| u(u).id },
    seen: { u('admin').id.to_s => Time.zone.now, u('user3').id.to_s => Time.zone.now },
    category_ids: [@cr_cate[1].id])
]

def create_circular_comment(data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id, name: data[:name] }
  item = Gws::Circular::Comment.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user5'), name: "Re: 年末年始休暇について", text: "内容確認しました。"
)
create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user2'), name: "Re: 年末年始休暇について", text: "承知しました。"
)
create_circular_comment(
  post_id: @cr_posts[1].id, cur_user: u('user3'), name: "Re: システム説明会のお知らせ",
  text: "予定があり参加できそうにありません。"
)
create_circular_comment(
  post_id: @cr_posts[1].id, cur_user: u('admin'), name: "Re: システム説明会のお知らせ", text: "参加します。"
)

## -------------------------------------
puts "# faq/category"

def create_faq_category(data)
  create_item(Gws::Faq::Category, data)
end

@faq_cate = [
  create_faq_category(name: "出張", color: "#6FFF00", order: 10),
  create_faq_category(name: "システム操作", color: "#FFF700", order: 20)
]

## -------------------------------------
puts "# faq/topic"

def create_faq_topic(data)
  create_item(Gws::Faq::Topic, data)
end

@faq_topics = [
  create_faq_topic(
    name: '新しいグループウェアアカウントの発行はどうすればいいですか。', text: 'システム管理者にアカウント発行の申請を行ってください。',
    mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[1].id], readable_setting_range: 'public'
  ),
  create_faq_topic(
    name: '出張申請はどのように行いますか。', text: 'ワークフローに「出張申請」がありますので、必要事項を記入し申請してください。',
    mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[0].id], readable_setting_range: 'public'
  )
]

## -------------------------------------
puts "# memo"

## -------------------------------------
puts "# monitor/category"

def create_monitor_category(data)
  create_item(Gws::Monitor::Category, data)
end

@mon_cate = [
  create_monitor_category(name: '設備', color: '#FF4000', order: 10),
  create_monitor_category(name: 'システム操作', color: '#FFF700', order: 20),
  create_monitor_category(name: 'アンケート', color: '#00FFEE', order: 30)
]

## -------------------------------------
puts "# monitor/topic"

def create_monitor_topic(data)
  create_item(Gws::Monitor::Topic, data)
end

@mon_topics = [
  create_monitor_topic(
    cur_user: u('user4'), name: '共有ファイルに登録できるファイル容量および種類',
    due_date: Time.zone.now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: '共有ファイルに登録できるファイル容量および種類の制限を教えてください。', category_ids: [@mon_cate[1].id]
  ),
  create_monitor_topic(
    cur_user: u('user5'), name: '新しい公用車の導入',
    due_date: Time.zone.now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: "公用車の劣化が進んでおり、買い替えを行うことになりました。\n希望車種などがあれば回答をお願いします。",
    category_ids: [@mon_cate[0].id]
  )
]

def create_monitor_post(data)
  create_item(Gws::Monitor::Post, data)
end

create_monitor_post(
  cur_user: u('admin'), name: 'Re: 新しい公用車の導入',
  due_date: @mon_topics[1].due_date,
  topic_id: @mon_topics[1].id, parent_id: @mon_topics[1].id,
  text: '車室の広いものを希望します。'
)

## -------------------------------------
puts "# portal"

## -------------------------------------
puts "# qna/category"

def create_qna_category(data)
  create_item(Gws::Qna::Category, data)
end

@qna_cate = [
  create_qna_category(name: '福利厚生', color: '#0033FF', order: 10),
  create_qna_category(name: '防災', color: '#F700FF', order: 20)
]

## -------------------------------------
puts "# qna/topic"

def create_qna_topic(data)
  create_item(Gws::Qna::Topic, data)
end

qna_topic = create_qna_topic(
  cur_user: u('user3'), name: '火災が起こった場合の広報課からの避難経路を教えてください。',
  text: '火災が起こった場合の広報課からの避難経路を教えてください。', category_ids: [@qna_cate[1].id]
)

## -------------------------------------
puts "# qna/post"

def create_qna_post(data)
  create_item(Gws::Qna::Post, data)
end

create_qna_post(
  name: 'Re: 火災が起こった場合の広報課からの避難経路を教えてください。',
  text: '防災マニュアルに従って避難行動を行ってください。'
)

## -------------------------------------
puts "# report/category"

def create_report_category(data)
  create_item(Gws::Report::Category, data)
end

@rep_cate = [
  create_report_category(name: '議事録', color: '#3300FF', order: 10),
  create_report_category(name: '報告書', color: '#00FF22', order: 20)
]

## -------------------------------------
puts "# report/form"

def create_report_form(data)
  create_item(Gws::Report::Form, data)
end

@rep_forms = [
  create_report_form(
    name: '打ち合わせ議事録', order: 10, state: 'public', memo: '打ち合わせ議事録です。', category_ids: [@rep_cate[0].id]
  ),
  create_report_form(
    name: '出張報告書', order: 20, state: 'public', memo: '出張報告書です。', category_ids: [@rep_cate[1].id]
  )
]

@rep_form0_cols = [
  create_column(
    :text, name: '打ち合わせ場所', order: 10, required: 'required',
    tooltips: '打ち合わせ場所をん入力してください。', input_type: 'text', form: @rep_forms[0]
  ),
  create_column(
    :date, name: '打ち合わせ日', order: 20, required: 'required',
    tooltips: '打ち合わせ日を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :text, name: '打ち合わせ時間', order: 30, required: 'required',
    tooltips: '打ち合わせ時間を入力してください。', input_type: 'text', form: @rep_forms[0]
  ),
  create_column(
    :text_area, name: '参加者', order: 40, required: 'required',
    tooltips: '打ち合わせ参加者を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :text_area, name: '打ち合わせ内容', order: 50, required: 'required',
    tooltips: '打ち合わせ内容を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :file_upload, name: '添付ファイル', order: 60, required: 'optional',
    tooltips: '関連資料があればファイルをアップロードしてください。', upload_file_count: 5, form: @rep_forms[0]
  )
]

@rep_form1_cols = [
  create_column(
    :text, name: '出張先', order: 10, required: 'required', input_type: 'text', form: @rep_forms[1]
  ),
  create_column(
    :date, name: '出張日', order: 20, required: 'required', form: @rep_forms[1]
  ),
  create_column(
    :text_area, name: '報告内容', order: 30, required: 'required', form: @rep_forms[1]
  )
]

## -------------------------------------
puts "# report/file"

def create_report_file(data)
  create_item(Gws::Report::File, data)
end

create_report_file(
  cur_form: @rep_forms[0], in_skip_notification_mail: true, name: '第1回シラサギ会議打ち合わせ議事録', state: 'public',
  member_ids: %w(admin user1 user3).map { |u| u(u).id }, schedule_ids: [@sch_plan1.id.to_s],
  readable_setting_range: 'select', readable_group_ids: %w[政策課 広報課].map { |n| g(n).id },
  column_values: [
    @rep_form0_cols[0].serialize_value('会議室101'),
    @rep_form0_cols[1].serialize_value((@today - 7.days).strftime('%Y/%m/%d')),
    @rep_form0_cols[2].serialize_value('15:00〜16:00'),
    @rep_form0_cols[3].serialize_value("広報課　斎藤課長\n政策課　白鷺係長"),
    @rep_form0_cols[4].serialize_value("シラサギプロジェクトについての会議を行った。\nかれこれしかじか"),
    @rep_form0_cols[5].serialize_value([])
  ]
)

create_report_file(
  cur_user: u('user1'), cur_form: @rep_forms[1], in_skip_notification_mail: true, name: '東京出張報告', state: 'public',
  member_ids: @users.map(&:id), schedule_ids: [@sch_plan2.id.to_s],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  column_values: [
    @rep_form1_cols[0].serialize_value('東京都庁'),
    @rep_form1_cols[1].serialize_value((@today - 3.days).strftime('%Y/%m/%d')),
    @rep_form1_cols[2].serialize_value("東京都庁で会議のため、出張しました。\nかれこれしかじか。")
  ]
)

## -------------------------------------
puts "# share/category"

def create_share_category(data)
  create_item(Gws::Share::Category, data)
end

@sh_cate = [
  create_share_category(name: 'パンフレット', color: '#A600FF', order: 10),
  create_share_category(name: '写真', color: '#0011FF', order: 20),
  create_share_category(name: '申請書', color: '#11FF00', order: 30),
  create_share_category(name: '資料', color: '#FFEE00', order: 40),
]

## -------------------------------------
puts "# share/folder"

def create_share_folder(data)
  create_item(Gws::Share::Folder, data)
end

@sh_folders = [
  create_share_folder(name: '講習会資料', order: 10),
  create_share_folder(name: '事業パンフレット', order: 20),
  create_share_folder(name: 'イベント写真', order: 30),
  create_share_folder(name: '座席表', order: 50),
]

## -------------------------------------
puts "# share/file"

def create_share_file(data)
  create_item(Gws::Share::File, data)
end

@sh_files = []
Fs::UploadedFile.create_from_file(Rails.root.join('db/seeds/gws/files/file.pdf'), filename: 'file.pdf', content_type: 'application/pdf') do |f|
  @sh_files << create_share_file(in_file: f, name: 'file.pdf', folder_id: @sh_folders[0].id, category_ids: [@sh_cate[3].id])
end
Fs::UploadedFile.create_from_file(Rails.root.join('db/seeds/gws/files/kikakuseisaku.pdf')) do |f|
  @sh_files << create_share_file(in_file: f, name: 'kikakuseisaku.pdf', folder_id: @sh_folders[3].id)
end

@sh_folders.each(&:update_folder_descendants_file_info)

## -------------------------------------
puts "# shared_address/group"

def create_shared_address_group(data)
  create_item(Gws::SharedAddress::Group, data)
end

create_shared_address_group(name: '株式会社シラサギ', order: 10)

## -------------------------------------
puts "# shared_address/address"

def create_shared_address_address(data)
  create_item(Gws::SharedAddress::Address, data)
end

create_shared_address_address(
  name: '白鷺　二郎', kana: 'シラサギ　ジロウ', company: '株式会社シラサギ', title: '代表取締役社長',
  tel: '080-0000-0000', email: 'shirasagi@example.jp'
)
create_shared_address_address(
  name: '黒鷺　晋三', kana: 'クロサギ　シンゾウ', company: '株式会社シラサギ',
  tel: '080-0000-0001', email: 'kurosagi@example.jp'
)

## -------------------------------------
puts "# user_form"

def create_user_form(data)
  # puts data[:name]
  cond = { site_id: @site._id }
  item = Gws::UserForm.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

def create_user_form_data(data)
  # puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id }
  item = Gws::UserFormData.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

user_form = create_user_form(state: 'public')

user_form_columns = [
  create_column(
    :select, form: user_form, name: '性別', order: 10, required: 'optional',
    tooltips: '性別を選択してください。', select_options: %w(男性 女性)
  ),
  create_column(
    :date, form: user_form, name: '生年月日', order: 20, required: 'optional',
    tooltips: '生年月日を入力してください。'
  ),
  create_column(
    :text, form: user_form, name: '個人携帯電話', order: 30, required: 'optional', input_type: 'tel',
    tooltips: '個人所有の携帯電話番号を入力してください。', place_holder: '090-0000-0000',
    additional_attr: 'pattern="\d{2,4}-\d{3,4}-\d{3,4}"'
  )
]

create_user_form_data(cur_user: u('sys'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1976/12/06'),
  user_form_columns[2].serialize_value('090-0000-0000'),
])
create_user_form_data(cur_user: u('admin'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1980/08/24'),
  user_form_columns[2].serialize_value('090-0000-0001'),
])
create_user_form_data(cur_user: u('user1'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1982/06/21'),
  user_form_columns[2].serialize_value('090-0000-0002'),
])
create_user_form_data(cur_user: u('user2'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1979/10/04'),
  user_form_columns[2].serialize_value('090-0000-0004'),
])
create_user_form_data(cur_user: u('user3'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1990/08/14'),
  user_form_columns[2].serialize_value('090-0000-0005'),
])
create_user_form_data(cur_user: u('user4'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1967/02/20'),
  user_form_columns[2].serialize_value('090-0000-0006'),
])
create_user_form_data(cur_user: u('user5'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1992/03/13'),
  user_form_columns[2].serialize_value('090-0000-0007'),
])

## -------------------------------------
puts "# user_title"

def create_user_title(data)
  puts data[:name]
  cond = { group_id: @site._id, name: data[:name] }
  item = Gws::UserTitle.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

user_titles = [
  create_user_title(name: '部長', order: 10),
  create_user_title(name: '課長', order: 20),
  create_user_title(name: '係長', order: 30),
  create_user_title(name: '主任', order: 40)
]

u('sys').add_to_set(title_ids: [user_titles[1].id])
u('admin').add_to_set(title_ids: [user_titles[0].id])
u('user2').add_to_set(title_ids: [user_titles[3].id])
u('user3').add_to_set(title_ids: [user_titles[1].id])
u('user4').add_to_set(title_ids: [user_titles[1].id])

## -------------------------------------
puts "# workflow/form"

def create_workflow_form(data)
  create_item(Gws::Workflow::Form, data)
end

@wf_forms = [
  create_workflow_form(name: '出張申請', order: 10, state: 'public', memo: '出張申請です。'),
  create_workflow_form(name: '稟議書', order: 20, state: 'public', memo: '稟議書です。')
]

@wf_form0_cols = [
  create_column(
    :text, form: @wf_forms[0], name: '出張期間', order: 10, required: 'required',
    tooltips: '出張期間を入力してください。', input_type: 'text'
  ),
  create_column(:text, form: @wf_forms[0], name: '出張先', order: 20, required: 'required', input_type: 'text'),
  create_column(:text, form: @wf_forms[0], name: '目的', order: 30, required: 'required', input_type: 'text'),
  create_column(
    :number, form: @wf_forms[0], name: '必要経費', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
  create_column(:text_area, form: @wf_forms[0], name: '詳細', order: 50, required: 'required'),
]

@wf_form1_cols = [
  create_column(
    :text_area, form: @wf_forms[1], name: '起案内容', order: 10, required: 'required',
    tooltips: '起案内容の詳細説明を入力してください。'
  ),
  create_column(
    :text, form: @wf_forms[1], name: '時期', order: 20, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :text, form: @wf_forms[1], name: '委託行者', order: 30, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :number, form: @wf_forms[1], name: '金額', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
]

## -------------------------------------
puts "# workflow/file"

def create_workflow_file(data)
  create_item(Gws::Workflow::File, data)
end

create_workflow_file(
  cur_user: u('user1'), cur_form: @wf_forms[0], name: '東京出張申請', state: 'closed',
  readable_setting_range: 'select', readable_group_ids: %w[政策課].map { |n| g(n).id },
  workflow_user_id: u('user1').id, workflow_state: 'request', workflow_comment: '東京出張を申請します。',
  workflow_approvers: [
    { 'level' => 1, 'user_id' => u('admin').id, 'editable' => '', 'state' => 'request', 'comment' => ''},
    { 'level' => 2, 'user_id' => u('sys').id, 'editable' => '', 'state' => 'pending', 'comment' => ''}
  ], workflow_required_counts: [false, false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2017/12/14~2017/12/15'),
    @wf_form0_cols[1].serialize_value('東京都庁'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('50000'),
    @wf_form0_cols[4].serialize_value("会議のため、東京都庁に出張します。\r\n飛行機での移動となります。"),
  ]
)

create_workflow_file(
  cur_user: u('user5'), cur_form: @wf_forms[1], name: 'パソコンの購入', state: 'closed',
  readable_setting_range: 'select', readable_group_ids: %w[広報課].map { |n| g(n).id },
  workflow_user_id: u('user5').id, workflow_state: 'request', workflow_comment: 'パソコン購入の稟議です。',
  workflow_approvers: [
    { 'level' => 1, 'user_id' => u('user3').id, 'editable' => '', 'state' => 'request', 'comment' => ''},
    { 'level' => 2, 'user_id' => u('sys').id, 'editable' => '', 'state' => 'pending', 'comment' => ''}
  ], workflow_required_counts: [false, false],
  column_values: [
    @wf_form1_cols[0].serialize_value('サポート期間が切れるため、新たなパソコン買い替えを行いたいと思います。'),
    @wf_form1_cols[1].serialize_value('2018年1月'),
    @wf_form1_cols[2].serialize_value('株式会社シラサギ'),
    @wf_form1_cols[3].serialize_value('100000'),
  ]
)

## -------------------------------------
puts "# bookmark"

def create_bookmark(data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id, name: data[:name] }
  item = Gws::Bookmark.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

create_bookmark(cur_user: u('sys'), name: @faq_topics[0].name, url: "/.g#{@site.id}/faq/topics/#{@faq_topics[0].id}", bookmark_model: 'faq')
create_bookmark(cur_user: u('sys'), name: '企画政策課座席表', url: "/.g#{@site.id}/share/folder-#{@sh_files[1].folder_id}/files/#{@sh_files[1].id}", bookmark_model: 'share')
create_bookmark(cur_user: u('sys'), name: 'SHIRASAGI公式サイト', url: 'http://www.ss-proj.org/', bookmark_model: 'other')

create_bookmark(cur_user: u('admin'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('admin'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[1].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('admin'), name: @cr_posts[1].name, url: "/.g#{@site.id}/circular/admins/#{@cr_posts[1].id}", bookmark_model: 'circular')

create_bookmark(cur_user: u('user1'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('user1'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[1].id}/topics", bookmark_model: 'discussion')

create_bookmark(cur_user: u('user2'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('user2'), name: @sh_files[0].name, url: "/.g#{@site.id}/share/folder-#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}", bookmark_model: 'share')

create_bookmark(cur_user: u('user3'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('user3'), name: @mon_topics[0].name, url: "/.g1/monitor/topics/#{@mon_topics[0].id}", bookmark_model: 'monitor')

create_bookmark(cur_user: u('user4'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('user4'), name: @bd_topics[0].name, url: "/.g#{@site.id}/board/topics/#{@bd_topics[0].id}", bookmark_model: 'board')

create_bookmark(cur_user: u('user5'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics", bookmark_model: 'discussion')
create_bookmark(cur_user: u('user5'), name: @bd_topics[1].name, url: "/.g#{@site.id}/board/topics/#{@bd_topics[1].id}", bookmark_model: 'board')

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

## -------------------------------------

@site = Gws::Group.where(name: SS::Db::Seed.site_name).first

def u(uid)
  @users_hash ||= {}
  @users_hash[uid.to_s] ||= Gws::User.find_by(uid: uid)
end

def g(name)
  @groups_hash ||= {}
  @groups_hash[name.to_s] ||= Gws::Group.find_by(name: name)
end

@users = %w[admin user1 user2 user3 user4 user5].map { |uid| u(uid) }

@today = Time.zone.today
@today_ym = @today.strftime('%Y-%m')

def create_item(model, data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

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
  puts item.errors.full_messages unless item.save
  item
end

def create_staff_record_user(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], section_name: data[:section_name], name: data[:name] }
  item = Gws::StaffRecord::User.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
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

create_link name: "#{@site.name}について", html: %(<a href="http://ss-proj.org/">SHIRASAGI</a>)

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

@bd_topic = [
  create_board_topic(
    name: "業務説明会を開催します。", text: "シラサギについても業務説明会を開催します。", mode: "thread",
    category_ids: [@bd_cate[0].id]
  ),
  create_board_topic(
    name: "会議室の増設について",
    text: "会議室の利用率が高いので増設を考えています。\r\n特に希望される内容などあればお願いします。", mode: "tree",
    category_ids: [@bd_cate[1].id]
  )
]

def create_board_post(data)
  create_item(Gws::Board::Post, data)
end

create_board_post(cur_user: u('user1'), name: "Re: 業務説明会を開催します。", text: "参加は自由ですか。", topic_id: @bd_topic[0].id, parent_id: @bd_topic[0].id)
res = create_board_post(cur_user: u('sys'), name: "Re: 会議室の増設について", text: "政策課フロアに増設いただけると助かります。", topic_id: @bd_topic[1].id, parent_id: @bd_topic[1].id)
res = create_board_post(cur_user: u('user1'), name: "Re: Re: 会議室の増設について", text: "検討します。", topic_id: @bd_topic[1].id, parent_id: res.id)

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
    name: "年末年始休暇について", text: "年末年始の休暇は12月29日から1月3日までとなります。\r\nお間違えないようお願いします。",
    see_type: "normal", state: 'public', due_date: Time.zone.now.beginning_of_day + 7.days,
    member_ids: %w[sys admin user1 user2 user3 user4 user5].map { |u| u(u).id },
    seen: { u('user2').id.to_s => Time.zone.now, u('user5').id.to_s => Time.zone.now },
    category_ids: [@cr_cate[0].id]
  ),
  create_circular_post(
    name: "システム説明会のお知らせ", text: "システム説明会を開催します。\r\n万障お繰り合わせの上ご参加願います。",
    see_type: "normal", state: 'public', due_date: Time.zone.now.beginning_of_day + 7.days,
    member_ids: %w[sys admin user1 user3 user5].map { |u| u(u).id },
    seen: { u('admin').id.to_s => Time.zone.now, u('user3').id.to_s => Time.zone.now },
    category_ids: [@cr_cate[1].id])
]

def create_circular_comment(data)
  create_item(Gws::Circular::Comment, data)
end

create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user5'), name: "Re: 年末年始休暇について", text: "内容確認しました。"
)
create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user2'), name: "Re: 年末年始休暇について", text: "承知しました。"
)
create_circular_comment(
  post_id: @cr_posts[2].id, cur_user: u('user3'), name: "Re: システム説明会のお知らせ", text: "予定があり参加できそうにありません。"
)
create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('admin'), name: "Re: システム説明会のお知らせ", text: "参加します。"
)

## -------------------------------------
puts "# discussion/forum"

def create_discussion_forum(data)
  create_item(Gws::Discussion::Forum, data)
end

@ds_forums = [
  create_discussion_forum(
    name: 'サイト改善プロジェクト', depth: 1,
    readable_setting_range: 'select', readable_member_ids: @users.map(&:id)
  ),
  create_discussion_forum(
    name: 'シラサギプロジェクト', depth: 1,
    readable_setting_range: 'select', readable_group_ids: [g('シラサギ市/企画政策部/政策課').id]
  )
]

def create_discussion_topic(data)
  create_item(Gws::Discussion::Topic, data)
end

@ds_topics = [
  create_discussion_topic(
    name: 'メインスレッド', text: 'サイト改善プロジェクトのメインスレッドです。', depth: 2, order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id
  ),
  create_discussion_topic(
    name: '問い合わせフォームの改善', text: '問い合わせフォームの改善について意見をお願いします。', depth: 2, order: 10,
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id
  ),
  create_discussion_topic(
    name: 'メインスレッド', text: 'シラサギプロジェクトのメインスレッドです。', depth: 2, order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[1].id, parent_id: @ds_forums[1].id
  ),
]

def create_discussion_post(data)
  create_item(Gws::Discussion::Post, data)
end

create_discussion_post(
  name: 'メインスレッド', text: 'シラサギ市のサイト改善を図りたいと思いますので、皆様のご意見をお願いします。', depth: 3,
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id
)
create_discussion_post(
  cur_user: u('user4'), name: 'メインスレッド', text: '全体的なデザインの見直しを行いたいです。', depth: 3,
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id
)
create_discussion_post(
  cur_user: u('user5'), name: 'メインスレッド', text: '観光コンンテンツは別途観光サイトを設けたいと思います。', depth: 3,
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id
)
create_discussion_post(
  cur_user: u('user3'), name: '問い合わせフォームの改善', text: '投稿時に問い合わせ先の課を選択でき、投稿通知が対象課に届くと良いと思います。', depth: 3,
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[1].id, parent_id: @ds_topics[1].id
)
create_discussion_post(
  name: 'メインスレッド', text: 'シラサギの改善要望について議論を交わしたいと思います。', depth: 3,
  forum_id: @ds_forums[1].id, topic_id: @ds_topics[2].id, parent_id: @ds_topics[2].id
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

create_faq_topic(
  name: '新しいグループウェアアカウントの発行はどうすればいいですか。', text: 'システム管理者にアカウント発行の申請を行ってください。',
  mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[1].id], readable_setting_range: 'public'
)
create_faq_topic(
  name: '出張申請はどのように行いますか。', text: 'ワークフローに「出張申請」がありますので、必要事項を記入し申請してください。',
  mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[0].id], readable_setting_range: 'public'
)

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
    cur_user: u('user4'), name: '共有ファイルに登録できるファイル容量および種類', mode: 'thread', permit_comment: 'allow',
    due_date: Time.zone.now.beginning_of_day + 7.days,
    text: '共有ファイルに登録できるファイル容量および種類の制限を教えてください。', category_ids: [@mon_cate[1].id]
  ),
  create_monitor_topic(
    cur_user: u('user5'), name: '新しい公用車の導入', mode: 'thread', permit_comment: 'allow',
    due_date: Time.zone.now.beginning_of_day + 7.days,
    text: "公用車の劣化が進んでおり、買い替えを行うことになりました。\r\n希望車種などがあれば回答をお願いします。", category_ids: [@mon_cate[0].id]
  )
]

def create_monitor_post(data)
  create_item(Gws::Monitor::Post, data)
end

create_monitor_post(
  cur_user: u('admin'), name: 'Re: 新しい公用車の導入', mode: 'thread', permit_comment: 'allow',
  due_date: Time.zone.now.beginning_of_day + 7.days,
  topic_id: @mon_topics[1].id, parent_id: @mon_topics[1].id,
  text: '車室の広いものを希望します。'
)

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

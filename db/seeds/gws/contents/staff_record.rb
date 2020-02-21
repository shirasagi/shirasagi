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

def create_staff_record_user_titles(data)
  puts data[:name]
  cond = { site_id: @site._id, year_id: data[:year_id], name: data[:name] }
  item = Gws::StaffRecord::UserTitle.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

@staff_record_years = [
  create_staff_record_year(name: "平成27年度", code: 2015, start_date: '2015/4/1', close_date: '2016/3/31'),
  create_staff_record_year(name: "平成28年度", code: 2016, start_date: '2016/4/1', close_date: '2017/3/31'),
  create_staff_record_year(name: "平成29年度", code: 2017, start_date: '2017/4/1', close_date: '2018/3/31')
].each do |year|
  sections = [
    create_staff_record_group(year_id: year.id, name: @site.name, order: 10, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '企画政策部', order: 20, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '政策課', order: 30, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '広報課', order: 40, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '危機管理部', order: 50, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '管理課', order: 60, seating_chart_url: ''),
    create_staff_record_group(year_id: year.id, name: '防災課', order: 70, seating_chart_url: '')
  ]
  user_titles = [
    create_staff_record_user_titles(year_id: year.id, name: '部長', code: 'T0100', order: 10),
    create_staff_record_user_titles(year_id: year.id, name: '課長', code: 'T0200', order: 20),
    create_staff_record_user_titles(year_id: year.id, name: '係長', code: 'T0300', order: 30),
    create_staff_record_user_titles(year_id: year.id, name: '主任', code: 'T0400', order: 40)
  ]

  create_staff_record_user(
    year_id: year.id, section_name: sections[2].name, in_title_id: user_titles[1].id,
    name: "佐藤 博", kana: 'サトウ ヒロシ', code: '101', charge_name: '庶務担当',
    divide_duties: "出張・研修関係\n文書収受",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[2].name,
    name: "鈴木 茂", kana: 'スズキ シゲル', code: '102', charge_name: '庶務担当',
    divide_duties: "出張・研修関係\n文書収受",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[3].name,
    name: "高橋 清", kana: 'タカハシ キヨシ', code: '103', charge_name: '庶務担当',
    divide_duties: "郵便発送\n掲示物",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[3].name,
    name: "田中 進", kana: 'タナカ ススム', code: '104', charge_name: '庶務担当',
    divide_duties: "郵便発送\n掲示物",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[5].name, in_title_id: user_titles[1].id,
    name: "伊藤 幸子", kana: 'イトウ サチコ', code: '201', charge_name: '会計担当',
    divide_duties: "予算・決算関係\n営繕関係",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[5].name,
    name: "渡辺 和子", kana: 'ワタナベ カズコ', code: '202', charge_name: '会計担当',
    divide_duties: "安全衛生・環境保全関係\n情報・ネットワーク関係",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[6].name,
    name: "山本 洋子", kana: 'ヤマモト ヒロコ', code: '203', charge_name: '企画調整担当',
    divide_duties: "安全衛生・環境保全関係\n施設、設備の維持管理に関すること",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
  create_staff_record_user(
    year_id: year.id, section_name: sections[6].name,
    name: "中村 節子", kana: 'ナカムラ セツコ', code: '204', charge_name: '企画調整担当',
    divide_duties: "地域社会との連携に関すること\n防火管理に関すること",
    tel_ext: '0000', charge_address: @site.name, charge_tel: '0000-00-0000'
  )
end

## -------------------------------------
puts "#create_staff_record_seating"

def create_staff_record_seating(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name], year_id: data[:year_id] }
  item = Gws::StaffRecord::Seating.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

create_staff_record_seating(
  name: '企画政策部', remark: '企画政策部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[0].id, year_code: '2015', year_name: '平成27年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)
create_staff_record_seating(
  name: '危機管理部', remark: '危機管理部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[0].id, year_code: '2015', year_name: '平成27年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)
create_staff_record_seating(
  name: '企画政策部', remark: '企画政策部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[1].id, year_code: '2016', year_name: '平成28年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)
create_staff_record_seating(
  name: '危機管理部', remark: '危機管理部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[1].id, year_code: '2016', year_name: '平成28年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)
create_staff_record_seating(
  name: '企画政策部', remark: '企画政策部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[2].id, year_code: '2017', year_name: '平成29年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)
create_staff_record_seating(
  name: '危機管理部', remark: '危機管理部の座席表です。', cur_user: u("sys"),
  year_id: @staff_record_years[2].id, year_code: '2017', year_name: '平成29年度',
  url: "/.g#{@site.id}/share/folder-#{sh_file("本庁舎フロア図").folder_id}/files/#{sh_file("本庁舎フロア図").id}"
)

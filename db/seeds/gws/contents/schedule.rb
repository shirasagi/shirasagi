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

def first_monday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.monday?
  base_date
end

def first_tuesday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.tuesday?
  base_date
end

def first_thursday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.thursday?
  base_date
end

def first_friday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.friday?
  base_date
end

def first_wednesday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.wednesday?
  base_date
end

def first_saturday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.saturday?
  base_date
end

def first_sunday_of_month(base_date)
  base_date = base_date.beginning_of_month
  base_date += 1.day until base_date.sunday?
  base_date
end

def second_monday_of_month(base_date)
  first_monday_of_month(base_date) + 7.days
end

def third_monday_of_month(base_date)
  first_monday_of_month(base_date) + 14.days
end

def second_thursday_of_month(base_date)
  first_thursday_of_month(base_date) + 7.days
end

def third_thursday_of_month(base_date)
  first_thursday_of_month(base_date) + 14.days
end

def third_tuesday_of_month(base_date)
  first_tuesday_of_month(base_date) + 14.days
end

def second_tuesday_of_month(base_date)
  first_tuesday_of_month(base_date) + 7.days
end

def second_friday_of_month(base_date)
  first_friday_of_month(base_date) + 7.days
end

def third_friday_of_month(base_date)
  first_friday_of_month(base_date) + 14.days
end

def forth_friday_of_month(base_date)
  first_friday_of_month(base_date) + 21.days
end

def third_sunday_of_month(base_date)
  first_saturday_of_month(base_date) + 14.days
end

def second_wednesday_of_month(base_date)
  first_wednesday_of_month(base_date) + 7.days
end

def second_sunday_of_month(base_date)
  first_sunday_of_month(base_date) + 7.days
end

def forth_thursday_of_month(base_date)
  first_thursday_of_month(base_date) + 21.days
end

def third_wednesday_of_month(base_date)
  first_wednesday_of_month(base_date) + 14.days
end

def forth_monday_of_month(base_date)
  first_monday_of_month(base_date) + 21.days
end

def third_saturday_of_month(base_date)
  first_saturday_of_month(base_date) + 14.days
end

def forth_tuesday_of_month(base_date)
  first_tuesday_of_month(base_date) + 21.days
end

def forth_wednesday_of_month(base_date)
  first_wednesday_of_month(base_date) + 21.days
end

def forth_saturday_of_month(base_date)
  first_saturday_of_month(base_date) + 21.days
end

def create_schedule_plan(data)
  data = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  #puts data[:name]
  cond = {site_id: @site.id, user_id: data[:cur_user].id, name: data[:name]}
  item = Gws::Schedule::Plan.find_or_initialize_by(cond)
  item.attributes = data
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

def create_schedule_comment(data)
  data = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  #puts data[:name]
  cond = {site_id: @site.id, schedule_id: data[:cur_schedule].id, text: data[:text]}
  item = Gws::Schedule::Comment.find_or_initialize_by(cond)
  item.attributes = data
  puts item.errors.full_messages unless item.save
  item
end

base_date = @now.beginning_of_month

# puts "予定1..50"
# 1.upto(50) do |i|
#   params = {
#     name: "#{@site.name}の予定#{i}",
#     member_ids: @users.sample(2).map(&:id),
#     category_id: @sc_cate.sample.id
#   }
#   date = base_date + (i * 3).days
#   if i.odd?
#     params.merge! start_at: date.strftime('%Y-%m-%d 10:00'),
#                   end_at: date.strftime('%Y-%m-%d 11:00'),
#                   facility_ids: [@fc_item.sample.id]
#   else
#     params.merge! start_on: date.strftime('%Y-%m-%d'),
#                   end_on: (date + 1.day).strftime('%Y-%m-%d'),
#                   allday: 'allday'
#   end
#   create_schedule_plan params
# end

@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "東京出張", member_ids: [u("sys").id, u("admin").id, u("user3").id],
  allday: "allday",
  start_on: first_monday_of_month(base_date).strftime('%Y-%m-%d'),
  end_on: (first_monday_of_month(base_date) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
create_schedule_plan(
  name: "地域イベント打ち合わせ", member_ids: [u("sys").id, u("admin").id, u("user1").id, u('user2').id],
  start_at: first_friday_of_month(base_date).strftime('%Y-%m-%d 10:00'),
  end_at: first_friday_of_month(base_date).strftime('%Y-%m-%d 11:00'),
  repeat_type: 'weekly', interval: 1, wdays: [],
  repeat_start: first_friday_of_month(base_date).strftime('%Y-%m-%d'),
  repeat_end: (first_friday_of_month(base_date) + 6.months).strftime('%Y-%m-%d'), category_id: @sc_cate[0].id,
  facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id, priority: '1'
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("admin"), name: '全庁会議',
  start_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 14:00'),
  end_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 15:00'),
  repeat_type: 'weekly', interval: 1, wdays: [2],
  repeat_start: first_tuesday_of_month(base_date),
  repeat_end: first_tuesday_of_month(base_date) + 5.months,
  member_ids: @users.map(&:id),
  facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id,
  group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("sys"), name: "#{@site_name}支所訪問 (#{second_monday_of_month(base_date).strftime('%m')}月)",
  member_ids: [u("user1").id, u("sys").id],
  start_at: second_monday_of_month(base_date).strftime('%Y-%m-%d 13:00'),
  end_at: second_monday_of_month(base_date).strftime('%Y-%m-%d 15:00'),
  group_ids: [g("政策課").id], readable_setting_range: 'select',
  readable_group_ids: [g('政策課').id], priority: '4'
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("sys"), name: "#{@site_name}支所訪問 (#{first_monday_of_month(base_date + 1.month).strftime('%m')}月)",
  member_ids: [u("user1").id, u("sys").id],
  start_at: first_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d 11:00'),
  end_at: first_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d 12:00'),
  group_ids: [g("政策課").id], readable_setting_range: 'select',
  readable_group_ids: [g('政策課').id], category_id: @sc_cate[0].id,
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("sys"), name: "徳島出張", member_ids: [u("sys").id],
  allday: "allday",
  start_on: third_tuesday_of_month(base_date).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[1].id, priority: '1',
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("sys"), name: "クロサギ支所訪問", member_ids: [u("user1").id, u("admin").id, u("sys").id],
  start_at: forth_thursday_of_month(base_date).strftime('%Y-%m-%d 9:00'),
  end_at: forth_thursday_of_month(base_date).strftime('%Y-%m-%d 10:00'),
  group_ids: [g("政策課").id],
  approval_state: 'approve', approval_member_ids: [u('user1').id],
  approvals: [{user_id: u('user1').id, approval_state: "approve"}],
  attendances: [{user_id: u('user1').id, attendance_state: "attendance"}], attendance_check_state: "enabled",
  category_id: @sc_cate[0].id, facility_ids: [@fc_item[2].id], main_facility_id: @fc_item[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
)

create_schedule_comment(
  cur_user: u("user1"), cur_schedule: @sch_plan2, text_type: "plain", text: "参加します。"
)
create_schedule_comment(
  cur_user: u("user1"), cur_schedule: @sch_plan2, text_type: "plain", text: "承認します。"
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("sys"), name: '佐賀出張',
  allday: "allday",
  start_on: third_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  end_on: (third_thursday_of_month(base_date + 1.month) + 1.day).strftime('%Y-%m-%d'),
  member_ids: [u('sys').id], facility_ids: [@fc_item[2].id], main_facility_id: @fc_item[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  readable_member_ids: [u('sys').id], priority: '3', category_id: @sc_cate[1].id
)
@sch_plan1 = create_schedule_plan(
  name: "#{@site_name}会議", start_at: base_date.strftime('%Y-%m-%d 15:00'), end_at: base_date.strftime('%Y-%m-%d 16:00'),
  repeat_type: 'weekly', interval: 1, repeat_start: base_date, repeat_end: base_date + 1.month, wdays: [3],
  member_ids: @users.map(&:id), member_custom_group_ids: [@cgroups[0].id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  readable_member_ids: [u('sys').id], category_id: @sc_cate[0].id
)
create_schedule_plan(
  name: '定例報告会',
  start_at: first_wednesday_of_month(base_date).strftime('%Y-%m-%d 14:00'),
  end_at: first_wednesday_of_month(base_date).strftime('%Y-%m-%d 16:00'),
  repeat_type: 'weekly', interval: 1, repeat_start: first_wednesday_of_month(base_date),
  repeat_end: first_wednesday_of_month(base_date) + 6.months, wdays: [],
  member_ids: %w(sys admin user1 user2 user3).map { |uid| u(uid).id },
  readable_setting_range: 'select', group_ids: [g('政策課').id]
)

# create_schedule_plan(
#   name: "株式会社#{@site_name}来社", start_at: (base_date + 2.day).strftime('%Y-%m-%d 10:00'),
#   end_at: (base_date + 1.day).strftime('%Y-%m-%d 11:00'),
#   member_ids: %w(admin user1).map { |uid| u(uid).id },
#   facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id,
#   readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
# )
create_schedule_plan(
  cur_user: u("admin"), name: "株式会社クロサギ様来庁", member_ids: [u("user1").id],
  start_at: first_tuesday_of_month(base_date + 2.months).strftime('%Y-%m-%d 10:00'),
  end_at: first_tuesday_of_month(base_date + 2.months).strftime('%Y-%m-%d 11:00'),
  repeat_end: first_wednesday_of_month(base_date) + 6.months, wdays: [],
  start_on: second_thursday_of_month(base_date).strftime('%Y-%m-%d'),
  category_id: @sc_cate[0].id,
  group_ids: [g("政策課").id]
)
create_schedule_plan(
  name: "株式会社#{@site_name}様来庁", member_ids: [u("admin").id, u("user4").id],
  start_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 10:00'),
  end_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 11:00'),
  repeat_type: 'monthly', interval: 1, repeat_start: first_tuesday_of_month(base_date),
  repeat_end: first_tuesday_of_month(base_date) + 6.months, wdays: [1],
  repeat_base: 'wday',
  # start_at: first_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 10:00'),
  # end_at: first_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 11:00'),
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id, category_id: @sc_cate[1].id
)
@sch_admin_hiroshima = create_schedule_plan(
  cur_user: u("admin"), name: "広島出張", member_ids: [u("admin").id, u("user1").id],
  allday: "allday",
  start_on: third_saturday_of_month(base_date).strftime('%Y-%m-%d'),
  end_on: (third_saturday_of_month(base_date) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id],
  facility_ids: [@fc_item[2].id], main_facility_id: @fc_item[2].id
)
create_schedule_plan(
  cur_user: u("admin"), name: "有給休暇(#{third_thursday_of_month(base_date).strftime('%m%d')})", member_ids: [u("admin").id],
  allday: "allday",
  start_on: third_thursday_of_month(base_date).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
)
create_schedule_plan(
  cur_user: u("sys"), name: "有給休暇(#{first_tuesday_of_month(base_date + 1.month).strftime('%m%d')})", member_ids: [u("sys").id],
  allday: "allday",
  start_on: first_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
)
create_schedule_plan(
  cur_user: u("user4"), name: "有給休暇(#{first_tuesday_of_month(base_date + 1.month).strftime('%m%d')})",
  member_ids: [u("user4").id],
  allday: "allday",
  start_on: forth_wednesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
create_schedule_plan(
  cur_user: u("user5"), name: "有給休暇(#{first_tuesday_of_month(base_date + 1.month).strftime('%m%d')})",
  member_ids: [u("user5").id],
  allday: "allday",
  start_on: forth_friday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
create_schedule_plan(
  cur_user: u("user2"), name: "有給休暇(#{third_thursday_of_month(base_date + 1.month).strftime('%m%d')})",
  member_ids: [u("user2").id],
  allday: "allday",
  start_on: third_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("管理課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
create_schedule_plan(
  cur_user: u("admin"), name: "有給休暇(#{forth_tuesday_of_month(base_date + 2.months).strftime('%m%d')})",
  member_ids: [u("user1").id, u("user2").id], allday: "allday",
  start_on: forth_tuesday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (forth_tuesday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "防災イベント", member_ids: [u("user2").id, u("user5").id],
  allday: "allday",
  start_on: second_sunday_of_month(base_date).strftime('%Y-%m-%d'),
  end_on: second_sunday_of_month(base_date).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], readable_setting_range: 'select',
  readable_group_ids: [g('政策課').id], priority: '2',
  facility_ids: [@fc_item[2].id], main_facility_id: @fc_item[2].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "防災イベント", member_ids: [u("user2").id, u("user4").id],
  allday: "allday",
  start_on: first_friday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (first_friday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], readable_setting_range: 'select',
  readable_group_ids: [g('政策課').id]
)
create_schedule_plan(
  cur_user: u("user2"), name: "代休", member_ids: [u("user2").id],
  allday: "allday",
  start_on: forth_thursday_of_month(base_date).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "広報イベント",
  member_group_ids: [g("広報課").id], member_ids: [u("user3").id, u("user5").id],
  allday: "allday",
  start_on: forth_friday_of_month(base_date).strftime('%Y-%m-%d'),
  end_on: (forth_friday_of_month(base_date) + 1.day).strftime('%Y-%m-%d'),
  group_ids: [g('政策課').id], user_ids: [u("user3").id, u("user5").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "地域振興イベント(#{third_monday_of_month(base_date).strftime('%m%d')})",
  member_ids: [u("admin").id, u("user4").id],
  start_at: third_monday_of_month(base_date).strftime('%Y-%m-%d 10:00'),
  end_at: third_monday_of_month(base_date).strftime('%Y-%m-%d 16:00'),
  group_ids: [g("政策課").id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  user_ids: [u("admin").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "地域振興イベント(#{third_sunday_of_month(base_date + 2.months).strftime('%m%d')})",
  member_ids: [u("user1").id, u("user5").id],
  start_on: third_sunday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], allday: "allday",
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id,
  user_ids: [u("admin").id,]
)

@sch_plan2 = create_schedule_plan(
  cur_user: u("user1"), name: "東京出張", member_ids: [u("user1").id],
  allday: "allday", category_id: @sc_cate[1].id,
  start_on: third_monday_of_month(base_date).strftime('%Y-%m-%d'),
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  group_ids: [g("政策課").id], user_ids: [u("user1").id,]
)
create_schedule_plan(
  cur_user: u("sys"), name: "サンプルイベント", member_ids: [u("admin").id, u("sys").id],
  start_at: first_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 20:00'),
  end_at: first_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 21:00'),
  group_ids: [g("政策課").id], readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  approval_member_ids: [u('admin').id], approval_state: 'request'
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "防災訓練", member_ids: @users.map(&:id), interval: 1,
  start_at: second_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 10:00'),
  end_at: second_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 11:00'), priority: '2'
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("sys"), name: "アオサギ株式会社様来社(#{third_tuesday_of_month(base_date + 2.months).strftime('%m%d')})",
  start_at: third_tuesday_of_month(base_date + 2.months).strftime('%Y-%m-%d 11:00'),
  end_at: third_tuesday_of_month(base_date + 2.months).strftime('%Y-%m-%d 12:00'), interval: 1,
  member_ids: [u("user1").id, u("sys").id, u("user2").id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  group_ids: [g("政策課").id]
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("admin"), name: "アオサギ株式会社様来庁(#{forth_thursday_of_month(base_date + 2.months).strftime('%m%d')})",
  start_at: forth_thursday_of_month(base_date + 2.months).strftime('%Y-%m-%d 10:00'),
  end_at: forth_thursday_of_month(base_date + 2.months).strftime('%Y-%m-%d 11:00'), interval: 1,
  member_ids: [u("user1").id, u("user2").id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  group_ids: [g("政策課").id],
  readable_setting_range: 'select', readable_group_ids: [u('user1').id, u('user2').id]
)
create_schedule_plan(
  name: "企画セミナー", cur_user: u("sys"), member_ids: [u("sys").id],
  start_at: second_thursday_of_month(base_date +2.months).strftime('%Y-%m-%d 16:00'),
  end_at: second_thursday_of_month(base_date +2.months).strftime('%Y-%m-%d 18:00'), priority: '1',
  member_group_ids: [g("政策課").id, g("広報課").id, g("企画政策部").id],
  attendances: [{user_id: u('user3').id, attendance_state: "attendance"}], attendance_check_state: "enabled",
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
create_schedule_plan(
  name: "企画勉強会", member_ids: [u("user1").id],
  start_at: second_monday_of_month(base_date +1.month).strftime('%Y-%m-%d 16:30'),
  end_at: second_monday_of_month(base_date +1.month).strftime('%Y-%m-%d 19:00'),
  group_ids: [g("政策課").id],
  readable_setting_range: 'select', readable_group_ids: [u('user1').id]
)
create_schedule_plan(
  name: "代休（広島出張）", member_ids: [u("admin").id, u("user1").id],
  allday: "allday",
  start_on: third_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  end_on: (third_monday_of_month(base_date + 1.month) + 1.day).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], category_id: @sc_cate[2].id,
  readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "大阪出張", member_ids: [u("admin").id, u("user1").id],
  start_on: forth_friday_of_month(base_date + 1.month).strftime('%Y-%m-%d'), allday: "allday",
  end_on: forth_friday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id,
  group_ids: [g("政策課").id], category_id: @sc_cate[1].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "長野出張", member_ids: [u("admin").id, u("user1").id],
  allday: "allday",
  start_on: third_thursday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (third_thursday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "千葉出張", member_ids: [u("user1").id, u("user5").id],
  allday: "allday", category_id: @sc_cate[1].id,
  start_on: first_sunday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], user_ids: [u("user1").id,]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("user2"), name: "岡山出張", member_ids: [u("user2").id],
  allday: "allday", category_id: @sc_cate[1].id,
  start_on: second_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  group_ids: [g("政策課").id], user_ids: [u("user2").id,]
)
create_schedule_plan(
  name: "アカサギ商事様来庁", member_ids: [u("user2").id, u("user4").id],
  start_at: third_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d 13:00'),
  end_at: third_monday_of_month(base_date + 1.month).strftime('%Y-%m-%d 14:00'),
  facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id, category_id: @sc_cate[1].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "富山出張", member_ids: [u("user2").id, u("user5").id],
  allday: "allday",
  start_on: second_thursday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (second_thursday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "滋賀出張", member_ids: [u("user2").id],
  allday: "allday", category_id: @sc_cate[1].id,
  start_on: forth_saturday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "和歌山出張", member_ids: [u("user2").id],
  allday: "allday",
  start_on: forth_monday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (forth_monday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "福島出張", member_ids: [u("user3").id, u("user5").id],
  start_on: second_wednesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  end_on: (second_wednesday_of_month(base_date + 1.month) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id], allday: "allday"
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "北海道出張", member_ids: [u("user3").id],
  allday: "allday",
  start_on: second_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  end_on: (second_tuesday_of_month(base_date + 1.month) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("admin"), name: "兵庫出張", member_ids: [u("user3").id, u("user5").id],
  allday: "allday",
  start_on: third_wednesday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: (third_wednesday_of_month(base_date + 2.months) + 1.day).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id]
)
create_schedule_plan(
  name: "#{@site_name}テレビ局来庁", cur_user: u("user3"),
  member_ids: [u("user3").id, u("user5").id],
  start_at: forth_friday_of_month(base_date + 2.months).strftime('%Y-%m-%d 13:00'),
  end_at: forth_friday_of_month(base_date + 2.months).strftime('%Y-%m-%d 14:00')
)
create_schedule_plan(
  name: "アオサギ支所訪問", member_ids: [u("user4").id],
  start_at: third_friday_of_month(base_date).strftime('%Y-%m-%d 14:00'),
  end_at: third_friday_of_month(base_date).strftime('%Y-%m-%d 15:00'),
  facility_ids: [@fc_item[2].id], main_facility_id: @fc_item[2].id, category_id: @sc_cate[1].id
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("user4"), name: "高知出張", member_ids: [u("user4").id],
  allday: "allday",
  start_on: third_wednesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  end_on: third_wednesday_of_month(base_date + 1.month).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("管理課").id]
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("admin"), name: '株式会社アカサギ様来庁',
  start_at: third_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 10:00'),
  end_at: third_tuesday_of_month(base_date + 1.month).strftime('%Y-%m-%d 11:00'), interval: 1,
  member_ids: [u("user4").id, u("user5").id],
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id,
  group_ids: [g("政策課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("user4"), name: "香川出張", member_ids: [u("user4").id],
  allday: "allday",
  start_on: second_wednesday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  end_on: second_wednesday_of_month(base_date + 2.months).strftime('%Y-%m-%d'),
  category_id: @sc_cate[1].id, group_ids: [g("管理課").id], priority: '1'
)
create_schedule_plan(
  name: "クロサギ商事様来庁", member_ids: [u("user4").id], cur_user: u("user4"),
  start_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 16:00'),
  end_at: first_tuesday_of_month(base_date).strftime('%Y-%m-%d 17:00'),
  repeat_type: 'monthly', interval: 1, repeat_start: first_tuesday_of_month(base_date),
  repeat_end: first_tuesday_of_month(base_date) + 6.months, wdays: [1],
  repeat_base: 'wday',
  category_id: @sc_cate[1].id, readable_setting_range: 'select', readable_group_ids: [g('管理課').id]
)
create_schedule_plan(
  name: "清掃活動", cur_user: u("user2"), member_ids: [u('user2').id, u("user4").id],
  start_at: second_wednesday_of_month(base_date +1.month).strftime('%Y-%m-%d 9:00'),
  end_at: second_wednesday_of_month(base_date +1.month).strftime('%Y-%m-%d 10:00'),
  group_ids: [g("政策課").id],
  readable_setting_range: 'select', readable_group_ids: [u('user2').id],
  approval_member_ids: [u('user4').id], approval_state: 'request'
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("user4"), name: "国民保護協議会参加", member_ids: [u("user4").id],
  start_at: forth_friday_of_month(base_date + 2.months).strftime('%Y-%m-%d 14:00'),
  end_at: forth_friday_of_month(base_date + 2.months).strftime('%Y-%m-%d 15:00'),
  group_ids: [g("政策課").id], readable_setting_range: 'select',
  readable_group_ids: [g('政策課').id], category_id: @sc_cate[0].id,
  facility_ids: [@fc_item[3].id], main_facility_id: @fc_item[3].id, priority: '1'
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("user5"), name: '#{@site_name}印刷様来社',
  start_at: forth_monday_of_month(base_date + 2.months).strftime('%Y-%m-%d 14:00'),
  end_at: forth_monday_of_month(base_date + 2.months).strftime('%Y-%m-%d 15:00'), interval: 1,
  member_ids: [u("user5").id],
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  group_ids: [g("政策課").id], category_id: @sc_cate[1].id
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("user5"), name: '広報会議',
  start_at: second_monday_of_month(base_date + 2.months).strftime('%Y-%m-%d 13:00'),
  end_at: second_monday_of_month(base_date + 2.months).strftime('%Y-%m-%d 14:00'), interval: 1,
  member_ids: [u("user5").id, u("user3").id], group_ids: [g("政策課").id], category_id: @sc_cate[1].id,
  facility_ids: [@fc_item[1].id], main_facility_id: @fc_item[1].id
)
@sch_plan1 = create_schedule_plan(
  cur_user: u("user2"), name: '課内打ち合わせ',
  start_at: forth_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 15:00'),
  end_at: forth_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 16:00'), interval: 1,
  member_ids: [u("user2").id], group_ids: [g("管理課").id], category_id: @sc_cate[1].id,
  member_group_ids: [g("管理課").id]
)
@sch_plan2 = create_schedule_plan(
  cur_user: u("sys"), name: "出張", color: '#0033FF', member_ids: [u("sys").id],
  start_at: forth_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 16:00'),
  end_at: forth_thursday_of_month(base_date + 1.month).strftime('%Y-%m-%d 17:00'),
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  category_id: @sc_cate[1].id, group_ids: [g("政策課").id], priority: '3',
  member_custom_group_ids: [@cgroups[0].id], member_group_ids: [g("政策課").id],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  attendances: [{user_id: u('user1').id, attendance_state: "attendance"}], attendance_check_state: "enabled"
)
create_schedule_plan(
  cur_user: u("admin"), name: "クロサギ株式会社様来庁", member_ids: [u("user2").id, u("user5").id],
  start_at: third_tuesday_of_month(base_date).strftime('%Y-%m-%d 10:00'),
  end_at: third_tuesday_of_month(base_date).strftime('%Y-%m-%d 11:00'),
  facility_ids: [@fc_item[0].id], main_facility_id: @fc_item[0].id,
  category_id: @sc_cate[0].id, group_ids: [g("政策課").id]
)

# @sch_plan2 = create_schedule_plan(
#   cur_user: u('user1'), name: '東京出張',
#   allday: 'allday', start_on: base_date + 13.day + 9.hours, end_on: base_date + 13.day + 9.hours,
#   start_at: base_date + 13.days, end_at: base_date.end_of_day,
#   member_ids: %w(user1).map { |uid| u(uid).id },
#   readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
#   category_id: @sc_cate[1].id
# )

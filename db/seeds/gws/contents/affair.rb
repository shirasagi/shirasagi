puts "# affair"

def update_staff_address_uid(uid, staff_address_uid)
  item = Gws::User.find_by(uid: uid) rescue nil
  return unless item
  item.staff_address_uid = staff_address_uid
  item.save!
  puts item.name
  item
end

def create_capital_year(site, fyear)
  item = Gws::Affair::CapitalYear.find_or_initialize_by(site_id: @site.id, code: fyear)
  item.name = fyear.to_s
  item.start_date = @site.fiscal_first_date(fyear)
  item.close_date = @site.fiscal_last_date(fyear)
  item.save!
  puts item.name
  item
end

def create_capital(site, cond = {})
  cond = { site_id: @site.id }.merge(cond)
  item = Gws::Affair::Capital.find_or_initialize_by(cond)
  item.save!
  puts item.name
  item
end

def create_leave_setting(site, year, user)
  cond = { site_id: @site.id, year_id: year.id, target_user_id: user.id }
  item = Gws::Affair::LeaveSetting.find_or_initialize_by(cond)
  item.cur_site = @site
  item.cur_user = user
  item.count = 20
  item.save!
  puts item.name
  item
end

def create_special_leave(site, cond = {})
  cond = { site_id: @site.id }.merge(cond)
  item = Gws::Affair::SpecialLeave.find_or_initialize_by(cond)
  item.save!
  puts item.name
  item
end

def create_overtime_file(site, cond = {})
  cond = { site_id: @site.id }.merge(cond)
  item = Gws::Affair::OvertimeFile.find_or_initialize_by(cond)
  item.save
  puts item.name
  item
end

def approve_overtime_file(item, approver)
  workflow_approvers = Workflow::Extensions::WorkflowApprovers.new
  workflow_approvers << { level: 1, user_id: approver.id, state: "approve", comment: "" }

  item.workflow_user = item.user
  item.workflow_approvers = workflow_approvers
  item.state = "approve"
  item.workflow_state = "approve"
  item.approved = Time.zone.now
  item.update
  item
end

def create_overtime_day_result(item, start_at, end_at)
  start_at_date = start_at.strftime("%Y/%m/%d")
  start_at_hour = start_at.hour
  start_at_minute = start_at.min

  end_at_date = end_at.strftime("%Y/%m/%d")
  end_at_hour = end_at.hour
  end_at_minute = end_at.min

  item.in_results = {
    item.id => {
      "start_at_date" => start_at_date,
      "start_at_hour" => start_at_hour,
      "start_at_minute" => start_at_minute,
      "end_at_date" => end_at_date,
      "end_at_hour" => end_at_hour,
      "end_at_minute" => end_at_minute
    }
  }
  item.save_results

  item.reload
  item.close_result

  item
end

# users
sys = update_staff_address_uid("sys", "9000")
admin = update_staff_address_uid("admin", "9001")
user1 = update_staff_address_uid("user1", "1001")
user2 = update_staff_address_uid("user2", "1002")
user3 = update_staff_address_uid("user3", "1003")
user4 = update_staff_address_uid("user4", "1004")
user5 = update_staff_address_uid("user5", "1005")

# year
year = create_capital_year(@site, @site.fiscal_year)

# capitals
capital1 = create_capital(@site,
  year: year.id,
  article_code: 1,
  section_code: 1,
  subsection_code: 1,
  project_code: 1000,
  detail_code: 100,
  project_name: "事業1",
  description_name: "説明1")
capital2 = create_capital(@site,
  year: year.id,
  article_code: 1,
  section_code: 1,
  subsection_code: 2,
  project_code: 1001,
  detail_code: 101,
  project_name: "事業2",
  description_name: "説明2")
capital3 = create_capital(@site,
  year: year.id,
  article_code: 1,
  section_code: 1,
  subsection_code: 3,
  project_code: 1002,
  detail_code: 102,
  project_name: "事業3",
  description_name: "説明3")
capital1.member_group_ids = Gws::Group.in_group(@site).pluck(:id)
capital1.save!

# leave setting
create_leave_setting(@site, year, sys)
create_leave_setting(@site, year, admin)
create_leave_setting(@site, year, user1)
create_leave_setting(@site, year, user2)
create_leave_setting(@site, year, user3)
create_leave_setting(@site, year, user4)
create_leave_setting(@site, year, user5)

# special leave
create_special_leave(@site, name: "夏季休暇", code: 10, order: 10, staff_category: "regular_staff")
create_special_leave(@site, name: "介護休暇", code: 20, order: 20, staff_category: "regular_staff")
create_special_leave(@site, name: "リフレッシュ休暇", code: 30, order: 30, staff_category: "regular_staff")
create_special_leave(@site, name: "夏季休暇", code: 40, order: 40, staff_category: "fiscal_year_staff")
create_special_leave(@site, name: "介護休暇", code: 50, order: 50, staff_category: "fiscal_year_staff")

# overtime files
duty_hour = Gws::Affair::DefaultDutyHour.new(cur_site: @site)

start_at = duty_hour.affair_end(Time.zone.now)
end_at = start_at.advance(hours: 1)
overtime_file1 = create_overtime_file(@site,
  user_id: user1.id,
  overtime_name: "定例会議の報告書作成",
  capital_id: capital1.id,
  start_at: start_at,
  end_at: end_at,
  target_group_id: user1.groups.first.id,
  target_user_id: user1.id,
  readable_group_ids: [user1.groups.first.id],
  group_ids: [user1.groups.first.id])
overtime_file1 = approve_overtime_file(overtime_file1, sys)
overtime_file1 = create_overtime_day_result(overtime_file1, start_at, end_at)

start_at = duty_hour.affair_end(Time.zone.now.advance(days: 1))
end_at = start_at.advance(hours: 1)
overtime_file2 = create_overtime_file(@site,
  user_id: user1.id,
  overtime_name: "地域イベントのパンフレット作成",
  capital_id: capital1.id,
  start_at: start_at,
  end_at: end_at,
  target_group_id: user1.groups.first.id,
  target_user_id: user1.id,
  readable_group_ids: [user1.groups.first.id],
  group_ids: [user1.groups.first.id])
overtime_file2 = approve_overtime_file(overtime_file2, sys)
overtime_file2 = create_overtime_day_result(overtime_file2, start_at, end_at)

start_at = duty_hour.affair_end(Time.zone.now.advance(days: 2))
end_at = start_at.advance(hours: 1)
overtime_file3 = create_overtime_file(@site,
  user_id: user2.id,
  overtime_name: "選挙会場の準備",
  capital_id: capital1.id,
  start_at: start_at,
  end_at: end_at,
  target_group_id: user2.groups.first.id,
  target_user_id: user2.id,
  readable_group_ids: [user2.groups.first.id],
  group_ids: [user2.groups.first.id])
overtime_file3 = approve_overtime_file(overtime_file3, sys)
overtime_file3 = create_overtime_day_result(overtime_file3, start_at, end_at)

#

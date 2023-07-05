def create_workload_category(data)
  create_item(Gws::Workload::Category, data)
end

def create_workload_client(data)
  create_item(Gws::Workload::Client, data)
end

def create_workload_cycle(data)
  create_item(Gws::Workload::Cycle, data)
end

def create_workload_load(data)
  create_item(Gws::Workload::Load, data)
end

def create_workload_work(data)
  create_item(Gws::Workload::Work, data)
end

def create_workload_work_comment(data)
  data[:cur_site] = @site
  data[:year] = @site.fiscal_year
  Gws::Workload::WorkComment.new(data).save!
end

def create_workload_overtime(user)
  Gws::Workload::Overtime.create_settings(@site.fiscal_year, [user], site_id: @site.id,
    group_id: user.gws_main_group(@site).id).first
end

member_user1 = u('user1')
member_user2 = u('admin')
member_user3 = u('sys')
member_group = member_user1.gws_main_group(@site)

puts "# workload/category"
category1 = create_workload_category(name: "人事・給与・共済", year: @site.fiscal_year, member_group: member_group, order: 10)
category2 = create_workload_category(name: "財政", year: @site.fiscal_year, member_group: member_group, order: 20)
category3 = create_workload_category(name: "企画", year: @site.fiscal_year, member_group: member_group, order: 30)
category4 = create_workload_category(name: "議会", year: @site.fiscal_year, member_group: member_group, order: 40)
category5 = create_workload_category(name: "契約・財産管理", year: @site.fiscal_year, member_group: member_group, order: 50)
category6 = create_workload_category(name: "消防・防災", year: @site.fiscal_year, member_group: member_group, order: 60)
category7 = create_workload_category(name: "広報", year: @site.fiscal_year, member_group: member_group, order: 70)
category8 = create_workload_category(name: "庶務", year: @site.fiscal_year, member_group: member_group, order: 80)
category9 = create_workload_category(name: "選挙", year: @site.fiscal_year, member_group: member_group, order: 90)

puts "# workload/client"
client1 = create_workload_client(name: "都", year: @site.fiscal_year, order: 10)
client2 = create_workload_client(name: "国", year: @site.fiscal_year, order: 20)
client3 = create_workload_client(name: "定期", year: @site.fiscal_year, order: 30)
client4 = create_workload_client(name: "庁内", year: @site.fiscal_year, order: 40)
client5 = create_workload_client(name: "住民", year: @site.fiscal_year, order: 50)
client6 = create_workload_client(name: "他自治体", year: @site.fiscal_year, order: 60)

puts "# workload/cycle"
cycle1 = create_workload_cycle(name: "毎年", year: @site.fiscal_year, order: 10)
cycle2 = create_workload_cycle(name: "隔年", year: @site.fiscal_year, order: 20)
cycle3 = create_workload_cycle(name: "毎月", year: @site.fiscal_year, order: 30)
cycle4 = create_workload_cycle(name: "毎日", year: @site.fiscal_year, order: 40)
cycle5 = create_workload_cycle(name: "臨時", year: @site.fiscal_year, order: 50)
cycle6 = create_workload_cycle(name: "3か月毎", year: @site.fiscal_year, order: 60)
cycle7 = create_workload_cycle(name: "4か月毎", year: @site.fiscal_year, order: 70)
cycle8 = create_workload_cycle(name: "半年毎", year: @site.fiscal_year, order: 80)

puts "# workload/load"
load1 = create_workload_load(name: "作業負荷大", year: @site.fiscal_year, coefficient: 166320, color: "#ff0000", order: 10)
load2 = create_workload_load(name: "作業負荷並", year: @site.fiscal_year, coefficient: 55440, color: "#008000", order: 20)
load3 = create_workload_load(name: "作業負荷小", year: @site.fiscal_year, coefficient: 27720, color: "#0000ff", order: 30)

puts "# workload/work"
today = Time.zone.today

due_date = today + @site.workload_default_due_date.day
due_start_on = today
work1 = create_workload_work(name: "サポート事業補助金", due_date: due_date, due_start_on: due_start_on,
  year: @site.fiscal_year, category: category2, client: client2, cycle: cycle1, load: load1,
  member_group: member_group, member_ids: [member_user1.id, member_user2.id, member_user3.id])

due_date = due_date.next_month
due_start_on = due_start_on.next_month
work2 = create_workload_work(name: "町村議会実態調査", due_date: due_date, due_start_on: due_start_on,
  year: @site.fiscal_year, category: category3, client: client5, cycle: cycle2, load: load2,
  member_group: member_group, member_ids: [member_user1.id, member_user2.id, member_user3.id])

due_date = due_date.next_month
due_start_on = due_start_on.next_month
work3 = create_workload_work(name: "事務処理効率化補助金申請", due_date: due_date, due_start_on: due_start_on,
  year: @site.fiscal_year, category: category1, client: client4, cycle: cycle3, load: load3,
  member_group: member_group, member_ids: [member_user1.id, member_user2.id, member_user3.id])

create_workload_work_comment(cur_work: work1, cur_user: member_user1, worktime_minutes: 30)
create_workload_work_comment(cur_work: work2, cur_user: member_user1, worktime_minutes: 60)
create_workload_work_comment(cur_work: work3, cur_user: member_user1, worktime_minutes: 120)

create_workload_work_comment(cur_work: work1, cur_user: member_user2, worktime_minutes: 15)
create_workload_work_comment(cur_work: work2, cur_user: member_user2, worktime_minutes: 30)
create_workload_work_comment(cur_work: work3, cur_user: member_user2, worktime_minutes: 60)

create_workload_work_comment(cur_work: work1, cur_user: member_user3, worktime_minutes: 10)
create_workload_work_comment(cur_work: work2, cur_user: member_user3, worktime_minutes: 20)
create_workload_work_comment(cur_work: work3, cur_user: member_user3, worktime_minutes: 30)

overtime1 = create_workload_overtime(member_user1)
overtime2 = create_workload_overtime(member_user2)
overtime3 = create_workload_overtime(member_user3)
@site.fiscal_months.each do |m|
  overtime1.send("in_month#{m}_hours=", rand(45))
  overtime2.send("in_month#{m}_hours=", rand(45))
  overtime3.send("in_month#{m}_hours=", rand(45))
end
overtime1.update
overtime2.update
overtime3.update

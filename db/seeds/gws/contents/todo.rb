puts "# schedule/todo"

base_date = @now.beginning_of_month

def create_schedule_todo(data)
  create_item(Gws::Schedule::Todo, data)
end

@todos = [
  create_schedule_todo(
    name: '広報誌校正', member_ids: [u('user3').id],
    start_at: @now + 6.months, end_at: @now + 6.months + 1.hour, priority: '1',
    repeat_type: "monthly", interval: "1", repeat_base: "wday", wdays: [""],
    repeat_start: (@now + 6.months).beginning_of_month, repeat_end: (@now + 8.months).end_of_month,
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id
  ),
  create_schedule_todo(
    name: '防災年間スケジュール作成', member_ids: [u('user4').id],
    start_at: third_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: third_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user4').id]
  ),
  create_schedule_todo(
    name: '地域防災計画資料見直し', member_ids: [u('user2').id],
    start_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user2').id]
  ),
  create_schedule_todo(
    name: '会議資料作成', member_ids: [u('user1').id],
    start_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 16:00'),
    end_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 16:00'), priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user1').id]
  ),
  create_schedule_todo(
    name: '会議資料作成', member_ids: [u('user4').id],
    start_at: third_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: third_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '3',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user4').id]
  ),
  create_schedule_todo(
    name: 'ラジオ広報原稿作成', member_ids: [u('user3').id],
    start_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user3').id]
  ),
  create_schedule_todo(
    name: '事務用品発注', member_ids: [u('sys').id],
    start_at: @now + 6.months, end_at: @now + 6.months + 1.hour, priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '事務用品発注', member_ids: [u('user1').id],
    start_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:24'),
    end_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 19:24'), priority: '1',
    todo_state: 'finished', readable_setting_range: 'select',
    readable_member_ids: [u('user1').id]
  ),
  create_schedule_todo(
    cur_user: u("sys"), name: 'イベント資料作成', member_ids: [u('sys').id],
    start_at: forth_friday_of_month(base_date + 6.months).strftime('%Y-%m-%d 13:00'),
    end_at: forth_friday_of_month(base_date + 6.months).strftime('%Y-%m-%d 13:00'),
    priority: '2', todo_state: 'unfinished',
    readable_setting_range: 'select', readable_group_ids: [g('政策課').id]
  ),
  create_schedule_todo(
    name: '広報イベント販促資料作成', member_ids: [u('user3').id],
    start_at: second_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'),
    end_at: second_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'), priority: '2',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user3').id]
  ),
  create_schedule_todo(
    name: '広報計画資料作成', member_ids: [u('user5').id],
    start_at: second_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'),
    end_at: second_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'), priority: '2',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user5').id]
  ),
  create_schedule_todo(
    name: '打ち合わせ資料作成', member_ids: [u('user3').id], cur_user: u("user2"),
    start_at: forth_wednesday_of_month(base_date + 6.month).strftime('%Y-%m-%d 15:00'),
    end_at: forth_wednesday_of_month(base_date + 6.month).strftime('%Y-%m-%d 15:00'), priority: '3',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id,
    readable_setting_range: 'select',
    readable_member_ids: [u('user3').id]
  ),
  create_schedule_todo(
    name: '地域イベント資料作成', member_ids: [u('user2').id],
    start_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 13:00'),
    end_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 13:00'), priority: '3',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user2').id]
  ),
  create_schedule_todo(
    name: 'テレビ広報原稿作成', member_ids: [u('user3').id], cur_user: u("user3"),
    start_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user3').id]
  ),
  create_schedule_todo(
    name: '勉強会資料作成', member_ids: [u('sys').id],
    start_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 16:00'),
    end_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 16:00'), priority: '3',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_group_ids: [g('政策課').id], readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '企画セミナーレポート提出', member_ids: [u('sys').id],
    start_at: second_friday_of_month(base_date + 6.months).strftime('%Y-%m-%d 12:00'), priority: '3',
    end_at: second_friday_of_month(base_date + 6.months).strftime('%Y-%m-%d 12:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27', todo_state: 'finished',
    readable_setting_range: 'select',
    readable_group_ids: [g('政策課').id], readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '[地域振興イベント]資料作成', member_ids: [u('sys').id], cur_user: u("sys"),
    start_at: first_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 16:00'),
    end_at: first_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27', todo_state: 'unfinished',
    readable_setting_range: 'select', discussion_forum_id: @ds_forums[0].id,
    readable_group_ids: [g('政策課').id], readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '打ち合わせ資料作成', member_ids: [u('user2').id],
    start_at: forth_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    end_at: forth_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    priority: '1',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user2').id]
  ),
  create_schedule_todo(
    name: '広告事業計画作成', member_ids: [u('user5').id], cur_user: u("user5"),
    start_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_member_ids: [u('user5').id]
  ),
  create_schedule_todo(
    name: '佐賀出張計画作成', member_ids: [u('sys').id], cur_user: u("sys"),
    start_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27', priority: '1',
    todo_state: 'unfinished', readable_setting_range: 'select',
    readable_group_ids: [g('政策課').id]
  ),
  create_schedule_todo(
    name: 'アンケート資料整理', member_ids: [u('user3').id], cur_user: u("user3"),
    start_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    end_at: third_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id,
    readable_setting_range: 'select',
    readable_member_ids: [u('user3').id]
  ),
  create_schedule_todo(
    name: '出張レポート提出', member_ids: [u('admin').id],
    start_at: second_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    end_at: second_wednesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 15:00'),
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id,
    readable_setting_range: 'select', priority: '3',
    readable_member_ids: [u('admin').id]
  ),
  create_schedule_todo(
    name: '[サイト改善プロジェクト]レポート作成', member_ids: @users.map(&:id),
    start_at: second_tuesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 11:00'),
    end_at: second_tuesday_of_month(base_date + 6.months).strftime('%Y-%m-%d 12:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id, state: 'public'
  ),
  create_schedule_todo(
    name: '[サイト改善プロジェクト]定例会議資料作成', member_ids: @users.map(&:id), cur_user: u("sys"),
    start_at: first_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 12:00'),
    end_at: first_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d 12:00'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id, state: 'public'
  ),
  create_schedule_todo(
    name: '水防計画書作成', member_ids: [u('user2').id], cur_user: u("user2"),
    start_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'),
    end_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:00'), priority: '1',
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id,
    readable_setting_range: 'select',
    readable_member_ids: [u('user2').id]
  ),
  create_schedule_todo(
    name: 'プロジェクト計画書作成', member_ids: [u('admin').id],
    start_at: @now + 6.months, end_at: @now + 6.months + 1.hour, priority: '1',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id, state: 'select',
    readable_setting_range: 'select',
    readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: "#{@site_name}会議資料作成", member_ids: [u('admin').id],
    start_at: second_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: second_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    readable_setting_range: 'select', state: 'select', priority: '1', todo_state: 'finished',
    readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '地域振興イベントレポート提出', member_ids: [u('admin').id],
    start_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 18:30'),
    end_at: first_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 19:30'),
    repeat_plan_id: '5b04f29f66630c8f37e5bf27',
    todo_state: 'finished', discussion_forum_id: @ds_forums[0].id, state: 'public'
  ),
  create_schedule_todo(
    name: '事業継続計画資料作成', member_ids: [u('user4').id],
    start_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'), priority: '1',
    todo_state: 'unfinished', discussion_forum_id: @ds_forums[0].id, state: 'select',
    readable_setting_range: 'select',
    readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    name: '[サイト改善プロジェクト]要求仕様提出',
    member_ids: [
      u('admin').id, u('user1').id, u('user2').id,
      u('user4').id, u('user5').id, u('user3').id
    ],
    start_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    end_at: forth_monday_of_month(base_date + 6.months).strftime('%Y-%m-%d 17:00'),
    todo_state: 'finished', discussion_forum_id: @ds_forums[0].id, state: 'public',
    readable_setting_range: 'select',
    readable_member_ids: [u('sys').id]
  ),
  create_schedule_todo(
    cur_user: u("sys"), name: "プロジェクト計画書作成", member_ids: [u("sys").id],
    allday: "allday", readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
    start_on: third_thursday_of_month(base_date + 6.months).strftime('%Y-%m-%d'),
    group_ids: [g("政策課").id], priority: '2', todo_state: 'unfinished'
  )
]

# ## ------------------------------------
#
# puts "#monitor/topic"
# def create_monitor_topic(data)
#     create_item(Gws::Monitor::Topic, data)
# end
# @mt_posts = [
#   create_monitor_topic(
#     name: "庁舎防災設備強化",
#     see_type: "normal", state: 'public',
#     member_ids: %w(sys admin user1 user2 user3 user4 user5).map { |u| u(u).id },
#     seen: { u('user2').id.to_s => @now, u('user5').id.to_s => @noww
# },
#     category_ids: [@cr_cate[0].id]
#   ),
# ]

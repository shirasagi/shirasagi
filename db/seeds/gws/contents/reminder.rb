puts "# reminder"

def find_todo_by_name(name)
  @todos.find { |todo| todo.name == name }
end

def create_reminder(data)
  conditions = data.delete(:notifications)
  # item = create_item(Gws::Reminder, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id, name: data[:name] }
  item = Gws::Reminder.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save

  item.notifications.destroy_all
  conditions.each do |cond|
    notificaation = item.notifications.new
    notificaation.notify_at = cond[:notify_at]
    notificaation.state = cond[:state]
    notificaation.interval = cond[:interval]
    notificaation.interval_type = cond[:interval_type]
    notificaation.base_time = cond[:base_time]
    if notificaation.notify_at < @now
      notificaation.delivered_at = nil
    else
      notificaation.delivered_at = Time.zone.at(0)
    end
  end
  item.save!

  item
end

find_todo_by_name("[地域振興イベント]資料作成").tap do |item|
  create_reminder(
    cur_user: u('sys'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end

find_todo_by_name("企画セミナーレポート提出").tap do |item|
  create_reminder(
    cur_user: u('sys'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("勉強会資料作成").tap do |item|
  create_reminder(
    cur_user: u('sys'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("イベント資料作成").tap do |item|
  create_reminder(
    cur_user: u('sys'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("事務用品発注").tap do |item|
  %w(user1).each do |uid|
    create_reminder(
      cur_user: u(uid), name: item.reference_name, model: item.reference_model, item_id: item.id,
      date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
      notifications: [
        {
          notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
        }
      ]
    )
  end
end
find_todo_by_name("#{@site_name}会議資料作成").tap do |item|
  create_reminder(
    cur_user: u('admin'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("会議資料作成").tap do |item|
  %w(user1 user4).each do |uid|
    create_reminder(
      cur_user: u(uid), name: item.reference_name, model: item.reference_model, item_id: item.id,
      date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
      notifications: [
        {
          notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
        }
      ]
    )
  end
end
find_todo_by_name("地域イベント資料作成").tap do |item|
  create_reminder(
    cur_user: u('user2'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("打ち合わせ資料作成").tap do |item|
  %w(user2 user3).each do |uid|
    create_reminder(
      cur_user: u(uid), name: item.reference_name, model: item.reference_model, item_id: item.id,
      date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
      notifications: [
        {
          notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
        }
      ]
    )
  end
end
find_todo_by_name("地域防災計画資料見直し").tap do |item|
  create_reminder(
    cur_user: u('user2'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("テレビ広報原稿作成").tap do |item|
  create_reminder(
    cur_user: u('user3'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("広報イベント販促資料作成").tap do |item|
  create_reminder(
    cur_user: u('user3'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("ラジオ広報原稿作成").tap do |item|
  create_reminder(
    cur_user: u('user3'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("防災年間スケジュール作成").tap do |item|
  create_reminder(
    cur_user: u('user4'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end
find_todo_by_name("広報計画資料作成").tap do |item|
  create_reminder(
    cur_user: u('user5'), name: item.reference_name, model: item.reference_model, item_id: item.id,
    date: item.start_at, start_at: item.start_at, end_at: item.end_at, allday: item.allday, repeat_plan_id: item.repeat_plan_id,
    notifications: [
      {
        notify_at: item.start_at - 10.minutes, state: "enabled", interval: 10, interval_type: "minutes"
      }
    ]
  )
end

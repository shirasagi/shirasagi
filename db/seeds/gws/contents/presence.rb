puts "# user_presence"

def create_user_presence(uid, state, plan, memo)
  user = @users_hash[uid.to_s]
  return nil unless user

  user_presence = user.user_presence(@site)
  return user_presence if user_presence

  user_presence = Gws::UserPresence.new
  user_presence.cur_site = @site
  user_presence.cur_user = user
  user_presence.state = state
  user_presence.plan = plan
  user_presence.memo = memo
  user_presence.save!

  puts "#{user.name} #{user_presence.label :state} #{user_presence.plan} #{user_presence.memo}"

  user_presence
end

create_user_presence("sys", "available", "", "")
create_user_presence("admin", "available", "", "")
create_user_presence("user1", "available", "企画書作成 13:00 - 14:00", "オフィスにいます")
create_user_presence("user2", "available", "資料準備 13:00 - 14:00", "オフィスにいます")
create_user_presence("user3", "unavailable", "会議中", "1時間ほど席を外します")
create_user_presence("user4", "leave", "終日出張", "明日13:00頃に帰社予定です")
create_user_presence("user5", "dayoff", "休暇中", "来週より出社予定です")

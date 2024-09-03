puts "# group superior"

[ %w(政策課 admin), %w(広報課 user3), %w(管理課 user4), %w(防災課 user3) ].each do |group_name, superior_user_uid|
  group = g(group_name)
  user = u(superior_user_uid)

  superior_user_ids = group.superior_user_ids.dup
  superior_user_ids << user.id
  superior_user_ids.uniq!
  superior_user_ids.sort!

  group.without_record_timestamps do
    group.superior_user_ids = superior_user_ids
    unless group.save
      puts group.save.full_messages
    end
  end
end

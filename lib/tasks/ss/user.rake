namespace :ss do
  task :create_user => :environment do
    cond = { name: "システム管理", permissions: Sys::Role.permission_names }
    role = Sys::Role.find_or_create_by cond

    data = eval(ENV["data"])
    data[:sys_role_ids] = [role.id]
    data[:in_password]  = data[:password]
    data.delete(:password)

    if item = SS::User.where(email: data[:email]).first
      item.update data
      puts item.errors.empty? ? "  updated  #{item.name}" : item.errors.full_messages.join("\n  ")
    else
      item = SS::User.create data
      puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")
    end
  end
end

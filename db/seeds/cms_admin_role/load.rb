# Usage:
#   rake db:seed name=cms_admin_role user=admin site=www

def error(msg)
  puts msg
  exit
end

error("Please input user name. ( user=[id or uid or email] )") if ENV["user"].blank?

# user
if ENV["user"] =~ /^\d+$/
  cond = { id: ENV["user"] }
elsif ENV["user"] =~ /@/
  cond = { email: ENV["user"] }
else
  cond = { uid: ENV["user"] }
end
user = Cms::User.where(cond).first
error("User not found: #{ENV['user']}") unless user

# site
site = Cms::Site.where(host: ENV["site"]).first
error("Site not found: #{ENV['site']}") unless site

# role
role = Cms::Role.find_or_create_by name: "#{site.name} 管理者", site_id: site.id
role.update permission_level: 3, permissions: Cms::Role.permission_names

# user's role
user.add_to_set cms_role_ids: role.id

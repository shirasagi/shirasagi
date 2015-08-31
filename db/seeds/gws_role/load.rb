# Usage:
#   rake db:seed name=gws_role user=admin site=シラサギ市

# user
if ENV["user"] =~ /^\d+$/
  cond = { id: ENV["user"] }
elsif ENV["user"] =~ /@/
  cond = { email: ENV["user"] }
else
  cond = { uid: ENV["user"] }
end
user = Gws::User.find_by(cond)

# site

# role
role = Gws::Role.find_or_create_by name: "GWS管理者"
role.update permission_level: 3, permissions: Gws::Role.permission_names

# user's role
user.update gws_role_ids: [role.id]

def sys_user
  sys_user = SS::User.where(email: build(:sys_user).email).first
  sys_user ||= create(:sys_user, sys_role_ids: [sys_role.id])
  sys_user
end

def sys_role
  sys_role = Sys::Role.where(name: build(:sys_role_admin).name).first
  sys_role ||= create(:sys_role_admin)
  sys_role
end

def login_sys_user(to: nil)
  login_user sys_user, to: to
end

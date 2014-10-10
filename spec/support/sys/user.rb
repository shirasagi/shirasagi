def sys_user
  return @sys_user if @sys_user ||= Sys::User.where(email: build(:sys_user).email).first
  @sys_user = create(:sys_user, sys_role_ids: [sys_role.id])
end

def sys_role
  return @sys_role if @sys_role ||= Cms::Role.where(name: build(:sys_user_role).name).first
  @sys_role = create(:sys_user_role)
end

def login_sys_user
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: sys_user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

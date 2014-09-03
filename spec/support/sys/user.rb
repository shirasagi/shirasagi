# coding: utf-8
def sys_user
  return @sys_user if @sys_user ||= Sys::User.where(email: build(:sys_user).email).first
  role = create(:sys_user_role, permissions: Sys::Role.permission_names.map { |k, v| v })
  @sys_user = create(:sys_user, sys_role_ids: [role.id])
end

def login_sys_user
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: sys_user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

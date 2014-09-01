# coding: utf-8
def sys_user
  return @cur_user if @cur_user
  user = build(:sys_user)
  @cur_user = Sys::User.where(email: user.email).first
  @cur_user ? @cur_user : @cur_user = create(:sys_user)
end

def login_sys_user
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: sys_user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

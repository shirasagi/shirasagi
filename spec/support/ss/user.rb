def ss_user
  return @ss_user if @ss_user ||= Sys::User.where(email: build(:ss_user).email).first
  @ss_user = create(:ss_user)
end

def login_ss_user
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: ss_user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

def login_service_account(user)
  visit service_login_path
  within "form" do
    fill_in "item[account]", with: user.account
    fill_in "item[password]", with: user.in_password
    click_button "ログイン"
  end
end

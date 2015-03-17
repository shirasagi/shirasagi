def ss_user
  ss_user = SS::User.where(email: build(:ss_user).email).first
  ss_user ||= create(:ss_user)
  ss_user
end

def ss_group
  ss_group = SS::Group.where(name: build(:ss_group).name).first
  ss_group ||= create(:ss_group)
  ss_group
end

def ss_site
  ss_site = SS::Site.where(host: build(:ss_site).host).first
  ss_site ||= create(:ss_site, group_ids: [ss_group.id])
  ss_site
end

def login_user(user)
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

def login_ss_user
  login_user ss_user
end

def cms_user
  return @cms_user if @cms_user ||= Cms::User.where(email: build(:cms_user).email).first
  @cms_user = create(:cms_user, group_ids: [cms_group.id], cms_role_ids: [cms_role.id])
end

def cms_group
  return @cms_group if @cms_group ||= Cms::Group.where(name: build(:cms_group).name).first
  @cms_group = create(:cms_group)
end

def cms_site
  return @cms_site if @cms_site ||= Cms::Site.where(host: build(:cms_site).host).first
  @cms_site = create(:cms_site, group_ids: [cms_group.id])
end

def cms_role
  return @cms_role if @cms_role ||= Cms::Role.where(name: build(:cms_user_role).name).first
  @cms_role = create(:cms_user_role, site_id: cms_site.id)
end

def login_cms_user
  visit sns_login_path
  within "form" do
    fill_in "item[email]", with: cms_user.email
    fill_in "item[password]", with: "pass"
    click_button "ログイン"
  end
end

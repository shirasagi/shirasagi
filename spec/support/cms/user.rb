def cms_user
  cms_user = Cms::User.where(email: build(:cms_user).email).first
  cms_user ||= create(:cms_user, group: cms_group, role: cms_role)
  cms_user.cur_site = cms_site
  cms_user
end

def cms_group
  cms_group = Cms::Group.where(name: build(:cms_group).name).first
  cms_group ||= create(:cms_group)
  cms_group
end

def cms_site
  cms_site = Cms::Site.where(host: build(:cms_site).host).first
  cms_site ||= create(:cms_site, group_ids: [cms_group.id])
  cms_site
end

def cms_role
  cms_role = Cms::Role.where(name: build(:cms_user_role).name).first
  cms_role ||= create(:cms_user_role, site_id: cms_site.id)
  cms_role
end

def login_cms_user
  login_user cms_user
end

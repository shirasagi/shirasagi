def create_affair_users
  site = Gws::Group.create(name: "庶務事務市", order: 10)
  role = Gws::Role.create(
    name: I18n.t('gws.roles.admin'),
    site_id: site.id,
    permissions: Gws::Role.permission_names,
    permission_level: 3
  )
  user = Gws::User.create(name: "管理者", uid: "sup", in_password: "pass",
    group_ids: [site.id], gws_role_ids: [role.id], organization_id: site.id,
    deletion_lock_state: "locked"
  )

  # import groups
  item = Gws::Group.new
  item.cur_site = site
  item.cur_user = user
  item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_groups.csv")
  item.import
  puts "import affair groups : #{Gws::Group.all.count}"

  # import roles
  item = Gws::Role.new
  item.cur_site = site
  item.cur_user = user
  item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_roles.csv")
  item.import
  puts "import affair roles : #{Gws::Role.all.count}"

  # import user titles
  ss_file = SS::TempFile.new
  ss_file.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_user_titles.csv")
  ss_file.save
  Gws::UserTitleImportJob.bind(site_id: site.id, user_id: user.id).perform_now(ss_file.id)
  puts "import affair user titles : #{Gws::UserTitle.all.count}"

  # import users
  item = Gws::UserCsv::Importer.new
  item.cur_site = site
  item.cur_user = user
  item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_users.csv")
  item.import
  puts "import affair users : #{Gws::User.all.count}"

  # import capitals
  year = Gws::Affair::CapitalYear.create(
    cur_site: site,
    cur_user: user,
    name: "令和2年",
    code: 2020,
    start_date: Time.zone.parse("2020/04/01"),
    close_date: Time.zone.parse("2021/03/31")
  )
  year.save!

  item = Gws::Affair::Capital.new
  item.cur_site = site
  item.cur_user = user
  item.year = year
  item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/capitals.csv")
  item.import
  puts "import affair capitals : #{Gws::Affair::Capital.all.count}"

  # import special leaves
  item = Gws::Affair::SpecialLeave.new
  item.cur_site = site
  item.cur_user = user
  item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/special_leaves.csv")
  item.import
  puts "import special leaves : #{Gws::Affair::SpecialLeave.all.count}"

  # 総務課
  item = Gws::Affair::Capital.site(site).find_by(
    year_id: year.id,
    article_code: 2,
    section_code: 1,
    subsection_code: 1,
    project_code: 693,
    detail_code: 78
  )
  g = Gws::Group.find_by(name: "庶務事務市/市長・副市長/総務部/総務課")
  item.member_group_ids = [g.id] + g.descendants.pluck(:id)
  item.save!
end

def affair_site
  Gws::Group.find_by(name: "庶務事務市")
end

def affair_user(uid)
  Gws::User.find_by(uid: uid)
end

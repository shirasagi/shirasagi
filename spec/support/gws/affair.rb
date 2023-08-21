def create_affair_users
  Gws::AffairSupport.create_users
end

def affair_site
  Gws::AffairSupport.site
end

def affair_user(uid)
  Gws::AffairSupport.user(uid)
end

module Gws
  module AffairSupport
    module_function

    def site
      Gws::Group.find_by(name: "庶務事務市")
    end

    def user(uid)
      Gws::User.find_by(uid: uid)
    end

    def sup
      user("sup")
    end

    def create_users
      Gws::Group.create(name: "庶務事務市", order: 10)
      role = Gws::Role.find_or_create_by(
        name: I18n.t('gws.roles.admin'),
        site_id: site.id,
        permissions: Gws::Role.permission_names,
        permission_level: 3
      )
      Gws::User.create(name: "管理者", uid: "sup", in_password: "pass",
        group_ids: [site.id], gws_role_ids: [role.id], organization_id: site.id,
        deletion_lock_state: "locked"
      )

      import_groups
      import_roles
      import_user_titles
      import_users
      import_capitals
      import_special_leaves
    end

    def import_groups
      item = Gws::Group.new
      item.cur_site = site
      item.cur_user = sup
      item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_groups.csv")
      item.import
      puts "import affair groups : #{Gws::Group.all.count}"
    end

    def import_roles
      item = Gws::Role.new
      item.cur_site = site
      item.cur_user = sup
      item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_roles.csv")
      item.import
      puts "import affair roles : #{Gws::Role.all.count}"
    end

    def import_user_titles
      ss_file = SS::TempFile.new
      ss_file.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_user_titles.csv")
      ss_file.save
      Gws::UserTitleImportJob.bind(site_id: site.id, user_id: sup.id).perform_now(ss_file.id)
      puts "import affair user titles : #{Gws::UserTitle.all.count}"
    end

    def import_users
      item = Gws::UserCsv::Importer.new
      item.cur_site = site
      item.cur_user = sup
      item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/affair_users.csv")
      item.import
      puts "import affair users : #{Gws::User.all.count}"
    end

    def import_capitals
      year = Gws::Affair::CapitalYear.create(
        cur_site: site,
        cur_user: sup,
        name: "令和2年",
        code: 2020,
        start_date: Time.zone.parse("2020/04/01"),
        close_date: Time.zone.parse("2021/03/31")
      )
      year.save!

      item = Gws::Affair::Capital.new
      item.cur_site = site
      item.cur_user = sup
      item.year = year
      item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/capitals.csv")
      item.import
      puts "import affair capitals : #{Gws::Affair::Capital.all.count}"

      # 総務課
      item = Gws::Affair::Capital.site(site).find_by(
        year_id: year.id,
        article_code: 2,
        section_code: 1,
        subsection_code: 1,
        project_code: 693,
        detail_code: 78)
      group = Gws::Group.find_by(name: "庶務事務市/市長・副市長/総務部/総務課")
      item.member_group_ids = [group.id] + group.descendants.pluck(:id)
      item.save!
    end

    def import_special_leaves
      item = Gws::Affair::SpecialLeave.new
      item.cur_site = site
      item.cur_user = sup
      item.in_file = Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/gws/affair/special_leaves.csv")
      item.import
      puts "import special leaves : #{Gws::Affair::SpecialLeave.all.count}"
    end
  end
end

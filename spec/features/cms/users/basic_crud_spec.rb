require 'spec_helper'

describe "cms_users", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:item) { create(:cms_test_user, group: group) }
  let(:index_path) { cms_users_path site.id }
  let(:new_path) { new_cms_user_path site.id }
  let(:show_path) { cms_user_path site.id, item }
  let(:edit_path) { edit_cms_user_path site.id, item }
  let(:delete_path) { delete_cms_user_path site.id, item }
  let(:import_path) { import_cms_users_path site.id }

  context "with login", js: true do
    it "#crud" do
      login_cms_user

      #index
      visit index_path
      expect(current_path).to eq index_path

      #new
      visit new_path
      click_on I18n.t("ss.apis.groups.index")
      wait_for_cbox do
        click_on group.name
      end

      within "#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: "pass"
        check "item[cms_role_ids][]"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      #show
      visit show_path
      expect(page).to have_content(item.name)

      #edit
      visit edit_path
      within "#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      #delete
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-items", count: 1)

      #lock_all
      within ".index-search" do
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-items", count: 1)

      find('.list-head label.check input').set(true)
      click_button I18n.t('ss.links.lock_user')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.lock_user_all'))
      expect(page).to have_no_content(item.name)

      #unlock_all
      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.all'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-items", count: 1)

      find('.list-head label.check input').set(true)
      click_button I18n.t('ss.links.unlock_user')
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.unlock_user_all'))
      expect(page).to have_no_content(item.name)

      # delete_all
      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-items", count: 1)

      find('.list-head label.check input').set(true)
      click_button I18n.t("ss.links.delete")
      page.accept_alert
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".index-search" do
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_content(item.name)
    end
  end

  context "with ldap user", js: true do
    it "#new" do
      login_cms_user

      visit new_path
      click_on I18n.t("ss.apis.groups.index")
      wait_for_cbox do
        click_on group.name
      end

      within "form#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[uid]", with: name
        expect(page).to have_css('#item_uid_errors', text: '')
        fill_in "item[ldap_dn]", with: "dc=#{name},dc=city,dc=example,dc=jp"
        check "item[cms_role_ids][]"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      login_cms_user
      visit show_path
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      login_cms_user
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      login_cms_user
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end

  context "import from csv" do
    before(:each) do
      g1 = create(:cms_group, name: "A", order: 10)
      g2 = create(:cms_group, name: "A/B", order: 20)
      g3 = create(:cms_group, name: "A/B/C", order: 30)
      g4 = create(:cms_group, name: "A/B/D", order: 40)
      r1 = create(:cms_role, name: "all")
      r1 = create(:cms_role, name: "edit")
      cms_site.add_to_set(group_ids: [g1.id, g2.id, g3.id, g4.id])
    end

    it "#import" do
      login_cms_user
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      users = Cms::User.site(cms_site).ne(id: cms_user.id)
      expected_emails = %w(
        import_admin@example.jp
        import_sys@example.jp
        import_user1@example.jp
        import_user2@example.jp
      )
      expected_names = %w(import_admin import_sys import_user1 import_user2)
      expected_uids = %w(import_admin import_sys import_user1 import_user2)
      expected_groups = [ %w(A/B/C), %w(A), %w(A/B/C A/B/D), %w(A/B/D) ]
      expected_cms_roles = [ %w(all), %w(all edit), %w(edit), %w(edit) ]
      expected_initial_password_warning = [ 1, 1, 1, 1 ]

      expect(users.map(&:name)).to eq expected_names
      expect(users.map(&:email)).to eq expected_emails
      expect(users.map(&:uid)).to eq expected_uids
      expect(users.map{ |u| u.groups.map(&:name) }).to eq expected_groups
      expect(users.map{ |u| u.cms_roles.order_by(name: 1).map(&:name) }).to eq expected_cms_roles
      expect(users.map(&:initial_password_warning)).to eq expected_initial_password_warning
    end

    context "with invalid group in csv" do
      before do
        cms_site.set(group_ids: [cms_group.id])
      end

      it "#import" do
        login_cms_user
        visit import_path
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv"
          click_button I18n.t('ss.buttons.import')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq import_path
        expect(page).to have_selector('#errorExplanation ul li', count: 9)
      end
    end
  end

  context "ss-1252" do
    before(:each) do
      g1 = create(:cms_group, name: "A", order: 10)
      g2 = create(:cms_group, name: "A/B", order: 20)
      g3 = create(:cms_group, name: "A/B/C", order: 30)
      g4 = create(:cms_group, name: "A/B/D", order: 40)
      r1 = create(:cms_role, name: "all")
      r1 = create(:cms_role, name: "edit")
      cms_site.add_to_set(group_ids: [g1.id, g2.id, g3.id, g4.id])
    end

    it "#import" do
      login_cms_user
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/user/cms_users_2.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      users = Cms::User.site(cms_site).ne(id: cms_user.id)
      expected_emails = %w(
        import_admin_update@example.jp
        import_sys@example.jp
      )
      expected_names = %w(import_admin_update import_sys)
      expected_uids = [nil, "import_sys"]
      expected_groups = [ %w(A/B), %w(A) ]
      expected_cms_roles = [ %w(all), %w(all edit) ]
      expected_initial_password_warning = [ nil, nil ]

      expect(users.map(&:name)).to eq expected_names
      expect(users.map(&:email)).to eq expected_emails
      expect(users.map(&:uid)).to eq expected_uids
      expect(users.map{ |u| u.groups.map(&:name) }).to match_array expected_groups
      expect(users.map{ |u| u.cms_roles.order_by(name: 1).map(&:name) }).to eq expected_cms_roles
      expect(users.map(&:initial_password_warning)).to eq expected_initial_password_warning

      user1 = Cms::User.site(cms_site).unscoped.ne(id: cms_user.id).where(uid: "import_user1").first
      user2 = Cms::User.site(cms_site).unscoped.ne(id: cms_user.id).where(uid: "import_user2").first
      expect(user1).not_to be_nil
      expect(user2).not_to be_nil
    end
  end

  context "ss-1075" do
    let(:site2) { create(:cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp") }
    let(:role) do
      create(
        :cms_role,
        cur_site: site,
        name: I18n.t("sys.roles.admin") + "1",
        permissions: Cms::Role.permission_names
      )
    end
    let(:role2) do
      create(
        :cms_role,
        cur_site: site2,
        name: I18n.t("sys.roles.admin") + "2",
        permissions: Cms::Role.permission_names
      )
    end
    let(:header) do
      %w(
        id name kana uid organization_uid email password tel tel_ext account_start_date account_expiration_date
        initial_password_warning organization_id groups ldap_dn cms_roles
      ).map { |k| Cms::User.new.t(k) }.join(",")
    end

    before do
      item.cms_role_ids = [ role.id, role2.id ]
      item.save!

      login_cms_user
    end

    it do
      visit index_path
      click_on I18n.t("ss.buttons.download")

      csv = page.html.encode("UTF-8")
      expect(csv).to include(header)
      expect(csv.split("\n").length).to eq 3
    end
  end

  context "disable user and edit it" do
    let(:user_name) { unique_id }
    let!(:test_user) { create(:cms_test_user, group: group, name: user_name) }
    let(:account_expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
    let(:kana) { unique_id }

    before do
      login_cms_user
    end

    it do
      visit index_path
      expect(page).to have_css(".list-item .title", text: user_name)

      click_on user_name
      click_on I18n.t("ss.links.edit")

      fill_in "item[account_expiration_date]", with: account_expiration_date.strftime("%Y/%m/%d %H:%M")
      click_on I18n.t("ss.buttons.save")

      test_user.reload
      expect(test_user.account_expiration_date).to eq account_expiration_date

      visit index_path
      expect(page).to have_no_css(".list-item .title", text: user_name)

      select I18n.t("ss.options.state.all"), from: "s[state]"
      click_on I18n.t('ss.buttons.search')

      expect(page).to have_css(".list-item .title", text: user_name)

      click_on user_name
      click_on I18n.t("ss.links.edit")

      fill_in "item[kana]", with: kana
      click_on I18n.t("ss.buttons.save")

      test_user.reload
      expect(test_user.kana).to eq kana
    end
  end

  context "edit user joined only disabled group" do
    let(:expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
    let!(:group1) { create(:cms_group, name: "#{group.name}/#{unique_id}", order: 100, expiration_date: expiration_date) }
    let(:user_name) { unique_id }
    let!(:test_user) { create(:cms_test_user, group: group1, name: user_name) }
    let(:kana) { unique_id }

    before do
      login_cms_user
    end

    it do
      expect(group1.active?).to be_falsey

      visit index_path
      expect(page).to have_css(".list-item .title", text: user_name)

      click_on user_name
      expect(page).to have_css("#addon-basic dd", text: group1.name)
      click_on I18n.t("ss.links.edit")

      fill_in "item[kana]", with: kana
      click_on I18n.t("ss.buttons.save")

      test_user.reload
      expect(test_user.kana).to eq kana
    end
  end

  context "when user joined only disabled group is logged-in" do
    let(:expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
    let!(:group1) { create(:cms_group, name: "#{group.name}/#{unique_id}", order: 100, expiration_date: expiration_date) }
    let!(:test_user) { create(:cms_test_user, group: group1, name: unique_id) }

    before do
      site = cms_site
      site.add_to_set(group_ids: [group1.id])

      login_user test_user
    end

    it do
      visit sns_mypage_path
      expect(status_code).to eq 200
      expect(page).to have_no_css(".mypage-sites .title", text: cms_site.name)

      visit cms_contents_path(site)
      expect(status_code).to eq 403
    end
  end

  context "when disalbed user is logged-in" do
    let(:account_expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
    let!(:test_user) { create(:cms_test_user, group: group, name: unique_id, account_expiration_date: account_expiration_date) }

    it do
      login_user test_user
      expect(status_code).to eq 200
      expect(current_path).to eq sns_login_path
      expect(page).to have_css(".error-message", text: I18n.t("sns.errors.invalid_login"))

      visit sns_mypage_path
      expect(status_code).to eq 200
      expect(current_path).to eq sns_login_path

      visit cms_contents_path(site)
      expect(status_code).to eq 200
      expect(current_path).to eq sns_login_path
    end
  end
end

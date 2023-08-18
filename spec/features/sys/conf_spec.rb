require 'spec_helper'

describe "sys_conf", type: :feature, dbscope: :example do
  context "with user which is permitted all" do
    before do
      role = create(:sys_role_admin, name: unique_id)
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      first('.main-navi .sys-conf a').click
      within 'nav.mod-navi' do
        expect(page).to have_css('h2', text: I18n.t("sys.conf"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.site"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.group"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.user"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.role"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.auth"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.max_file_size"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.site_copy"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.diag"))
        expect(page).to have_css('h3 a', text: I18n.t("history.log"))
        expect(page).to have_css('h3 a', text: I18n.t("job.main"))
      end
    end
  end

  context "with user which is permitted only edit_sys_groups" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_groups))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      first('.main-navi .sys-conf a').click
      within 'nav.mod-navi' do
        expect(page).to have_css('h2', text: I18n.t("sys.conf"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.group"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.user"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.role"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.auth"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.max_file_size"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site_copy"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.diag"))
        expect(page).to have_no_css('h3 a', text: I18n.t("history.log"))
        expect(page).to have_no_css('h3 a', text: I18n.t("job.main"))
      end
    end
  end

  context "with user which is permitted only edit_sys_roles" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_roles))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      first('.main-navi .sys-conf a').click
      within 'nav.mod-navi' do
        expect(page).to have_css('h2', text: I18n.t("sys.conf"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.group"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.user"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.role"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.auth"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.max_file_size"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site_copy"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.diag"))
        expect(page).to have_no_css('h3 a', text: I18n.t("history.log"))
        expect(page).to have_no_css('h3 a', text: I18n.t("job.main"))
      end
    end
  end

  context "with user which is permitted only edit_sys_sites" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_sites))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      first('.main-navi .sys-conf a').click
      within 'nav.mod-navi' do
        expect(page).to have_css('h2', text: I18n.t("sys.conf"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.site"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.group"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.user"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.role"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.auth"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.max_file_size"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.site_copy"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.diag"))
        expect(page).to have_no_css('h3 a', text: I18n.t("history.log"))
        expect(page).to have_no_css('h3 a', text: I18n.t("job.main"))
      end
    end
  end

  context "with user which is permitted only edit_sys_users" do
    before do
      role = create(:sys_role, name: unique_id, permissions: %w(edit_sys_users))
      user = create(:sys_user_sample, sys_role_ids: [role.id])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      first('.main-navi .sys-conf a').click
      within 'nav.mod-navi' do
        expect(page).to have_css('h2', text: I18n.t("sys.conf"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.group"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.user"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.role"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.auth"))
        expect(page).to have_no_css('h3 a', text: I18n.t("sys.site_copy"))
        expect(page).to have_css('h3 a', text: I18n.t("sys.diag"))
        expect(page).to have_css('h3 a', text: I18n.t("history.log"))
        expect(page).to have_css('h3 a', text: I18n.t("job.main"))
      end
    end
  end

  context "with user which is permitted nothing" do
    before do
      user = create(:sys_user_sample, sys_role_ids: [])
      login_user user
    end

    it "#index" do
      visit sns_mypage_path
      expect(page).to have_no_css('.main-navi .sys-conf a')
    end
  end
end

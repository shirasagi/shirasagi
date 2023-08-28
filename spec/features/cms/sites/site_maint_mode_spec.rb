require 'spec_helper'

describe "maint mode", type: :feature, dbscope: :example, js: true do
  let(:name) { "name-#{unique_id}" }
  let(:name2) { "modify-#{unique_id}" }
  let(:host) { unique_id }
  let(:domain) { unique_domain }
  let!(:site1) { cms_site }
  let!(:site2) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: cms_user.group_ids) }
  let(:index_path) { cms_site_path site1.id }
  let!(:user1) { create :sys_user, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id] }
  let!(:user2) { create :sys_user, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id], email: unique_email }

  before { login_cms_user }

  context "maintenance_mode is disabled" do
    it do
      visit index_path
      expect(page).to have_no_css(".maint-mode-text")
    end
  end

  context "maintenance_mode is enabled" do
    let(:maint_remark) { "今日から明日までメンテナンスになります。" }
    it do
      visit index_path
      click_on I18n.t("ss.links.edit")
      ensure_addon_opened "#addon-ss-agents-addons-maintenance_mode"
      within "form#item-form" do
        find("#item_maintenance_mode").find("option[value='enabled']").select_option
        fill_in "item[maint_remark]", with: maint_remark

        wait_cbox_open do
          within ".maint-mode" do
            click_on I18n.t("ss.apis.users.index")
          end
        end
      end
      wait_for_cbox do
        within ".items" do
          wait_cbox_close do
            click_on cms_user.name
          end
        end
      end
      within "#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      site1.reload
      expect(site1.maintenance_mode).to eq "enabled"

      visit sns_mypage_path
      expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
      expect(page).to have_link(site1.name, href: "/.s#{site1.id}/cms/contents")
      click_on site1.name
      expect(page).to have_no_css(".maint-mode-text")
      visit sns_logout_path

      # 除外ユーザーではないユーザーでログイン
      within "form" do
        fill_in "item[email]", with: user2.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      I18n.with_locale(user2.lang.try(:to_sym) || I18n.default_locale) do
        visit sns_mypage_path
        expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
        expect(page).to have_no_link(site1.name, href: "/.s#{site1.id}/cms/contents")

        visit cms_contents_path(site: site1)
        expect(page).to have_text(site1.maint_remark)

        visit cms_contents_path(site: site2)
        expect(page).to have_no_text(site1.maint_remark)
      end
    end
  end
end

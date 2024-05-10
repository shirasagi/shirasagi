require 'spec_helper'

describe "maint mode", type: :feature, dbscope: :example, js: true do
  let(:name) { "name-#{unique_id}" }
  let(:name2) { "modify-#{unique_id}" }
  let(:host) { unique_id }
  let(:domain) { unique_domain }
  let!(:group1) { create :cms_group, name: unique_id }
  let!(:group2) { create :cms_group, name: unique_id }
  let!(:site1) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: [ group1.id ]) }
  let!(:site2) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: [ group2.id ]) }
  let!(:site1_role) { create :cms_role_admin, cur_site: site1 }
  let!(:site2_role) { create :cms_role_admin, cur_site: site2 }
  let!(:site1_user1) { create :cms_test_user, group_ids: site1.group_ids, cms_role_ids: [ site1_role.id ] }
  let!(:site1_user2) { create :cms_test_user, group_ids: site1.group_ids, cms_role_ids: [ site1_role.id ] }
  let!(:site2_user1) { create :cms_test_user, group_ids: site2.group_ids, cms_role_ids: [ site2_role.id ] }

  before { login_user site1_user1 }

  context "maintenance_mode is disabled" do
    it do
      visit cms_contents_path(site: site1)
      expect(page).to have_no_css(".maint-mode-text")
    end
  end

  context "maintenance_mode is enabled" do
    let(:maint_remark) { "今日から明日までメンテナンスになります。" }

    it do
      visit cms_site_path(site: site1)
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
        expect(page).to have_css(".list-item", text: site1_user1.name)
        expect(page).to have_css(".list-item", text: site1_user2.name)
        expect(page).to have_no_css(".list-item", text: site2_user1.name)
        within ".items" do
          wait_cbox_close do
            click_on site1_user1.name
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

      visit cms_contents_path(site: site1)
      expect(page).to have_no_css(".maint-mode-text")

      # 除外ユーザーではないユーザーでログイン
      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: site1_user2.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      I18n.with_locale(site1_user2.lang.try(:to_sym) || I18n.default_locale) do
        visit sns_mypage_path
        expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
        expect(page).to have_no_link(site1.name, href: "/.s#{site1.id}/cms/contents")

        visit cms_contents_path(site: site1)
        expect(page).to have_css(".maint-mode-text", text: site1.maint_remark)
      end

      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: site2_user1.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      I18n.with_locale(site2_user1.lang.try(:to_sym) || I18n.default_locale) do
        visit cms_contents_path(site: site2)
        expect(page).to have_no_css(".maint-mode-text")
      end
    end
  end
end

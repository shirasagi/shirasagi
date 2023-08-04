require 'spec_helper'

describe "maint mode", type: :feature, dbscope: :example, js: true do
  let(:name) { "name-#{unique_id}" }
  let(:name2) { "modify-#{unique_id}" }
  let(:host) { unique_id }
  let(:domain) { unique_domain }
  let!(:site1) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: cms_user.group_ids) }
  let!(:site2) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: cms_user.group_ids) }
  let(:user1) { create :sys_user, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id] }
  let(:user2) { create :sys_user, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id], email: unique_email }
  let(:maint_remark) { "今日から明日までメンテナンスになります。" }

  before { login_user user1 }

  it "disabled" do
    visit sns_mypage_path
    click_on site1.name
    expect(page).to have_no_css(".maint-mode-text")
  end

  it "enabled" do
    visit sys_sites_path
    click_on site1.name
    click_on I18n.t("ss.links.edit")
    within "form#item-form" do
      ensure_addon_opened "#addon-ss-agents-addons-maintenance_mode"
      within "#addon-ss-agents-addons-maintenance_mode" do
        select I18n.t("ss.options.state.enabled"), from: "item[maintenance_mode]"
        fill_in "item[maint_remark]", with: maint_remark

        wait_cbox_open { click_on I18n.t("ss.apis.users.index") }
      end
    end
    wait_for_cbox do
      within ".items" do
        wait_cbox_close { click_on user1.name }
      end
    end
    within "#item-form" do
      within "#addon-ss-agents-addons-maintenance_mode" do
        expect(page).to have_css("[data-id='#{user1.id}']", text: user1.name)
      end
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    site1.reload
    expect(site1.maintenance_mode).to eq "enabled"
    expect(site1.maint_remark).to eq maint_remark

    # 除外ユーザーでログイン
    login_user user1
    visit sns_mypage_path
    expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
    expect(page).to have_link(site1.name, href: "/.s#{site1.id}/cms/contents")
    click_on site1.name
    expect(page).to have_no_css(".maint-mode-text")

    # 除外ユーザーではないユーザーでログイン
    login_user user2
    visit sns_mypage_path
    expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
    expect(page).to have_no_link(site1.name, href: "/.s#{site1.id}/cms/contents")
    visit cms_contents_path(site: site1)
    expect(page).to have_css(".maint-mode-text", text: site1.maint_remark)

    visit cms_contents_path(site: site2)
    expect(page).to have_css(".list-head", text: I18n.t("cms.content", locale: I18n.default_locale))
    expect(page).to have_no_css(".maint-mode-text")
    expect(page).to have_no_text(site1.maint_remark)
  end
end

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
    find("#addon-ss-agents-addons-maintenance_mode").click
    within "form#item-form" do
      find("#item_maintenance_mode").find("option[value='enabled']").select_option
      fill_in "item[maint_remark]", with: "今日から明日までメンテナンスになります。"
      within ".maint-mode" do
        click_on I18n.t("ss.apis.users.index")
      end
    end
    wait_for_cbox do
      within ".items" do
        click_on user1.name
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
      click_button I18n.t("ss.login", locale: I18n.default_locale)
    end
    expect(page).to have_text(I18n.t("ss.under_maintenance_mode"))
    expect(page).not_to have_link(site1.name, href: "/.s#{site1.id}/cms/contents")
    visit cms_contents_path(site: site1)
    expect(page).to have_text(site1.maint_remark)

    visit cms_contents_path(site: site2)
    expect(page).not_to have_text(site1.maint_remark)
  end
end

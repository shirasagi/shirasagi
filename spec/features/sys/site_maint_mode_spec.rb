require 'spec_helper'

describe "maint mode", type: :feature, dbscope: :example, js: true do
  let(:name) { "name-#{unique_id}" }
  let(:name2) { "modify-#{unique_id}" }
  let(:host) { unique_id }
  let(:domain) { unique_domain }
  let!(:site1) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: cms_user.group_ids) }
  let!(:site2) { create(:cms_site, name: unique_id, host: unique_id, domains: unique_domain, group_ids: cms_user.group_ids) }
  let(:user1) { create :sys_user, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id] }
  let(:user2) { create :sys_user_sample, group_ids: cms_user.group_ids, sys_role_ids: [sys_role.id] }

  before { login_user user1 }

  context "enabled" do
    it "maint mode is disabled" do
      visit sns_mypage_path
      click_on site1.name
      expect(page).to have_css(".list-head")
      expect(page).to have_no_css(".maint-mode-text")
    end
  end

  context "enabled" do
    it do
      visit sys_sites_path
      click_on site1.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        find("#item_maint_mode").find("option[value='enabled']").select_option
        fill_in "item[maint_remarks]", with: "今日から明日までメンテナンスになります。"
        within ".maint-mode" do
          click_on "ユーザーを選択する"
        end

        wait_for_ajax
        save_full_screenshot
        # find('.items input[type="checkbox"][value="2"]').set(set)
        # click_on "ユーザーを設定する"
        click_on user1.name

        save_full_screenshot
        click_on I18n.t('ss.buttons.save')
      end


    end
  end
end

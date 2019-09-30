require 'spec_helper'

describe "gws_affair_groups", type: :feature, dbscope: :example, js: true do
  before { create_affair_users }
  let(:site) { affair_site }

  context "group_code" do
    before { login_gws_user }
    let(:item) { Gws::Group.where(name: "庶務事務市/市長・副市長/総務部/総務課").first }
    let(:show_path) { gws_group_path site, item }

    let(:group_code1) { "310100" }
    let(:group_code2) { unique_id }

    it "#index" do
      visit show_path
      within "#addon-gws-agents-addons-group-affair_setting" do
        expect(page).to have_css("dd", text: group_code1)
      end
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        within "#addon-gws-agents-addons-group-affair_setting" do
          fill_in "item[group_code]", with: group_code2
        end
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-group-affair_setting" do
        expect(page).to have_css("dd", text: group_code2)
      end
    end
  end
end

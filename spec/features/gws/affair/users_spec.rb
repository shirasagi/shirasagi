require 'spec_helper'

describe "gws_affair_users", type: :feature, dbscope: :example, js: true do
  before { create_affair_users }
  let(:site) { affair_site }

  context "regular_staff" do
    before { login_gws_user }
    let(:item) { affair_user(638) }
    let(:show_path) { gws_user_path site, item }

    let(:staff_address_uid1) { "520357" }
    let(:staff_address_uid2) { unique_id }

    let(:regular_staff) { I18n.t("gws/affair.options.staff_category.regular_staff") }
    let(:fiscal_year_staff) { I18n.t("gws/affair.options.staff_category.fiscal_year_staff") }

    it "#index" do
      visit show_path
      within "#addon-gws-agents-addons-user-affair_setting" do
        expect(page).to have_css("dd", text: regular_staff)
        expect(page).to have_css("dd", text: staff_address_uid1)
      end
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        within "#addon-gws-agents-addons-user-affair_setting" do
          select fiscal_year_staff, from: 'item[staff_category]'
          fill_in "item[staff_address_uid]", with: staff_address_uid2
        end
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-user-affair_setting" do
        expect(page).to have_css("dd", text: fiscal_year_staff)
        expect(page).to have_css("dd", text: staff_address_uid2)
      end
    end
  end∂
end

require 'spec_helper'

describe "cms/check_links/site_setting", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:show_path) { cms_check_links_site_setting_path site.id }

  let(:email) { "#{unique_id}@example.jp" }
  let(:message_format) { I18n.t("cms/check_links.options.message_format.csv") }

  context "with auth" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      within "#menu" do
        click_link I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[check_links_email]", with: email
        select message_format, from: "item[check_links_message_format]"
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_css("dd", text: email)
        expect(page).to have_css("dd", text: message_format)
      end
    end
  end
end

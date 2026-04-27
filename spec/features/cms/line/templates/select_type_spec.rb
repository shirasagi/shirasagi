require 'spec_helper'

describe "cms/line/templates", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_message }
  let(:show_path) { cms_line_message_path site, item }

  before { login_cms_user }

  context "default case" do
    it "#show" do
      visit show_path

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_css("div", text: I18n.t("cms.line_empty_template"))
        click_on I18n.t("cms.buttons.add_template")
      end
      wait_for_js_ready

      within ".message-types" do
        expect(page).to have_selector(".message-type", count: 4)
        expect(page).to have_css(".message-type.text")
        expect(page).to have_css(".message-type.image")
        expect(page).to have_css(".message-type.page")
        expect(page).to have_css(".message-type.json_body")
      end
    end
  end

  context "without page template" do
    let!(:setting) { create(:cms_line_setting, template_types: %w(text image json_body)) }

    it "#show" do
      visit show_path

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_css("div", text: I18n.t("cms.line_empty_template"))
        click_on I18n.t("cms.buttons.add_template")
      end
      wait_for_js_ready

      within ".message-types" do
        expect(page).to have_selector(".message-type", count: 3)
        expect(page).to have_css(".message-type.text")
        expect(page).to have_css(".message-type.image")
        expect(page).to have_css(".message-type.json_body")
      end
    end
  end
end

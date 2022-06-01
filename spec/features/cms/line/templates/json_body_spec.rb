require 'spec_helper'

describe "cms/line/templates json_body", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_message }
  let(:show_path) { cms_line_message_path site, item }
  let(:json_body) { '{ "type": "text", "text": "hello" }' }
  let(:json_body_invalid) { "hello" }

  describe "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_css("div", text: "テンプレートが設定されていません。")
        click_on I18n.t("cms.buttons.add_template")
      end
      within ".line-select-message-type" do
        first(".message-type.json_body").click
      end

      # input invalid json
      expect(page).to have_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-json_body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/json_body"))
        fill_in "item[json_body]", with: json_body_invalid
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation ul li", text: "JSONは不正な値です。")

      # input valid json
      within "#addon-cms-agents-addons-line-template-json_body" do
        fill_in "item[json_body]", with: json_body
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # check talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_no_css("div", text: "テンプレートが設定されていません。")
        within ".line-talk-view" do
          expect(page).to have_css(".talk-balloon", text: "{JSONテンプレート;}")
          first(".actions .edit-template").click
        end
      end

      # edit talk-balloon
      expect(page).to have_no_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-json_body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/json_body"))
        fill_in "item[json_body]", with: json_body
      end

      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        within ".line-talk-view" do
          expect(page).to have_css(".talk-balloon", text: "{JSONテンプレート;}")
          page.accept_confirm do
            first(".actions .remove-template").click
          end
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_css("div", text: "テンプレートが設定されていません。")
      end
    end
  end
end

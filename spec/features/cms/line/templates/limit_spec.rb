require 'spec_helper'

describe "cms/line/templates text", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_message }
  let(:show_path) { cms_line_message_path site, item }

  def add_template
    visit show_path
    within "#addon-cms-agents-addons-line-message-body" do
      click_on I18n.t("cms.buttons.add_template")
    end

    within ".line-select-message-type" do
      first(".message-type.text").click
    end

    within "#addon-cms-agents-addons-line-template-text" do
      expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/text"))
      fill_in "item[text]", with: unique_id
    end

    within "footer.send" do
      click_on I18n.t("ss.buttons.save")
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
  end

  describe "basic crud" do
    before { login_cms_user }

    it "#show" do
      item.class.max_templates.times { add_template }

      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("a.btn-disabled", text: I18n.t("cms.buttons.add_template"))
      end
    end
  end
end

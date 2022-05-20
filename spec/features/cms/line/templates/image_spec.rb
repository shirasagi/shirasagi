require 'spec_helper'

describe "cms/line/templates image", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_message }
  let(:show_path) { cms_line_message_path site, item }
  let!(:file1) do
    tmp_ss_file(Cms::TempFile, user: cms_user, site: site,
      contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end
  let!(:file2) do
    tmp_ss_file(Cms::TempFile, user: cms_user, site: site,
      contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
  end

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
        first(".message-type.image").click
      end

      # input image
      expect(page).to have_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-image" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/image"))
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        expect(page).to have_css(".file-view", text: file1.name)
        click_on file1.name
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
          expect(page.find('img')[:src]).to start_with file1.full_url
          first(".actions .edit-template").click
        end
      end

      # edit talk-balloon
      expect(page).to have_no_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-image" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/image"))
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        expect(page).to have_css(".file-view", text: file2.name)
        click_on file2.name
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        within ".line-talk-view" do
          expect(page.find('img')[:src]).to start_with file2.full_url
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

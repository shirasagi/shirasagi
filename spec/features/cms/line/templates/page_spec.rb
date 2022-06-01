require 'spec_helper'

describe "cms/line/templates text", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_message }
  let(:show_path) { cms_line_message_path site, item }

  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:page1) { create(:article_page, cur_node: node) }
  let!(:page2) { create(:article_page, cur_node: node) }

  let!(:file1) do
    tmp_ss_file(
      Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end
  let!(:file2) do
    tmp_ss_file(
      Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
  end

  let!(:summary1) { unique_id }
  let!(:summary2) { unique_id }

  before do
    page2.thumb_id = file1.id
    page2.file_ids = [file2.id]
    page2.html = "<img src=\"#{file2.url}\" />"
    page2.save!
    page2.reload
  end

  context "template with no image" do
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
        first(".message-type.page").click
      end

      # input page with no image
      expect(page).to have_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-page" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/page"))
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page1.name)
        click_on page1.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary1
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
          expect(page).to have_css(".talk-balloon .title", text: page1.name)
          expect(page).to have_css(".talk-balloon .summary", text: summary1)
          within ".talk-balloon .footer" do
            expect(page.find('a')[:href]).to start_with page1.full_url
          end
          first(".actions .edit-template").click
        end
      end

      # edit talk-balloon
      expect(page).to have_no_css(".line-select-message-type")
      within "#addon-cms-agents-addons-line-template-page" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/template/page"))
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page2.name)
        click_on page2.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary2
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # delete talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_no_css("div", text: "テンプレートが設定されていません。")
        within ".line-talk-view" do
          expect(page).to have_css(".talk-balloon .title", text: page2.name)
          expect(page).to have_css(".talk-balloon .summary", text: summary2)
          within ".talk-balloon .footer" do
            expect(page.find('a')[:href]).to start_with page2.full_url
          end
          page.accept_confirm do
            first(".actions .remove-template").click
          end
        end
      end

      within "#addon-cms-agents-addons-line-message-body" do
        expect(page).to have_css("h2", text: I18n.t("modules.addons.cms/line/message/body"))
        expect(page).to have_css("div", text: "テンプレートが設定されていません。")
      end
    end
  end

  context "template with page's thumb image" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        click_on I18n.t("cms.buttons.add_template")
      end
      within ".line-select-message-type" do
        first(".message-type.page").click
      end

      # page1 have no thumb
      within "#addon-cms-agents-addons-line-template-page" do
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page1.name)
        click_on page1.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary1
        select I18n.t("cms.options.line_template_thumb_state.thumb_carousel"), from: 'item[thumb_state]'
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation ul li", text: "ページにサムネイル画像が設定されていません。")

      # page2 have thumb
      within "#addon-cms-agents-addons-line-template-page" do
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page1.name)
        click_on page2.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary2
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # check talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        within ".line-talk-view" do
          expect(page).to have_css(".talk-balloon .title", text: page2.name)
          expect(page).to have_css(".talk-balloon .summary", text: summary2)
          within ".talk-balloon .footer" do
            expect(page.find('a')[:href]).to start_with page2.full_url
          end
          within ".talk-balloon .img-warp" do
            expect(page.find('img')[:src]).to start_with page2.thumb.full_url
          end
        end
      end
    end
  end

  context "template with page's body image" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        click_on I18n.t("cms.buttons.add_template")
      end
      within ".line-select-message-type" do
        first(".message-type.page").click
      end

      # page1 have no body image
      within "#addon-cms-agents-addons-line-template-page" do
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page1.name)
        click_on page1.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary1
        select I18n.t("cms.options.line_template_thumb_state.body_carousel"), from: 'item[thumb_state]'
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end

      # add template
      within "#addon-cms-agents-addons-line-message-body" do
        click_on I18n.t("cms.buttons.add_template")
      end
      within ".line-select-message-type" do
        first(".message-type.page").click
      end

      # page2 have body image
      within "#addon-cms-agents-addons-line-template-page" do
        click_on I18n.t("cms.apis.pages.index")
      end
      wait_for_cbox do
        expect(page).to have_css(".list-item", text: page2.name)
        click_on page2.name
      end
      within "#addon-cms-agents-addons-line-template-page" do
        fill_in "item[summary]", with: summary2
        select I18n.t("cms.options.line_template_thumb_state.body_carousel"), from: 'item[thumb_state]'
      end
      within "footer.send" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # check talk-balloon
      within "#addon-cms-agents-addons-line-message-body" do
        within ".line-talk-view" do
          within ".template0" do
            expect(page).to have_css(".talk-balloon .title", text: page1.name)
            expect(page).to have_css(".talk-balloon .summary", text: summary1)
            within ".talk-balloon .footer" do
              expect(page.find('a')[:href]).to start_with page1.full_url
            end
          end
          within ".template1" do
            expect(page).to have_css(".talk-balloon .title", text: page2.name)
            expect(page).to have_css(".talk-balloon .summary", text: summary2)
            within ".talk-balloon .footer" do
              expect(page.find('a')[:href]).to start_with page2.full_url
            end
            within ".talk-balloon .img-warp" do
              expect(page.find('img')[:src]).to start_with page2.files.first.full_url
            end
          end
        end
      end
    end
  end
end

require 'spec_helper'

describe "article_pages", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "attach file" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
      end

      click_on I18n.t("ss.buttons.upload")
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        click_button I18n.t("ss.buttons.attach")
      end

      sleep 0.5

      expect(first("#addon-cms-agents-addons-file #selected-files").text).to include('keyvisual.gif')
    end

    it "#edit file name" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
      end

      click_on I18n.t("ss.buttons.upload")
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        sleep 0.1

        click_on I18n.t("ss.buttons.edit")
        within "form#ajax-form" do
          fill_in "item[name]", with: "modify"
        end

        click_button I18n.t("ss.buttons.save")
        sleep 0.1

        first("a.thumb.select").click
      end

      sleep 0.5

      expect(first("#addon-cms-agents-addons-file #selected-files").text).to include('modify')
    end
  end
end

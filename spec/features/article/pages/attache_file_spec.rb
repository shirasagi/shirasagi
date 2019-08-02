require 'spec_helper'

describe "article_pages", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "attache file" do
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
        click_button I18n.t("ss.buttons.attache")
      end

      sleep 1

      expect(first("#selected-files").text).to include('keyvisual.gif')
    end
  end
end

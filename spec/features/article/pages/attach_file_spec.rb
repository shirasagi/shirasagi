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
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        click_button I18n.t("ss.buttons.attach")
        wait_for_ajax
      end

      within '#selected-files' do
        expect(page).to have_css('.name', text: 'keyvisual.gif')
      end
    end

    it "#edit file name" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        click_on I18n.t("ss.buttons.edit")
        fill_in "item[name]", with: "modify.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        first("a.thumb.select").click
      end

      within '#selected-files' do
        expect(page).to have_css('.name', text: 'modify.jpg')
      end
    end
  end
end

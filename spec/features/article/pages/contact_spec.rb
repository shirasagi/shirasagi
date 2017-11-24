require 'spec_helper'

describe "article_pages", dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:item) { create(:article_page, cur_node: node) }
  let!(:new_path) { new_article_page_path site.id, node }
  let!(:contact_group) { create(:contact_group, name: "contact_group") }

  context "contact", js: true do
    before { login_cms_user }
    before { site.add_to_set group_ids: contact_group.id }

    it "#new" do
      visit new_path

      first('#addon-contact-agents-addons-page').click
      first('#addon-contact-agents-addons-page .ajax-box').click
      wait_for_cbox

      click_on "contact_group"
      #sleep 1

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_button "下書き保存"
      end
      click_button "警告を無視する"

      section = first('#addon-contact-agents-addons-page')
      expect(section).to have_text("contact_group")
      expect(section).to have_text("0000000000")
      expect(section).to have_text("1111111111")
      expect(section).to have_text("contact@example.jp")
      expect(section).to have_text("http://example.jp")
      expect(section).to have_text("link_name")
    end
  end
end

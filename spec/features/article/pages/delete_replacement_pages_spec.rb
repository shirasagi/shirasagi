require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let!(:replacement_page) { create(:article_page, cur_node: node) }
  let(:index_path) { article_pages_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }
  let(:contains_urls_path) { contains_urls_article_page_path site.id, node, item }

  context "Try and delete replacement pages but you can't" do
    before do 
      replacement_page.update(related_page_ids: [item.id])
      item.reload
      replacement_page.reload
      login_cms_user
    end

    it "Hit index and try to delete" do
      visit index_path
      expect(page).to have_css(".list-items")

      within ".list-items" do 
        expect(page).to have_css("input[type='checkbox'][value='#{item.id}']")
        expect(page).to have_css("input[type='checkbox'][value='#{replacement_page.id}']")
        find("input[type='checkbox'][value='#{item.id}']").click
        find("input[type='checkbox'][value='#{replacement_page.id}']").click
        expect(find("input[type='checkbox'][value='#{item.id}']")).to be_checked
        expect(find("input[type='checkbox'][value='#{replacement_page.id}']")).to be_checked
      end
      find('.destroy-all').click
      wait_for_ajax

      expect(page).to have_css("h2", text: I18n.t("ss.confirm.target_to_delete"))
      expect(page).to have_css("input[type='checkbox'][value='#{replacement_page.id}'][checked='checked']")
      expect(page).to_not have_css("input[type='checkbox'][value='#{item.id}'][checked='checked']")
      expect(page).to have_css("a.contains-urls[href='#{contains_urls_path}']", text: I18n.t("ss.confirm.contains_links_in_file"))
    end
  end
end
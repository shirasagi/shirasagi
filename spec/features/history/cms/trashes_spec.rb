require 'spec_helper'

describe "history_cms_trashes", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:page_item) { create(:article_page, cur_node: node) }
  let(:index_path) { history_cms_trashes_path(site: site.id, coll: 'cms_pages') }
  let(:node_path) { article_pages_path(site: site.id, cid: node.id) }
  let(:page_path) { article_page_path(site: site.id, cid: node.id, id: page_item.id) }

  context "with auth" do
    before { login_cms_user }

    it "#undo_delete" do
      visit page_path
      click_link '削除する'
      click_button '削除'
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      click_link '元に戻す'
      click_button '元に戻す'
      expect(current_path).to eq index_path

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)
    end

    it "#undo_delete_all" do
      visit page_path
      click_link '削除する'
      click_button '削除'
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      within '.list-head' do
        check(nil)
        page.accept_confirm do
          click_button '元に戻す'
        end
      end
      expect(current_path).to eq index_path

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)
    end
  end
end

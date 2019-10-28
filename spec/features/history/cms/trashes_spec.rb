require 'spec_helper'

describe "history_cms_trashes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:file) { create :cms_file, site: site }
  let(:page_item) { create(:article_page, cur_node: node, file_ids: [file.id]) }
  let(:index_path) { history_cms_trashes_path(site: site.id) }
  let(:node_path) { article_pages_path(site: site.id, cid: node.id) }
  let(:page_path) { article_page_path(site: site.id, cid: node.id, id: page_item.id) }

  context "with auth" do
    before { login_cms_user }

    it "#destroy" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      expect(page).to have_css('dd', text: page_item.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_no_css('a.title', text: page_item.name)
    end

    it "#destroy_all" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      within '.list-head' do
        check(nil)
        page.accept_confirm do
          click_button I18n.t('ss.links.delete')
        end
      end
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_no_css('a.title', text: page_item.name)
    end

    it "#undo_delete" do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      expect(page).to have_css('dd', text: page_item.name)

      click_link I18n.t('ss.buttons.restore')
      click_button I18n.t('ss.buttons.restore')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)

      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)
    end

    it "#undo_delete_all" do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      within '.list-head' do
        check(nil)
        page.accept_confirm do
          click_button I18n.t('ss.buttons.restore')
        end
      end
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)

      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)
    end
  end
end

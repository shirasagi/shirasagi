require 'spec_helper'

describe "gws_bookmark_items move_all", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:root_folder) { user.bookmark_root_folder(site) }
  let!(:folder1) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }
  let!(:folder2) { create :gws_bookmark_folder, cur_user: user, in_parent: root_folder.id }

  let!(:item1) { create :gws_bookmark_item, cur_user: user, folder: folder1 }
  let!(:item2) { create :gws_bookmark_item, cur_user: user, folder: folder1 }

  let(:index_path) { gws_bookmark_items_path site, folder_id: folder1 }

  before { login_user user }

  context "移動ドロップダウンで選択したブックマークを別フォルダーへ一括移動できる" do
    it do
      visit index_path
      within ".index .list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
      end

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }

      within ".list-head-action .move-menu" do
        find("button.btn", text: I18n.t("gws/bookmark.links.move")).click
        page.accept_confirm do
          click_on folder2.name
        end
      end

      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Bookmark::Item.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Bookmark::Item.find(item2.id).folder_id).to eq folder2.id
    end
  end
end

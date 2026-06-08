require 'spec_helper'

describe "gws_share_files move_all", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:category) { create :gws_share_category, cur_site: site }

  # ライブラリーA（最上位フォルダー folder0 とその配下 folder1 / folder2）
  let!(:folder0) { create :gws_share_folder, cur_site: site }
  let!(:folder1) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }
  let!(:folder2) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }

  # ライブラリーB（別の最上位フォルダー）
  let!(:other_library) { create :gws_share_folder, cur_site: site }

  let!(:item1) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [category.id] }
  let!(:item2) { create :gws_share_file, cur_site: site, folder: folder1, category_ids: [category.id] }

  let(:index_path) { gws_share_folder_files_path site, folder1 }

  context "同一ライブラリー内の別フォルダーへ一括移動できる" do
    it do
      expect(item1.folder_id).to eq folder1.id
      expect(item2.folder_id).to eq folder1.id

      login_gws_user to: index_path
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder0.name)
      end

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }

      within ".list-head-action .move-menu" do
        find("button.btn", text: I18n.t("gws/share.links.move")).click
        page.accept_confirm do
          click_on folder2.name
        end
      end

      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Share::File.find(item1.id).folder_id).to eq folder2.id
      expect(Gws::Share::File.find(item2.id).folder_id).to eq folder2.id

      # 移動元・移動先の集計が更新されていること
      folder1.reload
      expect(folder1.descendants_files_count).to eq 0
      folder2.reload
      expect(folder2.descendants_files_count).to eq 2
    end
  end

  context "移動先候補は同一ライブラリー内に絞り込まれる" do
    it do
      login_gws_user to: index_path

      within ".list-head-action .move-menu" do
        find("button.btn", text: I18n.t("gws/share.links.move")).click
        expect(page).to have_link folder2.name
        # 別ライブラリーは候補に表示されない
        expect(page).to have_no_link other_library.name
      end
    end
  end
end

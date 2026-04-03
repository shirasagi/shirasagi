require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:category) { create :gws_share_category, cur_site: site }
  let!(:folder0) { create :gws_share_folder, cur_site: site }
  let!(:folder1) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }
  let!(:folder2) { create :gws_share_folder, cur_site: site, name: "#{folder0.name}/#{unique_id}" }
  let!(:item) do
    Timecop.freeze(now - 1.day) do
      create :gws_share_file, cur_site: site, folder: folder1, category_ids: [category.id]
    end
  end

  context "move folder" do
    it do
      # 画面から操作した場合、フォルダーが保持している総ファイル数と総ファイル容量とは更新されるが、
      # 直接作成した場合、更新されないので手動で再計算する
      folder1.reload
      folder1.update_folder_descendants_file_info
      expect(folder1.descendants_files_count).to eq 1
      expect(folder1.descendants_total_file_size).to eq item.size

      folder2.reload
      folder2.update_folder_descendants_file_info
      expect(folder2.descendants_files_count).to eq 0
      expect(folder2.descendants_total_file_size).to eq 0

      folder0.reload
      folder0.update_folder_descendants_file_info
      expect(folder0.descendants_files_count).to eq 1
      expect(folder0.descendants_total_file_size).to eq item.size

      login_gws_user to: gws_share_files_path(site: site)
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        select folder2.name, from: "item[folder_id]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Gws::Share::File.find(item.id).tap do |item_after_move|
        expect(item_after_move.site_id).to eq item.site_id
        expect(item_after_move.folder_id).to eq folder2.id
        expect(item_after_move.name).to eq item.name
        expect(item_after_move.filename).to eq item.filename
        expect(item_after_move.size).to eq item.size
        expect(item_after_move.content_type).to eq item.content_type
        expect(item_after_move.updated.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(item_after_move.created).to eq item.created
        expect(item_after_move.deleted).to eq item.deleted
      end

      # 画面操作によりフォルダーを移動したのでフォルダーが保持している総ファイル数と総ファイル容量とは更新されているはず
      # 再計算する必要はなく DB から読込直すだけで問題ないはず
      folder0.reload
      expect(folder0.descendants_files_count).to eq 1
      expect(folder0.descendants_total_file_size).to eq item.size

      folder1.reload
      expect(folder1.descendants_files_count).to eq 0
      expect(folder1.descendants_total_file_size).to eq 0

      folder2.reload
      expect(folder2.descendants_files_count).to eq 1
      expect(folder2.descendants_total_file_size).to eq item.size
    end
  end
end

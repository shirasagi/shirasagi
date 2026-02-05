require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:folder) { create :gws_share_folder, cur_site: site }
  let!(:category) { create :gws_share_category, cur_site: site }
  let!(:item) do
    Timecop.freeze(now) do
      create :gws_share_file, cur_site: site, folder: folder, category_ids: [category.id], deleted: now
    end
  end

  before { login_gws_user }

  describe "restore file as-is" do
    it do
      # 画面から操作した場合、フォルダーが保持している総ファイル数と総ファイル容量とは更新されるが、
      # 直接作成した場合、更新されないので手動で再計算する
      folder.reload
      folder.update_folder_descendants_file_info
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size

      expect(item.histories.count).to eq 1

      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name
      click_on I18n.t("ss.links.restore")

      within "form#item-form" do
        click_on I18n.t("ss.buttons.restore")
      end

      wait_for_notice I18n.t('ss.notice.restored')
      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end

      Gws::Share::File.find(item.id).tap do |item_after_recover|
        expect(item_after_recover.site_id).to eq item.site_id
        expect(item_after_recover.name).to eq item.name
        expect(item_after_recover.folder_id).to eq item.folder_id
        expect(item_after_recover.deleted).to be_blank
        expect(item_after_recover.updated).to eq item.updated
      end

      expect(item.histories.count).to eq 2
      item.histories.first.tap do |history|
        expect(history.name).to eq item.name
        expect(history.mode).to eq "undelete"
        expect(history.model).to eq item.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{item.class.model_name.i18n_key}")
        expect(history.item_id).to eq item.id.to_s
        expect(Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq item.histories.last.path
      end

      # 画面操作によりフォルダーを移動したのでフォルダーが保持している総ファイル数と総ファイル容量とは更新されているはず
      # 再計算する必要はなく DB から読込直すだけで問題ないはず
      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size
    end
  end

  describe "restore file with different name" do
    let(:new_name) { "name-#{unique_id}" }

    it do
      # 画面から操作した場合、フォルダーが保持している総ファイル数と総ファイル容量とは更新されるが、
      # 直接作成した場合、更新されないので手動で再計算する
      folder.reload
      folder.update_folder_descendants_file_info
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size

      expect(item.histories.count).to eq 1

      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name
      click_on I18n.t("ss.links.restore")

      within "form#item-form" do
        fill_in "item[name]", with: new_name
        click_on I18n.t("ss.buttons.restore")
      end

      wait_for_notice I18n.t('ss.notice.restored')
      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end

      Gws::Share::File.find(item.id).tap do |item_after_recover|
        expect(item_after_recover.site_id).to eq item.site_id
        expect(item_after_recover.name).to eq "#{new_name}#{File.extname(item.filename)}"
        expect(item_after_recover.folder_id).to eq item.folder_id
        expect(item_after_recover.deleted).to be_blank
        expect(item_after_recover.updated).to eq item.updated
      end

      expect(item.histories.count).to eq 2
      item.histories.first.tap do |history|
        expect(history.name).to eq "#{new_name}#{File.extname(item.filename)}"
        expect(history.mode).to eq "undelete"
        expect(history.model).to eq item.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{item.class.model_name.i18n_key}")
        expect(history.item_id).to eq item.id.to_s
        expect(Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq item.histories.last.path
      end

      # 画面操作によりフォルダーを移動したのでフォルダーが保持している総ファイル数と総ファイル容量とは更新されているはず
      # 再計算する必要はなく DB から読込直すだけで問題ないはず
      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size
    end
  end

  describe "restore file with different folder" do
    let!(:folder2) { create :gws_share_folder, cur_site: site }

    it do
      # 画面から操作した場合、フォルダーが保持している総ファイル数と総ファイル容量とは更新されるが、
      # 直接作成した場合、更新されないので手動で再計算する
      folder.reload
      folder.update_folder_descendants_file_info
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size

      folder2.reload
      folder2.update_folder_descendants_file_info
      expect(folder2.descendants_files_count).to eq 0
      expect(folder2.descendants_total_file_size).to eq 0

      expect(item.histories.count).to eq 1

      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name
      click_on I18n.t("ss.links.restore")

      within "form#item-form" do
        wait_for_cbox_opened { click_on I18n.t('gws/share.apis.folders.index') }
      end
      within_cbox do
        wait_for_cbox_closed { click_on folder2.name }
      end
      within "form#item-form" do
        expect(page).to have_css("[data-id='#{folder2.id}']", text: folder2.name)
        click_on I18n.t("ss.buttons.restore")
      end

      wait_for_notice I18n.t('ss.notice.restored')
      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end

      Gws::Share::File.find(item.id).tap do |item_after_recover|
        expect(item_after_recover.site_id).to eq item.site_id
        expect(item_after_recover.name).to eq item.name
        expect(item_after_recover.folder_id).to eq folder2.id
        expect(item_after_recover.deleted).to be_blank
        expect(item_after_recover.updated).to eq item.updated
      end

      expect(item.histories.count).to eq 2
      item.histories.first.tap do |history|
        expect(history.name).to eq item.name
        expect(history.mode).to eq "undelete"
        expect(history.model).to eq item.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{item.class.model_name.i18n_key}")
        expect(history.item_id).to eq item.id.to_s
        expect(Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq item.histories.last.path
      end

      # 画面操作によりフォルダーを移動したのでフォルダーが保持している総ファイル数と総ファイル容量とは更新されているはず
      # 再計算する必要はなく DB から読込直すだけで問題ないはず
      folder.reload
      expect(folder.descendants_files_count).to eq 0
      expect(folder.descendants_total_file_size).to eq 0

      folder2.reload
      expect(folder2.descendants_files_count).to eq 1
      expect(folder2.descendants_total_file_size).to eq item.size
    end
  end
end

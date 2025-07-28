require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item1) { create :gws_share_folder, order: 10 }
  let!(:item2) { create :gws_share_folder, order: 20 }
  let!(:item3) { create :gws_share_folder, order: 30 }

  let!(:item4) { create :gws_share_folder, order: 40, name: "#{item1.name}/#{unique_id}" }
  let!(:item5) { create :gws_share_folder, order: 50, name: "#{item1.name}/#{unique_id}" }
  let!(:item6) { create :gws_share_folder, order: 60, name: "#{item1.name}/#{unique_id}" }

  let!(:item7) { create :gws_share_folder, order: 70, name: "#{item4.name}/#{unique_id}" }
  let!(:item8) { create :gws_share_folder, order: 80, name: "#{item4.name}/#{unique_id}" }
  let!(:item9) { create :gws_share_folder, order: 90, name: "#{item4.name}/#{unique_id}" }

  before do
    @save_config = SS.config.gws.share
    SS.config.replace_value_at(:gws, :share, @save_config.merge({ "folder_navi_limit" => limit }))
    login_gws_user
  end

  after do
    SS.config.replace_value_at(:gws, :share, @save_config)
  end

  context "default limit 100 folders" do
    let(:limit) { 100 }

    it do
      visit gws_share_files_path(site)

      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_no_link item4.trailing_name
        expect(page).to have_no_link item5.trailing_name
        expect(page).to have_no_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item1.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item4.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_link item6.trailing_name
        expect(page).to have_link item7.trailing_name
        expect(page).to have_link item8.trailing_name
        expect(page).to have_link item9.trailing_name
      end
    end
  end

  context "limit 2 folders" do
    let(:limit) { 2 }

    it do
      visit gws_share_files_path(site)

      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_no_link item3.trailing_name
        expect(page).to have_no_link item4.trailing_name
        expect(page).to have_no_link item5.trailing_name
        expect(page).to have_no_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item1.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_no_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_no_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item4.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_no_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_no_link item6.trailing_name
        expect(page).to have_link item7.trailing_name
        expect(page).to have_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
      end
    end
  end

  context "no limit" do
    let(:limit) { nil }

    it do
      visit gws_share_files_path(site)

      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_no_link item4.trailing_name
        expect(page).to have_no_link item5.trailing_name
        expect(page).to have_no_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item1.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_link item6.trailing_name
        expect(page).to have_no_link item7.trailing_name
        expect(page).to have_no_link item8.trailing_name
        expect(page).to have_no_link item9.trailing_name
        click_link item4.trailing_name
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link item1.trailing_name
        expect(page).to have_link item2.trailing_name
        expect(page).to have_link item3.trailing_name
        expect(page).to have_link item4.trailing_name
        expect(page).to have_link item5.trailing_name
        expect(page).to have_link item6.trailing_name
        expect(page).to have_link item7.trailing_name
        expect(page).to have_link item8.trailing_name
        expect(page).to have_link item9.trailing_name
      end
    end
  end
end

require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder_name1) { unique_id }
  let(:folder_name2) { unique_id }
  let(:folder_name3) { unique_id }

  before { login_gws_user }

  context "with folder crud on folder navi" do
    it do
      visit gws_share_files_path(site)

      # create root folder
      within "#gws-share-file-folder-list" do
        wait_cbox_open { first(".btn-create-root-folder").click }
      end
      wait_for_cbox do
        fill_in "item[in_basename]", with: folder_name1
        click_on I18n.t("ss.buttons.save")
      end

      within "#gws-share-file-folder-property" do
        expect(page).to have_css(".folder-name", text: folder_name1)
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder_name1)
      end

      expect(Gws::Share::Folder.site(site).where(name: folder_name1)).to be_present
      root_folder = Gws::Share::Folder.site(site).find_by(name: folder_name1)
      expect(root_folder.group_ids).to include(*gws_user.group_ids)

      # create sub folder
      within "#gws-share-file-folder-property" do
        wait_cbox_open { first(".btn-create-folder").click }
      end
      wait_for_cbox do
        fill_in "item[in_basename]", with: folder_name2
        click_on I18n.t("ss.buttons.save")
      end

      within "#gws-share-file-folder-property" do
        expect(page).to have_css(".folder-name", text: "#{folder_name1}/#{folder_name2}")
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder_name1)
        expect(page).to have_link(folder_name2)
      end

      expect(Gws::Share::Folder.site(site).where(name: "#{folder_name1}/#{folder_name2}")).to be_present
      Gws::Share::Folder.site(site).find_by(name: "#{folder_name1}/#{folder_name2}").tap do |folder|
        expect(folder.share_max_file_size).to eq root_folder.share_max_file_size
        expect(folder.share_max_folder_size).to eq root_folder.share_max_folder_size
        expect(folder.readable_setting_range).to eq root_folder.readable_setting_range
        expect(folder.readable_group_ids).to include(*root_folder.readable_group_ids)
        expect(folder.readable_member_ids).to include(*root_folder.readable_member_ids)
        expect(folder.group_ids).to include(*root_folder.group_ids)
        expect(folder.user_ids).to include(*root_folder.user_ids)
      end

      # rename sub folder
      within "#gws-share-file-folder-property" do
        wait_cbox_open { first(".btn-rename-folder").click }
      end
      wait_for_cbox do
        fill_in "item[in_basename]", with: folder_name3
        click_on I18n.t("ss.buttons.save")
      end

      within "#gws-share-file-folder-property" do
        expect(page).to have_css(".folder-name", text: "#{folder_name1}/#{folder_name3}")
      end
      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder_name1)
        expect(page).to have_link(folder_name3)
      end

      expect(Gws::Share::Folder.site(site).where(name: "#{folder_name1}/#{folder_name2}")).to be_blank
      expect(Gws::Share::Folder.site(site).where(name: "#{folder_name1}/#{folder_name3}")).to be_present

      # delete sub folder
      within "#gws-share-file-folder-property" do
        wait_cbox_open { first(".btn-delete-folder").click }
      end
      wait_for_cbox do
        click_on I18n.t("ss.buttons.delete")
      end

      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder_name1)
        expect(page).to have_no_link(folder_name3)
      end
      within "#gws-share-file-folder-property" do
        expect(page).to have_css(".folder-name", text: folder_name1)
      end

      expect(Gws::Share::Folder.site(site).where(name: "#{folder_name1}/#{folder_name3}")).to be_blank
    end
  end

  context "when folder list refreshes" do
    it do
      visit gws_share_files_path(site)
      within "#gws-share-file-folder-list" do
        expect(page).to have_no_link(folder_name1)
      end

      Gws::Share::Folder.create!(cur_site: site, name: folder_name1, group_ids: [ site.id ])

      # refresh
      within "#gws-share-file-folder-list" do
        first(".btn-refresh-folder").click
      end

      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder_name1)
      end
    end
  end
end

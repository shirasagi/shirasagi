require 'spec_helper'

describe "gws_bookmark_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
  let!(:user2) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
  let!(:user3) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }

  let!(:folder1) { user1.bookmark_root_folder(site) }
  let!(:folder2) { user2.bookmark_root_folder(site) }
  let!(:folder3) { user3.bookmark_root_folder(site) }

  let!(:item1) { create :gws_bookmark_folder, cur_user: user1, in_parent: folder1.id }
  let!(:item2) { create :gws_bookmark_folder, cur_user: user2, in_parent: folder2.id }
  let!(:item3) { create :gws_bookmark_folder, cur_user: user3, in_parent: folder3.id }

  let(:index_path) { gws_bookmark_folders_path site }
  let(:new_path) { new_gws_bookmark_folder_path site }

  let(:name) { unique_id }

  context "created folders" do
    it do
      expect(Gws::Bookmark::Folder.count).to eq 6
      expect(Gws::Bookmark::Folder.where(folder_type: "specified").count).to eq 3
      expect(Gws::Bookmark::Folder.where(folder_type: "specified", user_id: user1.id).count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "specified", user_id: user2.id).count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "specified", user_id: user3.id).count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "general").count).to eq 3
      expect(Gws::Bookmark::Folder.where(folder_type: "general", user_id: user1.id).count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "general", user_id: user2.id).count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "general", user_id: user3.id).count).to eq 1
    end
  end

  context "user1" do
    before { login_user user1 }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".list-item", text: folder1.name)
        expect(page).to have_css(".list-item", text: item1.name)
      end

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in 'item[in_basename]', with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      click_on I18n.t("ss.links.back_to_index")
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 3)
        expect(page).to have_css(".list-item", text: folder1.name)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: name)
      end
    end
  end

  context "user2" do
    before { login_user user2 }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".list-item", text: folder2.name)
        expect(page).to have_css(".list-item", text: item2.name)
      end

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in 'item[in_basename]', with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      click_on I18n.t("ss.links.back_to_index")
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 3)
        expect(page).to have_css(".list-item", text: folder2.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: name)
      end
    end
  end

  context "user3" do
    before { login_user user3 }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".list-item", text: folder3.name)
        expect(page).to have_css(".list-item", text: item3.name)
      end

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in 'item[in_basename]', with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      click_on I18n.t("ss.links.back_to_index")
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 3)
        expect(page).to have_css(".list-item", text: folder3.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: name)
      end
    end
  end
end

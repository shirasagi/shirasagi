require 'spec_helper'

describe "gws_bookmark_items", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
  let!(:user2) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
  let!(:user3) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }

  let!(:folder1) { user1.bookmark_root_folder(site) }
  let!(:folder2) { create :gws_bookmark_folder, cur_user: user1, in_parent: folder1.id }
  let!(:folder3) { user2.bookmark_root_folder(site) }
  let!(:folder4) { create :gws_bookmark_folder, cur_user: user2, in_parent: folder3.id }
  let!(:folder5) { user3.bookmark_root_folder(site) }
  let!(:folder6) { create :gws_bookmark_folder, cur_user: user3, in_parent: folder5.id }

  let!(:item1) { create :gws_bookmark_item, cur_user: user1, folder: folder1 }
  let!(:item2) { create :gws_bookmark_item, cur_user: user1, folder: folder2 }
  let!(:item3) { create :gws_bookmark_item, cur_user: user2, folder: folder3 }
  let!(:item4) { create :gws_bookmark_item, cur_user: user2, folder: folder4 }
  let!(:item5) { create :gws_bookmark_item, cur_user: user3, folder: folder5 }
  let!(:item6) { create :gws_bookmark_item, cur_user: user3, folder: folder6 }

  let(:index_path) { gws_bookmark_main_path site }

  let(:name) { unique_id }

  context "user1" do
    before { login_user user1 }

    it "#index" do
      visit index_path

      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within "#content-navi" do
        expect(page).to have_selector(".is-open a.item-name", count: 2)
        expect(page).to have_link folder1.trailing_name
        expect(page).to have_link folder2.trailing_name
      end
      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item1.name)
      end

      within "#content-navi" do
        click_on folder2.trailing_name
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item2.name)
      end
    end
  end

  context "user2" do
    before { login_user user2 }

    it "#index" do
      visit index_path

      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within "#content-navi" do
        expect(page).to have_selector(".is-open a.item-name", count: 2)
        expect(page).to have_link folder3.trailing_name
        expect(page).to have_link folder4.trailing_name
      end
      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item3.name)
      end

      within "#content-navi" do
        click_on folder4.trailing_name
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item4.name)
      end
    end
  end

  context "user3" do
    before { login_user user3 }

    it "#index" do
      visit index_path

      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within "#content-navi" do
        expect(page).to have_selector(".is-open a.item-name", count: 2)
        expect(page).to have_link folder5.trailing_name
        expect(page).to have_link folder6.trailing_name
      end
      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item5.name)
      end

      within "#content-navi" do
        click_on folder6.trailing_name
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item", text: item6.name)
      end
    end
  end
end

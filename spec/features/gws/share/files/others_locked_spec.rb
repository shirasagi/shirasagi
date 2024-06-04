require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user0) { gws_user }
  let(:user1) { create :gws_user, group_ids: user0.group_ids, gws_role_ids: user0.gws_role_ids }
  let(:user2) { create :gws_user, group_ids: user0.group_ids, gws_role_ids: user0.gws_role_ids }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id] }

  before do
    result = item.acquire_lock(user: user2)
    expect(result).to be_truthy
    expect(item.locked?).to be_truthy
    expect(item.lock_owned?(user1)).to be_falsey
  end

  describe "#lock" do
    before { login_user user1 }

    it do
      visit gws_share_folder_files_path(site, folder)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on item.name
      within "#addon-gws-agents-addons-edit_lock" do
        expect(page).to have_content(I18n.t("errors.messages.locked", user: user2.long_name))
      end

      click_on I18n.t("ss.links.edit")
      within ".main-box" do
        expect(page).to have_content(I18n.t("errors.messages.locked", user: user2.long_name))
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.unlock_and_edit_forcibly")
      end

      item.reload
      expect(item.locked?).to be_truthy
      expect(item.lock_owned?(user1)).to be_truthy

      within "form#item-form" do
        expect(page).to have_field("item[name]", with: item.name)
        fill_in "item[name]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.locked?).to be_falsey
    end
  end

  describe "unlock forcibly on #show" do
    before { login_user user1 }

    it do
      visit gws_share_folder_files_path(site, folder)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on item.name
      within "#addon-gws-agents-addons-edit_lock" do
        expect(page).to have_content(I18n.t("errors.messages.locked", user: user2.long_name))
        within "form#item-form" do
          click_on I18n.t("ss.buttons.unlock_and_edit_forcibly")
        end
      end

      item.reload
      expect(item.locked?).to be_truthy
      expect(item.lock_owned?(user1)).to be_truthy

      within "form#item-form" do
        expect(page).to have_field("item[name]", with: item.name)
        fill_in "item[name]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.locked?).to be_falsey
    end
  end

  describe "other gets locked forcibly on updating" do
    before { login_user user2 }

    it do
      visit gws_share_folder_files_path(site, folder)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on item.name
      click_on I18n.t("ss.buttons.edit")

      item.reload
      expect(item.locked?).to be_truthy
      expect(item.lock_owned?(user1)).to be_falsey
      expect(item.lock_owned?(user2)).to be_truthy

      item.acquire_lock(user: user1, force: true)
      expect(item.locked?).to be_truthy
      expect(item.lock_owned?(user1)).to be_truthy
      expect(item.lock_owned?(user2)).to be_falsey

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end

      within ".main-box" do
        expect(page).to have_content(I18n.t("errors.messages.locked", user: user1.long_name))
      end

      item.reload
      expect(item.locked?).to be_truthy
      expect(item.lock_owned?(user1)).to be_truthy
      expect(item.lock_owned?(user2)).to be_falsey
    end
  end
end

require 'spec_helper'

describe "cms_users", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:user) { cms_user }

  let!(:user1) { create :cms_test_user, group_ids: [group.id] }
  let!(:user2) { create :cms_test_user, group_ids: [group.id], deletion_lock_state: "locked" }
  let(:index_path) { cms_users_path site }
  let(:delete_user1_path) { delete_cms_user_path site, user1 }
  let(:delete_user2_path) { delete_cms_user_path site, user2 }

  context "with auth" do
    before { login_cms_user }

    it "#edit" do
      visit index_path

      expect(page).to have_css(".list-items", text: user.name)
      expect(page).to have_css(".list-items", text: user1.name)
      expect(page).to have_css(".list-items", text: user2.name)
      expect(page).to have_selector('.list-item .deletion-lock', count: 2)

      click_on user1.name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.user_deletion_lock_state.locked"), from: "item[deletion_lock_state]"
        click_button I18n.t('ss.buttons.save')
      end

      click_on I18n.t("ss.links.back_to_index")

      expect(current_path).to eq index_path
      expect(page).to have_selector('.list-item .deletion-lock', count: 3)
    end

    it "#delete user" do
      visit delete_user1_path
      within "form" do
        expect(page).to have_text(I18n.t("ss.info.soft_delete"))
        click_button I18n.t('ss.buttons.delete')
      end

      expect(current_path).to eq index_path
      expect(page).to have_css(".list-items", text: user.name)
      expect(page).to have_no_css(".list-items", text: user1.name)
      expect(page).to have_css(".list-items", text: user2.name)
    end

    it "#delete locked user" do
      visit delete_user2_path
      within "form" do
        expect(page).to have_text(I18n.t("ss.info.soft_delete_locked"))
        expect(page).to have_no_css('input[type="submit"]')
      end
    end

    it "#delete_all" do
      visit index_path
      expect(page).to have_css(".list-items", text: user.name)
      expect(page).to have_css(".list-items", text: user1.name)
      expect(page).to have_css(".list-items", text: user2.name)

      find('.list-head input[type="checkbox"]').set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end

      expect(page).to have_css(".list-items", text: user.name)
      expect(page).to have_no_css(".list-items", text: user1.name)
      expect(page).to have_css(".list-items", text: user2.name)
    end
  end
end

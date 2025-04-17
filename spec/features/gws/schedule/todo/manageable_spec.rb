require 'spec_helper'

describe "gws_schedule_todo_manageables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let!(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:item1) { create :gws_schedule_todo, cur_site: site, cur_user: user1, member_ids: [user1.id], user_ids: [user1.id] }
  let!(:item2) { create :gws_schedule_todo, cur_site: site, cur_user: user2, member_ids: [user2.id], user_ids: [user1.id] }

  before { login_gws_user }

  describe "manageable todo" do
    it do
      visit gws_schedule_todo_main_path site
      expect(page).to have_content(item1.name)
      expect(page).to have_no_content(item2.name)

      click_on I18n.t('gws/schedule.tabs.manageable_todo')
      expect(page).to have_no_content(item1.name)
      expect(page).to have_content(item2.name)

      # copy
      click_on item2.name
      within "#menu" do
        click_on I18n.t("ss.links.copy")
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end
  end
end

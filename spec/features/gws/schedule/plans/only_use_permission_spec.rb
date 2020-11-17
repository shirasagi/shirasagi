require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:use_plan_role) { create :gws_role, permissions: %w(use_private_gws_schedule_plans) }
  let!(:user0) { gws_user }
  let!(:user1) { create :gws_user, group_ids: user0.group_ids, gws_role_ids: [ use_plan_role.id ] }
  let!(:item) { create :gws_schedule_plan, cur_site: site, cur_user: user0, member_ids: [ user1.id ] }

  before { login_user user1 }

  describe "ss-3651" do
    it do
      visit gws_schedule_plans_path(site: site)
      within ".fc-view" do
        expect(page).to have_css(".fc-content", text: item.name)
      end

      within ".fc-view" do
        # click_on item.name
        find(".fc-content", text: item.name).click
      end

      within ".gws-popup" do
        expect(page).to have_css(".popup-title", text: item.name)
        expect(page).to have_css(".popup-members", text: user1.long_name)
        expect(page).to have_css(".popup-history", text: user0.long_name)
        expect(page).to have_css(".popup-menu", text: I18n.t("ss.links.show"))

        click_on I18n.t("ss.links.show")
      end

      expect(page).to have_css("#addon-basic", text: item.name)
    end
  end
end

require 'spec_helper'

describe "gws_schedule_group_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category1) { create :gws_schedule_category, cur_site: site, name: "cate-#{unique_id}" }
  let!(:category2) { create :gws_schedule_category, cur_site: site, name: "cate-#{unique_id}" }
  let!(:category3) { create :gws_schedule_category, cur_site: site, name: "cate-#{unique_id}" }
  let!(:plan1) { create :gws_schedule_plan, cur_site: site, category: category1, member_ids: [gws_user.id] }
  let!(:plan2) { create :gws_schedule_plan, cur_site: site, category: category2, member_ids: [gws_user.id] }
  let!(:plan3) { create :gws_schedule_plan, cur_site: site, category: category3, member_ids: [gws_user.id] }

  before { login_gws_user }

  context "when keyword is given" do
    it do
      visit gws_schedule_group_plans_path(site: site, group: gws_user.groups.first)
      expect(page).to have_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_css(".fc-basic-view", text: plan2.name)
      expect(page).to have_css(".fc-basic-view", text: plan3.name)

      within ".gws-schedule-box .search" do
        fill_in "s[keyword]", with: plan1.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan2.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan3.name)

      within ".gws-schedule-box .search" do
        fill_in "s[keyword]", with: plan2.text
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".fc-basic-view", text: plan2.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan3.name)
    end
  end

  context "when category is given" do
    it do
      visit gws_schedule_group_plans_path(site: site, group: gws_user.groups.first)
      expect(page).to have_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_css(".fc-basic-view", text: plan2.name)
      expect(page).to have_css(".fc-basic-view", text: plan3.name)

      within ".gws-schedule-box .search" do
        select category2.name, from: "s[category_id]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".fc-basic-view", text: plan2.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan3.name)

      within ".gws-schedule-box .search" do
        select category3.name, from: "s[category_id]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".fc-basic-view", text: plan3.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan1.name)
      expect(page).to have_no_css(".fc-basic-view", text: plan2.name)
    end
  end
end

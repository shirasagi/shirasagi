require 'spec_helper'

describe "gws_schedule_search_users", type: :feature, dbscope: :example do
  let!(:user) { gws_user }
  let!(:site) { gws_site }
  let!(:path) { gws_schedule_search_users_path site }
  let!(:user2) { create :gws_user, group_ids: gws_user.group_ids }
  let!(:user3) { create :gws_user, group_ids: gws_user.group_ids }
  let!(:count) { 2 }

  context "with auth", js: true do
    let!(:item1) { create :gws_schedule_plan, cur_user: user, member_ids: [user.id] }
    let!(:item2) { create :gws_schedule_plan, cur_user: user2, member_ids: [user2.id] }
    let!(:item3) { create :gws_schedule_plan, cur_user: user3, member_ids: [user3.id] }

    before { login_gws_user }

    it "#index" do
      visit path
      within "form.search" do
        fill_in "s[keyword]", with: user.name
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_js_ready
      within ".gws-schedule-search" do
        expect(page).to have_selector(".calendar-multiple-header", count: 1)
        within ".calendar-multiple-header" do
          expect(page).to have_content(user.name)
        end
        expect(page).to have_css(".fc-content", text: item1.name)
        expect(page).to have_no_css(".fc-content", text: item2.name)
        expect(page).to have_no_css(".fc-content", text: item3.name)
      end

      within "form.search" do
        fill_in "s[keyword]", with: user2.name
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_js_ready
      within ".gws-schedule-search" do
        expect(page).to have_selector(".calendar-multiple-header", count: 1)
        within ".calendar-multiple-header" do
          expect(page).to have_content(user2.name)
        end
        expect(page).to have_no_css(".fc-content", text: item1.name)
        expect(page).to have_css(".fc-content", text: item2.name)
        expect(page).to have_no_css(".fc-content", text: item3.name)
      end

      within "form.search" do
        fill_in "s[keyword]", with: user3.name
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_js_ready
      within ".gws-schedule-search" do
        expect(page).to have_selector(".calendar-multiple-header", count: 1)
        within ".calendar-multiple-header" do
          expect(page).to have_content(user3.name)
        end
        expect(page).to have_no_css(".fc-content", text: item1.name)
        expect(page).to have_no_css(".fc-content", text: item2.name)
        expect(page).to have_css(".fc-content", text: item3.name)
      end
    end
  end

  context "with auth", js: true do
    before do
      login_gws_user
      @save_config = SS.config.gws.schedule
      SS.config.replace_value_at(:gws, :schedule, @save_config.merge({ "search_users" => { 'max_users' => count } }))
    end

    after do
      SS.config.replace_value_at(:gws, :schedule, @save_config)
    end

    it "over users limit" do
      visit path
      within "form.search" do
        fill_in "s[keyword]", with: '@'
        click_button I18n.t('ss.buttons.search')
      end

      within "#errorExplanation" do
        expect(page).to have_text(I18n.t('gws.errors.plan_search.max_users', count: count))
      end
      expect(page).to have_selector('.calendar-multiple-header', count: count)
    end
  end
end

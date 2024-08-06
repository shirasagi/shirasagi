require 'spec_helper'

describe "gws_schedule_search_users", type: :feature, dbscope: :example do
  let!(:user) { gws_user }
  let!(:site) { gws_site }
  let!(:path) { gws_schedule_search_users_path site }
  let!(:user2) { create :gws_user, group_ids: gws_user.group_ids }
  let!(:user3) { create :gws_user, group_ids: gws_user.group_ids }
  let!(:count) { 2 }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      within "form.search" do
        fill_in "s[keyword]", with: user.name
        click_button I18n.t('ss.buttons.search')
      end

      wait_for_js_ready
      within ".calendar-multiple-header" do
        expect(page).to have_content(user.name)
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

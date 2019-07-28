require 'spec_helper'

describe "gws_schedule_search_users", type: :feature, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_users_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      within "form.search" do
        fill_in "s[keyword]", with: user.name
        click_button I18n.t('ss.buttons.search')
      end

      wait_for_ajax
      within ".calendar-multiple-header" do
        expect(page).to have_content(user.name)
      end
    end
  end
end

require 'spec_helper'

describe "gws_schedule_search_users", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_users_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      within "form.search" do
        fill_in "s[keyword]", with: gws_user.name
        click_button "検索"
      end
      expect(page).to have_content(gws_user.name)
    end
  end
end

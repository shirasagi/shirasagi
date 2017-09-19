require 'spec_helper'

describe "gws_schedule_search_times", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_times_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      within "form.search" do
        first('input[type=submit]').click
      end
      expect(page).to have_content(gws_user.name)
    end
  end
end

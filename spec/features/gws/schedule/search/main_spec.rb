require 'spec_helper'

describe "gws_schedule_search", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      first('.gws-schedule-search-users input[type=submit]').click
      expect(status_code).to eq 200

      visit path
      first('.gws-schedule-search-times input[type=submit]').click
      expect(status_code).to eq 200
    end
  end
end

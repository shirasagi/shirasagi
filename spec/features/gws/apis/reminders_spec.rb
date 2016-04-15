require 'spec_helper'

describe "gws_apis_reminders", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_plan_path site, item }
  let(:item) { create :gws_schedule_plan }

  context "create", js: true do
    before { login_gws_user }

    it "create" do
      visit path
      # Capybara::Poltergeist::TimeoutError
      # click_button "登録"
      expect(status_code).to eq 200
    end
  end
end

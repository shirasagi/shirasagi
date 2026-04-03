require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  before { create_affair_users }

  let(:site) { affair_site }
  let(:user) { affair_user("sup") }
  let(:index_path) { gws_affair_overtime_aggregate_users_main_path(site) }

  context "update group array" do
    before do
      Gws::Aggregation::GroupUpdateJob.bind(site_id: site.id).perform_now
    end

    it "#index" do
      login_user(user)
      visit index_path
      expect(page).to have_css(".gws-attendance")
    end
  end
end

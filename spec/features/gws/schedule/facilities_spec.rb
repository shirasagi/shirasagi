require 'spec_helper'

describe "gws_schedule_facilities", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:facility) { create :gws_facility_item }
  let!(:item) { create :gws_schedule_facility_plan, facility_ids: [facility.id] }
  let(:index_path) { gws_schedule_facilities_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(page).to have_content(item.name)
    end
  end
end

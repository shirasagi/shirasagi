require 'spec_helper'

describe "gws_apis_facilities", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_apis_facilities_path site }
  let(:item) { create :gws_facility_item, name: 'Facility' }

  context "with auth" do
    before { login_gws_user }

    it "index" do
      item

      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)

      click_on "検索"
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)
    end
  end
end

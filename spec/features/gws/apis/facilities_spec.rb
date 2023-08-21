require 'spec_helper'

describe "gws_apis_facilities", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_apis_facilities_path site }
  let!(:cate) { create :gws_facility_category }
  let!(:item1) { create :gws_facility_item }
  let!(:item2) { create :gws_facility_item, category_id: cate.id }

  context "with auth" do
    before { login_gws_user }

    it "index" do
      visit path
      expect(page).to have_content(item1.name)
      expect(page).to have_content(item2.name)

      visit "#{path}?s[category]=#{cate.id}"
      expect(page).to have_no_content(item1.name)
      expect(page).to have_content(item2.name)
    end
  end
end

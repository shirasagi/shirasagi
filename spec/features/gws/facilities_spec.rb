require 'spec_helper'

describe "gws_facility_items", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_facility_item }
  let(:index_path) { gws_facility_items_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path

    it_behaves_like 'crud flow'
  end
end

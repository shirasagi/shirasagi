require 'spec_helper'

describe "gws_facility_usage", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_facility_usage_main_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).to include("/monthly") # redirect
    end
  end
end

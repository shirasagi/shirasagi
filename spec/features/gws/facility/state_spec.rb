require 'spec_helper'

describe "gws_facility_state", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_facility_state_main_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).to include("/daily") # redirect
    end
  end
end

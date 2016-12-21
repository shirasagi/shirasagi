require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_site_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end

require 'spec_helper'

describe "gws_apis_files", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_apis_files_path site }

  context "with auth" do
    before { login_gws_user }

    it "index" do
      visit path
      expect(status_code).to eq 200
    end
  end
end

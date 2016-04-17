require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "without login/auth" do
    let(:site) { gws_site }
    let(:index_path) { gws_schedule_plans_path site }

    it "without login" do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end
end

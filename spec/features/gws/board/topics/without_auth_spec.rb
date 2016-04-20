require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  context "without auth" do
    let(:site) { gws_site }
    let(:index_path) { gws_board_topics_path site }

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

require 'spec_helper'

describe "ads_access_logs" do
  subject(:site) { cms_site }
  subject(:node) { create_once :ads_node_banner, name: "ads" }
  subject(:index_path) { ads_access_logs_path site.host, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

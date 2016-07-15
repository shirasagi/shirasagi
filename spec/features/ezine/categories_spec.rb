require 'spec_helper'

describe "ezine_node_category_nodes", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :ezine_node_category_node, cur_site: site }
  let(:index_path) { ezine_category_nodes_path site.id, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

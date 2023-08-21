require 'spec_helper'

describe "cms_node_site_searches", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:path) { node_site_searches_path(site, node) }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit path
      expect(current_path).to eq node_nodes_path(site.id, node)
    end
  end
end

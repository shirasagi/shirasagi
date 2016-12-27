require 'spec_helper'

describe "urgency_layouts" do
  subject(:site) { cms_site }
  subject(:node) { create_once :urgency_node_layout, name: "urgency" }
  subject(:item) { Uploader::File.last }
  subject(:index_path) { urgency_layouts_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

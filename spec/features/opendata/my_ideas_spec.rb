require 'spec_helper'

describe "opendata_my_ideas", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_my_idea, name: "opendata_my_idea" }

  let(:index_path) { opendata_my_ideas_path site.host, node }

  context "my_ideas" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      #expect(current_path).not_to eq sns_login_path
    end
  end
end

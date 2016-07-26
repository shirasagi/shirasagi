require 'spec_helper'

describe "opendata_search_ideas", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_search_idea, name: "opendata_search_ideas" }

  let(:index_path) { opendata_search_ideas_path site, node }

  context "search_idea" do
    before { login_cms_user }

    it "#index" do
      visit index_path
    end
  end
end

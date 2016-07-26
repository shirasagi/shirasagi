require 'spec_helper'

describe "opendata_search_apps", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_search_app, name: "opendata_search_apps" }

  let(:index_path) { opendata_search_apps_path site, node }

  context "search_app" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

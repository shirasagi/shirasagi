require 'spec_helper'

describe "opendata_apis", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_api, name: "opendata_apis" }

  let(:index_path) { opendata_apis_path site.host, node }

  context "api" do
    before { login_cms_user }

    it "#index" do
      visit index_path
    end
  end
end

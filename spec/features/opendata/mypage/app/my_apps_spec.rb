require 'spec_helper'

describe "opendata_my_apps", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_my_app, name: "opendata_my_app" }

  let(:index_path) { opendata_my_apps_path site.host, node }

  context "my_apps" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

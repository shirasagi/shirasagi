require 'spec_helper'

describe "opendata_app_categories", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_app_category, name: "opendata_app_categories" }

  let(:index_path) { opendata_app_categories_path site.host, node }

  context "app_categories" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end

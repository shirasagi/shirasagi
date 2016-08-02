require 'spec_helper'

describe "opendata_sparqls", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_sparql, name: "opendata_sparqls" }

  let(:index_path) { opendata_sparqls_path site, node }

  context "sparql" do
    before { login_cms_user }

    it "#index" do
      visit index_path
    end
  end
end

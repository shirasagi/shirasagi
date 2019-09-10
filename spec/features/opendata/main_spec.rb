require 'spec_helper'

describe "opendata_main", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "with auth" do
    before { login_cms_user }

    context "when dataset node is given" do
      let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
      let(:index_path) { opendata_main_path site, node }

      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq opendata_datasets_path(site, node)
      end
    end

    context "when app node is given" do
      let(:node) { create_once :opendata_node_app, name: "opendata_app" }
      let(:index_path) { opendata_main_path site, node }

      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq opendata_apps_path(site, node)
      end
    end

    context "when idea node is given" do
      let(:node) { create_once :opendata_node_idea, name: "opendata_idea" }
      let(:index_path) { opendata_main_path site, node }

      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq opendata_ideas_path(site, node)
      end
    end
  end
end

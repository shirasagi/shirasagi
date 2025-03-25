require 'spec_helper'
require "csv"

describe "Opendata::Dataset::ResourceFilter", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let!(:node_search) do
    create(:opendata_node_search_dataset, layout: layout, filename: "dataset/search")
  end
  let!(:page_dataset) { create :opendata_dataset, layout: layout, cur_node: node_dataset }
  let!(:license) { create :opendata_license, cur_site: site }

  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "graph.csv") }
  let(:dataset_resource) { page_dataset.resources.new(attributes_for(:opendata_resource)) }

  let(:content_path) do
    ::File.join(node_dataset.full_url,
      page_dataset.basename.delete_suffix(".html"),
      "resource",
      dataset_resource.id.to_s,
      "content.html")
  end

  let(:referer) { page_dataset.full_url }
  let(:generic_ua) { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100" }
  let(:bot_ua) { "Mozilla/5.0 (compatible; SSBot/0.1; +https://sample.example.jp/bot/)" }

  before do
    Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec") do |f|
      dataset_resource.in_file = f
      dataset_resource.license_id = license.id
      dataset_resource.preview_graph_state = "enabled"
      dataset_resource.preview_graph_types = %w(bar line pie)
      dataset_resource.save!
    end
    Fs.rm_rf page_dataset.path
  end

  context "generic ua" do
    context "from page" do
      let(:headers) { { "HTTP_USER_AGENT" => generic_ua, "HTTP_REFERER" => referer } }

      it "#content" do
        get content_path, headers: headers
        expect(response.status).to eq 200
      end
    end

    context "no referer" do
      let(:headers) { { "HTTP_USER_AGENT" => generic_ua } }

      it "#content" do
        get content_path, headers: headers
        expect(response.status).to eq 404
      end
    end
  end

  context "bot ua" do
    context "from page" do
      let(:headers) { { "HTTP_USER_AGENT" => bot_ua, "HTTP_REFERER" => referer } }

      it "#content" do
        get content_path, headers: headers
        expect(response.status).to eq 404
      end
    end

    context "no referer" do
      let(:headers) { { "HTTP_USER_AGENT" => bot_ua } }

      it "#content" do
        get content_path, headers: headers
        expect(response.status).to eq 404
      end
    end
  end
end

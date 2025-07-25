require 'spec_helper'

describe "opendata_agents_nodes_dataset_resource", type: :feature, dbscope: :example, js: true do
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

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "index" do
      visit page_dataset.full_url

      within ".resources .resource" do
        wait_for_cbox_opened do
          click_on I18n.t("opendata.labels.preview")
        end
      end
      within_cbox do
        within ".tabs .tab.graph" do
          click_on I18n.t("opendata.labels.graph_view")
        end
      end
      wait_for_ajax
      within_cbox do
        within ".resource-content[data-graph-style='bar']" do
          expect(page).to have_css(".graph-types button", text: I18n.t("opendata.graph_types.bar"))
          expect(page).to have_css(".graph-types button", text: I18n.t("opendata.graph_types.line"))
          expect(page).to have_css(".graph-types button", text: I18n.t("opendata.graph_types.pie"))
          expect(page).to have_css(".graph-warp.loaded")
          canvas_to_png(first("canvas.graph")).tap do |data_url|
            extract_image_info_from_data_url(data_url).tap do |info|
              expect(info[:width]).to be > 100
              expect(info[:height]).to be > 100
              expect(info[:size]).to be > 10_240
            end
          end
          within ".graph-types" do
            click_on I18n.t("opendata.graph_types.line")
          end
        end
      end

      wait_for_ajax

      within_cbox do
        within ".resource-content[data-graph-style='line']" do
          expect(page).to have_css(".graph-warp.loaded")
          canvas_to_png(first("canvas.graph")).tap do |data_url|
            extract_image_info_from_data_url(data_url).tap do |info|
              expect(info[:width]).to be > 100
              expect(info[:height]).to be > 100
              expect(info[:size]).to be > 10_240
            end
          end
          within ".graph-types" do
            click_on I18n.t("opendata.graph_types.pie")
          end
        end
      end

      wait_for_ajax

      within_cbox do
        within ".resource-content[data-graph-style='pie']" do
          expect(page).to have_css(".graph-warp.loaded")
          canvas_to_png(first("canvas.graph")).tap do |data_url|
            extract_image_info_from_data_url(data_url).tap do |info|
              expect(info[:width]).to be > 100
              expect(info[:height]).to be > 100
              expect(info[:size]).to be > 10_240
            end
          end
          within ".graph-types" do
            click_on I18n.t("opendata.graph_types.bar")
          end
        end
      end
      wait_for_ajax
      within_cbox do
        within ".resource-content[data-graph-style='bar']" do
          expect(page).to have_css(".graph-warp.loaded")
          canvas_to_png(first("canvas.graph")).tap do |data_url|
            extract_image_info_from_data_url(data_url).tap do |info|
              expect(info[:width]).to be > 100
              expect(info[:height]).to be > 100
              expect(info[:size]).to be > 10_240
            end
          end
        end
      end
    end
  end
end

require 'spec_helper'

describe "opendata_agents_pages_dataset", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:area) { create_once :opendata_node_area, filename: "opendata_area_1" }
  let!(:node_dataset) { create_once :opendata_node_dataset }
  let!(:node_area) { create :opendata_node_area }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, filename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, cur_node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create_once :opendata_node_dataset_category }
  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:index_path) { page_dataset.url }

  context "public" do
    before do
      dataset_resource = page_dataset.resources.new

      file = Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec")
      file.original_filename = "shift_jis.csv"

      dataset_resource.in_file = file
      dataset_resource.license = license
      dataset_resource.name = "shift_jis.csv"
      dataset_resource.save!

      Fs.rm_rf page_dataset.path

      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path
      within "div#dataset-tabs-1" do
        within "article#cms-tab-1-0" do
          expect(page).to have_content(page_dataset.resources.first.name)
          expect(page).to have_css("img[src=\"#{license.file.url}\"]")
          expect(page).to have_css("a", text: I18n.t("opendata.labels.preview"))
          expect(page).to have_css("a", text: I18n.t("opendata.labels.downloaded"))
          expect(page).to have_css("a", text: "URLをコピー")
        end
      end
    end
  end
end

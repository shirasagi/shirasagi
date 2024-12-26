require 'spec_helper'

describe "opendata_agents_pages_dataset", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:area) { create :opendata_node_area, layout: layout, filename: "opendata_area1" }
  let!(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let!(:node_area) { create :opendata_node_area, layout: layout }
  let!(:node_search_dataset) { create :opendata_node_search_dataset, layout: layout, filename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, layout: layout, cur_node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create :opendata_node_dataset_category, layout: layout }
  let!(:license) { create(:opendata_license, cur_site: site) }

  let(:pdf_path) { Rails.root.join("spec", "fixtures", "opendata", "resource.pdf") }

  context "preview pdf" do
    before do
      @rs1 = page_dataset.resources.new
      @rs1.license = license
      @rs1.name = "resource.pdf"
      Fs::UploadedFile.create_from_file(pdf_path, basename: "spec") do |file|
        file.original_filename = "resource.pdf"

        @rs1.in_file = file
        @rs1.save!
      end

      page_dataset.reload
      page_dataset.save
      expect(page_dataset.resources.count).to eq 1

      FileUtils.rm_f(page_dataset.path)
    end

    it "#index" do
      visit page_dataset.full_url

      expect(page).to have_css(".point .count .number", text: "0")
      expect(page).to have_css(".dataset-apps .detail .dataset-apps")
      expect(page).to have_css(".dataset-ideas .detail .dataset-ideas")

      wait_for_cbox_opened { click_on I18n.t("opendata.labels.preview") }
      within_cbox do
        within ".resource-pdf" do
          imgs = all('img').to_a
          srcs = imgs.map { |ele| ele['src'] }

          expect(imgs.size).to eq 3
          srcs.each do |src|
            expect(src.start_with?('data:image/png;base64,')).to eq true
          end
        end
      end
    end
  end
end

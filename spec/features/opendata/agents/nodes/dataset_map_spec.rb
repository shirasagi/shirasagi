require 'spec_helper'

describe "opendata_agents_nodes_dataset_map", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :opendata_node_dataset_map, layout_id: layout.id, filename: "node" }

  let(:node_dataset) { create_once :opendata_node_dataset, name: "datasets" }
  let!(:node_search) { create_once :opendata_node_search_dataset }

  let(:license) { create(:opendata_license, cur_site: site) }

  let(:item1) { create :opendata_dataset, cur_node: node_dataset }
  let(:item2) { create :opendata_dataset, cur_node: node_dataset }
  let(:item3) { create :opendata_dataset, cur_node: node_dataset }
  let(:item4) { create :opendata_dataset, cur_node: node_dataset }
  let(:item5) { create :opendata_dataset, cur_node: node_dataset }
  let(:item6) { create :opendata_dataset, cur_node: node_dataset }
  let(:item7) { create :opendata_dataset, cur_node: node_dataset }
  let(:item8) { create :opendata_dataset, cur_node: node_dataset }
  let(:item9) { create :opendata_dataset, cur_node: node_dataset }
  let(:item10) { create :opendata_dataset, cur_node: node_dataset }
  let(:item11) { create :opendata_dataset, cur_node: node_dataset }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"

      (1..11).each do |i|
        file = Fs::UploadedFile.create_from_file("spec/fixtures/opendata/location.csv")
        resource = Opendata::Resource.new
        resource.name = "location"
        resource.license = license
        resource.in_file = file

        item = send("item#{i}")
        item.resources = [resource]
        item.save!
      end
    end

    it "#index" do
      (1..11).each do |i|
        resource = send("item#{i}").resources.first
        expect(resource.map_resources).to be_present
      end

      visit node.url
      expect(page).to have_css(".dataset-search")

      within ".dataset-search" do
        click_on I18n.t("opendata.links.dataset_map_search_datasets")
        wait_for_cbox
      end

      # search
      within "#ajax-box" do
        fill_in "s[keyword]", with: I18n.t("opendata.links.dataset_map_search_datasets")
        first('input[name="commit"]').click
        wait_for_cbox
      end
      expect(page).to have_no_css(".dataset-name", text: item11.name)

      # reset
      within "#ajax-box" do
        first("a", text: I18n.t("ss.buttons.reset")).click
        wait_for_cbox
      end
      expect(page).to have_css(".dataset-name", text: item11.name)

      # select
      within "#ajax-box" do
        fill_in "s[keyword]", with: I18n.t("opendata.links.dataset_map_search_datasets")
        wait_for_cbox
      end

      within "#ajax-box" do
        first("a", text: item11.name).click
      end

      within ".dataset-search" do
        click_on I18n.t("opendata.links.dataset_map_search_datasets")
        wait_for_cbox
      end

      # pagination
      within "#ajax-box" do
        click_on I18n.t("views.pagination.next")
        wait_for_cbox
      end

      within "#ajax-box" do
        first("a", text: item1.name).click
      end

      within ".dataset-search" do
        expect(page).to have_css(".dataset-name", text: item1.name)
        expect(page).to have_css(".dataset-name", text: item11.name)
      end
    end
  end
end

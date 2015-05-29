require 'spec_helper'

describe "opendata_agents_nodes_search_dataset", dbscope: :example do
  let(:site) { cms_site }
  let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let(:node_dataset) { create_once :opendata_node_dataset }
  let(:node_area) { create :opendata_node_area }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, basename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create_once :opendata_node_dataset_category }
  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:dataset_resource) { page_dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
  let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
  let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
  let(:index_path) { "#{node_search_dataset.url}index.html" }
  let(:rss_path) { "#{node_search_dataset.url}rss.xml" }

  before do
    Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec") do |f|
      dataset_resource.in_file = f
      dataset_resource.license_id = license.id
      dataset_resource.save!
    end
  end

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
      within "form.opendata-search_datasets-form" do
        within "dl.keyword" do
          expect(page).to have_field('s[keyword]')
        end
        within "dl.category" do
          expect(page).to have_field('s[category_id]')
        end
        within "dl.area" do
          expect(page).to have_field('s[area_id]')
        end
        within "dl.tag" do
          expect(page).to have_field('s[tag]')
        end
        within "dl.format" do
          expect(page).to have_field('s[format]')
        end
        within "dl.license" do
          expect(page).to have_field('s[license_id]')
        end
      end
    end
  end

  it "#rss" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit rss_path
      expect(current_path).to eq rss_path
      expect(page).to have_xpath('//rss/channel/item')
      expect(page).to have_xpath('//rss/channel/item/title')
      expect(page).to have_xpath('//rss/channel/item/link')
      # expect(page).to have_xpath('//rss/channel/item/pubDate')
      # expect(page).to have_xpath('//rss/channel/item/dc:date')
    end
  end
end

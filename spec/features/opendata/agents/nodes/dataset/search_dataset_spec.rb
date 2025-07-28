require 'spec_helper'

describe "opendata_agents_nodes_search_dataset", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:area) { create :opendata_node_area, layout: layout, filename: "opendata_area_1" }
  let(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let(:node_area) { create :opendata_node_area, layout: layout }
  let(:category_folder) { create(:cms_node_node, layout: layout, filename: "category") }
  let(:category) do
    create(
      :opendata_node_category, layout: layout,
      filename: "#{category_folder.filename}/opendata_category1",
      depth: category_folder.depth + 1)
  end
  let!(:node_search_dataset) do
    create(
      :opendata_node_search_dataset, layout: layout,
      filename: "#{node_dataset.filename}/search",
      depth: node_dataset.depth + 1)
  end
  let!(:page_dataset) { create(:opendata_dataset, layout: layout, cur_node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) do
    create(
      :opendata_node_dataset_category, layout: layout,
      filename: "#{node_dataset.filename}/category",
      depth: node_dataset.depth + 1)
  end
  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:dataset_resource) { page_dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:license) { create(:opendata_license, cur_site: site) }
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
      within "form.opendata-search-datasets-form" do
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
    layout.html = <<~HTML
      <html>
      <body>
        <br><br><br>
        <h1 id="ss-page-name">\#{page_name}</h1><br>
        <div id="main" class="page">
          {{ yield }}
          <div class="list-footer">
            <a href="#{rss_path}" download>RSS</a>
          </div>
        </div>
      </body>
      </html>
    HTML
    layout.save!

    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)

      visit index_path
      within ".list-footer" do
        click_on "RSS"
      end

      xmldoc = REXML::Document.new(page.html)
      title = REXML::XPath.first(xmldoc, "/rss/channel/title/text()").to_s.strip
      expect(title).to start_with(node_search_dataset.name)
      link = REXML::XPath.first(xmldoc, "/rss/channel/link/text()").to_s.strip
      expect(link).to end_with(node_search_dataset.url)
      items = REXML::XPath.match(xmldoc, "/rss/channel/item")
      expect(items).to have(1).items
    end
  end
end

require 'spec_helper'

describe "opendata_agents_nodes_dataset_category", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node_category_folder) { create :cms_node_node, layout: layout, filename: "category" }
  let!(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let!(:node) do
    create(
      :opendata_node_dataset_category, layout: layout,
      filename: "#{node_dataset.filename}/#{node_category_folder.filename}",
      depth: node_dataset.depth + 1)
  end
  let!(:node_kurashi) do
    create(
      :opendata_node_category, layout: layout,
      filename: "#{node_category_folder.filename}/kurashi",
      depth: node_category_folder.depth + 1)
  end
  let!(:node_search) do
    create(:opendata_node_search_dataset, layout: layout, filename: "dataset/search")
  end

  let(:index_path) { "#{node.url}/kurashi" }
  let(:rss_path) { "#{node.url}/kurashi/rss.xml" }
  let(:nothing_path) { "#{node.url}index.html" }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
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
      expect(title).to start_with(node_kurashi.name)
      link = REXML::XPath.first(xmldoc, "/rss/channel/link/text()").to_s.strip
      expect(link).to end_with(node.url)
      items = REXML::XPath.match(xmldoc, "/rss/channel/item")
      expect(items).to have(0).items
    end
  end

  it "#nothing" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit nothing_path
      expect(current_path).to eq nothing_path
    end
  end
end

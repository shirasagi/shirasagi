require 'spec_helper'

describe "opendata_search_apps", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_app) { create :opendata_node_app, layout: layout }
  let(:node) do
    create(
      :opendata_node_search_app, layout: layout,
      filename: "#{node_app.filename}/search",
      depth: node_app.depth + 1,
      name: "opendata_search_apps")
  end
  before do
    node_category_folder = create(:cms_node_node, layout: layout, filename: "category")
    create(
      :opendata_node_category, layout: layout,
      filename: "#{node_category_folder.filename}/kurashi",
      depth: node_category_folder.depth + 1)
  end

  let(:index_path) { "#{node.url}index.html" }
  let(:rss_path) { "#{node.url}rss.xml" }

  context "search_app" do
    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit index_path
        expect(current_path).to eq index_path
      end
    end

    it "#index released" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=released"
        expect(current_path).to eq index_path
      end
    end

    it "#index popular" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=popular"
        expect(current_path).to eq index_path
      end
    end

    it "#index attention" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=attention"
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
        expect(title).to start_with(node.name)
        link = REXML::XPath.first(xmldoc, "/rss/channel/link/text()").to_s.strip
        expect(link).to end_with(node.url)
        items = REXML::XPath.match(xmldoc, "/rss/channel/item")
        expect(items).to have(0).items
      end
    end
  end
end

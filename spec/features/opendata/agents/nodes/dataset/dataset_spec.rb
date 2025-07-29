require 'spec_helper'

describe "opendata_agents_nodes_dataset", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:area) { create :opendata_node_area, layout: layout, filename: "opendata_area_1" }
  let(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let(:node_area) { create :opendata_node_area, layout: layout }
  let!(:node_search_dataset) { create :opendata_node_search_dataset, layout: layout, filename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, cur_node: node_dataset, layout: layout, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create :opendata_node_dataset_category, layout: layout }
  let(:dataset_resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let(:index_path) { "#{node_dataset.url}index.html" }
  let(:rss_path) { "#{node_dataset.url}rss.xml" }
  let(:areas_path) { "#{node_dataset.url}areas.html" }
  let(:tags_path) { "#{node_dataset.url}tags.html" }
  let(:formats_path) { "#{node_dataset.url}formats.html" }
  let(:licenses_path) { "#{node_dataset.url}licenses.html" }

  let(:show_point_path) { page_dataset.point_url }
  let(:point_members_path) { page_dataset.point_members_url }
  let(:dataset_apps_path) { page_dataset.dataset_apps_url }
  let(:dataset_ideas_path) { page_dataset.dataset_ideas_url }

  let(:datasets_search_path) { "#{node_dataset.url}datasets/search" }

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

  it "index, preview" do
    visit index_path
    within "article#cms-tab-#{node_dataset.id}-0-view" do
      within "div.pages" do
        click_link page_dataset.name
      end
    end

    within "article#cms-tab-#{node_dataset.id}-0-view" do
      within "div.pages" do
        wait_for_cbox_opened { click_link 'プレビュー' }
      end
    end

    within_cbox do
      within "div.resource-content" do
        within "table.cells" do
          expect(page).to have_content('品川')
          expect(page).to have_content('新宿')
        end
      end
    end
  end

  it "index, download" do
    visit index_path
    within "article#cms-tab-#{node_dataset.id}-0-view" do
      within "div.pages" do
        click_link page_dataset.name
      end
    end

    within "article#cms-tab-#{node_dataset.id}-0-view" do
      within "div.pages" do
        click_link 'ダウンロード'
      end
    end

    wait_for_download
    expect(File.size(downloads.first)).to be > 0
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

    visit rss_path

    REXML::Document.new(page.html).tap do |xmldoc|
      rss = REXML::XPath.first(xmldoc, "//rss")
      title = REXML::XPath.first(rss, "channel/title/text()").to_s.strip
      expect(title).to start_with(node_dataset.name)
      link = REXML::XPath.first(rss, "channel/link/text()").to_s.strip
      expect(link).to eq node_dataset.full_url
      items = REXML::XPath.match(rss, "channel/item")
      expect(items).to have(1).items
    end

    visit index_path
    within ".list-footer" do
      click_on "RSS"
    end

    wait_for_download
    expect(File.size(downloads.first)).to be > 0

    REXML::Document.new(File.read(downloads.first)).tap do |xmldoc|
      title = REXML::XPath.first(xmldoc, "/rss/channel/title/text()").to_s.strip
      expect(title).to start_with(node_dataset.name)
      link = REXML::XPath.first(xmldoc, "/rss/channel/link/text()").to_s.strip
      expect(link).to end_with(node_dataset.url)
      items = REXML::XPath.match(xmldoc, "/rss/channel/item")
      expect(items).to have(1).items
    end
  end

  it "#areas" do
    visit areas_path
    expect(page).to have_css(".name", text: node_area.name)
  end

  it "#tags" do
    visit tags_path
    expect(page).to have_css(".name", count: 2)
    expect(page).to have_css(".name", text: page_dataset.tags[0])
    expect(page).to have_css(".name", text: page_dataset.tags[1])
  end

  it "#formats" do
    visit formats_path
    expect(page).to have_css(".name", count: 1)
    expect(page).to have_css(".name", text: 'CSV')
  end

  it "#licenses" do
    visit licenses_path
    expect(page).to have_css(".name", count: 1)
    expect(page).to have_css(".name", text: license.name)
  end

  it "#show_point" do
    visit show_point_path
    expect(page).to have_css(".count", text: 'いいね！')
  end

  it "#point_members" do
    visit point_members_path
    expect(page).to have_selector('ul.point-members')
  end

  it "#show_apps" do
    visit dataset_apps_path
    within "div.detail" do
      within "div.dataset-apps" do
        expect(page).to have_selector('div.apps')
      end
    end
  end

  it "#show_ideas" do
    visit dataset_ideas_path
    within "div.detail" do
      within "div.dataset-ideas" do
        expect(page).to have_selector('div.ideas')
      end
    end
  end

  it "#datasets_search" do
    visit datasets_search_path
    expect(page).to have_css(".search [type='submit']")
    expect(page).to have_css(".items tr", count: 1)
    expect(page).to have_css(".items tr[data-id='#{page_dataset.id}']", text: page_dataset.name)
  end
end

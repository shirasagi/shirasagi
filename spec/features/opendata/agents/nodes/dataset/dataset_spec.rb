require 'spec_helper'

describe "opendata_agents_nodes_dataset", dbscope: :example do
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
    Fs::UploadedFile.create_from_file(dataset_resource_file_path, basename: "spec") do |f|
      dataset_resource.in_file = f
      dataset_resource.license_id = license.id
      dataset_resource.save!
    end
  end

  it "index, preview" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
      within "article#cms-tab-#{node_dataset.id}-0" do
        within "div.pages" do
          click_link page_dataset.name
        end
      end
      expect(status_code).to eq 200

      within "article#cms-tab-#{node_dataset.id}-0" do
        within "div.pages" do
          click_link 'プレビュー'
        end
      end
      expect(status_code).to eq 200

      within "div.resource-content" do
        within "table.cells" do
          expect(page).to have_content('品川')
          expect(page).to have_content('新宿')
        end
      end
    end
  end

  it "index, download" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
      within "article#cms-tab-#{node_dataset.id}-0" do
        within "div.pages" do
          click_link page_dataset.name
        end
      end
      expect(status_code).to eq 200

      within "article#cms-tab-#{node_dataset.id}-0" do
        within "div.pages" do
          click_link 'ダウンロード'
        end
      end
      expect(status_code).to eq 200
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

  it "#areas" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit areas_path
      expect(current_path).to eq areas_path
      expect(page).to have_content(node_area.name)
    end
  end

  it "#tags" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit tags_path
      expect(current_path).to eq tags_path
      expect(page).to have_content(page_dataset.tags[0])
      expect(page).to have_content(page_dataset.tags[1])
    end
  end

  it "#formats" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit formats_path
      expect(current_path).to eq formats_path
      expect(page).to have_content('CSV')
    end
  end

  it "#licenses" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit licenses_path
      expect(current_path).to eq licenses_path
      expect(page).to have_content(license.name)
    end
  end

  it "#show_point" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit show_point_path
      expect(current_path).to eq show_point_path
      expect(page).to have_content('いいね！')
    end
  end

  it "#point_members" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit point_members_path
      expect(current_path).to eq point_members_path
      expect(page).to have_selector('ul.point-members')
    end
  end

  it "#show_apps" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit dataset_apps_path
      expect(current_path).to eq dataset_apps_path
      within "div.detail" do
        within "div.dataset-apps" do
          expect(page).to have_selector('div.apps')
        end
      end
    end
  end

  it "#show_ideas" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit dataset_ideas_path
      expect(current_path).to eq dataset_ideas_path
      within "div.detail" do
        within "div.dataset-ideas" do
          expect(page).to have_selector('div.ideas')
        end
      end
    end
  end

  it "#datasets_search" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit datasets_search_path
      expect(current_path).to eq datasets_search_path
    end
  end
end

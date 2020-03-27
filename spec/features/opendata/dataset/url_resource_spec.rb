require 'spec_helper'

describe "opendata_url_resource", dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let!(:license) do
    create(:opendata_license, cur_site: site)
  end
  let(:csv_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv").to_s }
  let(:name) { "name-#{unique_id}" }
  let(:filename) { "file-#{unique_id}.csv" }
  let(:original_url) { "http://#{unique_domain}/#{filename}" }
  let(:text) { "text-#{unique_id}" }
  let(:text2) { "text-#{unique_id}" }

  context "basic crud" do
    before do
      WebMock.reset!

      headers = { "Content-Type" => "text/csv", "Content-Disposition" => "attachment; filename=\"#{filename}\"" }
      stub_request(:get, original_url).
        to_return(status: 200, body: ::File.binread(csv_path), :headers => headers)

      login_cms_user
    end

    after { WebMock.reset! }

    it do
      #
      # Create
      #
      visit opendata_dataset_path(site: site, cid: node, id: dataset)
      within "#addon-opendata-agents-addons-url_resource" do
        click_button I18n.t("opendata.manage_url_resources")
      end
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[original_url]", with: original_url
        fill_in "item[name]", with: name
        select  license.name, from: "item_license_id"
        select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
        fill_in "item[text]", with: text
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      dataset.reload
      expect(dataset.url_resources.count).to eq 1
      item = dataset.url_resources.first
      expect(item.original_url).to eq original_url
      expect(item.name).to eq name
      expect(item.filename).to eq filename
      expect(item.format).to eq "CSV"
      expect(item.license.id).to eq license.id
      expect(item.crawl_update).to eq "auto"
      expect(item.crawl_state).to eq "same"
      expect(item.text).to eq text
      expect(item.map_resources).to be_blank
      expect(item.harvest_imported_attributes).to be_blank
      expect(item.harvest_text_index).to be_blank
      expect(item.uuid).to be_present
      expect(item.original_updated).to be_present
      expect(item.revision_id).to be_present
      expect(item.file).to be_present
      expect(item.file.name).to eq filename
      expect(item.file.filename).to eq filename
      expect(item.file.size).to be > 0
      expect(item.file.site_id).to eq site.id
      expect(item.file.owner_item_id).to eq dataset.id
      expect(item.file.owner_item_type).to eq dataset.class.name
      expect(item.file.state).to eq "closed"
      expect(item.file.model).to eq "opendata/url_resource"
      expect(item.file.content_type).to eq "text/comma-separated-values"

      #
      # Content
      #
      visit opendata_dataset_path(site: site, cid: node, id: dataset)
      within "#addon-opendata-agents-addons-url_resource" do
        click_button I18n.t("opendata.manage_url_resources")
      end
      click_on item.name
      click_on I18n.t("mongoid.attributes.opendata/url_resource.content")
      expect(page).to have_content("[#{item.name}]")
      expect(page).to have_css(".tsv-preview")

      #
      # Download
      #
      visit opendata_dataset_path(site: site, cid: node, id: dataset)
      within "#addon-opendata-agents-addons-url_resource" do
        click_button I18n.t("opendata.manage_url_resources")
      end
      click_on item.name
      click_on ::File.basename(item.filename)

      wait_for_download
      expect(::File.binread(downloads.first)).to eq ::File.binread(csv_path)

      #
      # Update
      #
      visit opendata_dataset_path(site: site, cid: node, id: dataset)
      within "#addon-opendata-agents-addons-url_resource" do
        click_button I18n.t("opendata.manage_url_resources")
      end
      click_on item.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[text]", with: text2
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      dataset.reload
      item = dataset.url_resources.first
      expect(item.text).to eq text2

      #
      # Delete
      #
      visit opendata_dataset_path(site: site, cid: node, id: dataset)
      within "#addon-opendata-agents-addons-url_resource" do
        click_button I18n.t("opendata.manage_url_resources")
      end
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      dataset.reload
      expect(dataset.url_resources.count).to eq 0
    end
  end
end

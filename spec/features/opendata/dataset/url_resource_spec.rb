require 'spec_helper'

describe "opendata_url_resource", dbscope: :example, http_server: true do
  # http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "opendata")

  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, node: node) }
  let(:license) do
    file = Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png"))
    create(:opendata_license, site: site, file: file)
  end
  let!(:item) do
    file = Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png"))
    create(:opendata_license, site: site, file: file)
  end
  let(:content_type) { "application/vnd.ms-excel" }
  let(:index_path) { opendata_dataset_url_resources_path site, node, dataset_id: dataset.id }
  let(:new_path) { new_opendata_dataset_url_resource_path site, node, dataset_id: dataset.id }
  let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let(:download_path) do
    opendata_dataset_url_resource_file_path site,
      node,
      dataset_id: dataset.id,
      url_resource_id: subject.id
    end

  subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }
  before do
    subject.license_id = license.id
    subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
    subject.crawl_update = "none"
    subject.save!
  end

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "without auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[original_url]", with: "http://#{http.addr}:#{http.port}/shift_jis.csv"
        fill_in "item[name]", with: "sample"
        select  item.name, from: "item_license_id"
        select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
        fill_in "item[text]", with: "text"
        click_button I18n.t("views.button.save")
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
      click_on I18n.t("mongoid.attributes.opendata/url_resource.content")
      expect(current_path).not_to eq new_path
    end

    it "#download" do
      visit download_path
      expect(current_path).to eq download_path
    end

  end
end

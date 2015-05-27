require 'spec_helper'

describe "opendata_url_resource", dbscope: :example, http_server: true,
           doc_root: Rails.root.join("spec", "fixtures", "opendata") do

   let(:site) { cms_site }
   let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
   let(:node) { create(:opendata_node_dataset) }
   let(:dataset) { create(:opendata_dataset, node: node) }
   let(:license_logo_file) { Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
   let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
   let!(:item) { create(:opendata_license, site: site, file: license_logo_file) }
   let(:content_type) { "application/vnd.ms-excel" }
   let(:index_path) { opendata_dataset_url_resources_path site.host, node, dataset_id: dataset.id }
   let(:new_path) { new_opendata_dataset_url_resource_path site.host, node, dataset_id: dataset.id }
   let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
   let(:download_path) do
     opendata_dataset_url_resource_file_path site.host,
       node,
       dataset_id: dataset.id,
       url_resource_id: subject.id
   end

   subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }
   before do
     subject.license_id = license.id
     subject.original_url = "http://#{@http_server.bind_addr}:#{@http_server.port}/shift_jis.csv"
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
        fill_in "item[original_url]", with: "http://#{@http_server.bind_addr}:#{@http_server.port}/shift_jis.csv"
        fill_in "item[name]", with: "sample"
        select  item.name, from: "item_license_id"
        select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
        fill_in "item[text]", with: "text"
        click_button I18n.t("views.button.save")
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#download" do
      visit download_path
      expect(current_path).to eq download_path
    end

  end
end


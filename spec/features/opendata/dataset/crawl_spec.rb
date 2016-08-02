require 'spec_helper'

describe "opendata_crawl", dbscope: :example, http_server: true do
  # http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "opendata")

  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:index_path) { opendata_crawls_path site, node }
  let(:license_logo_file) { Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, cur_site: site, in_file: license_logo_file) }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth seatch updated and deleted" do
    before { login_cms_user }

  subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
  before do
    subject.license_id = license.id
    subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
    subject.crawl_update = "none"
    subject.save!
  end

    it "#index" do
      visit index_path
      check "s_search_updated"
      check "s_search_deleted"
      click_button I18n.t("views.button.search")
      expect(current_path).not_to eq sns_login_path
    end
  end

   context "with auth seatch updated" do
     before { login_cms_user }

   subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
   before do
     subject.license_id = license.id
     subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
     subject.crawl_update = "none"
     subject.save!
   end

     it "#index" do
       visit index_path
       check "s_search_updated"
       click_button I18n.t("views.button.search")
       expect(current_path).not_to eq sns_login_path
     end

   end

   context "with auth seatch deleted" do
     before { login_cms_user }

   subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
   before do
     subject.license_id = license.id
     subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
     subject.crawl_update = "none"
     subject.save!
   end

     it "#index" do
       visit index_path
       check "s_search_deleted"
       click_button I18n.t("views.button.search")
       expect(current_path).not_to eq sns_login_path
     end

   end

 end

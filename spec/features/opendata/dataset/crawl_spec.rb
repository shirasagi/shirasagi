require 'spec_helper'

describe "opendata_crawl", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:index_path) { opendata_crawls_path site, node }
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:url) { "http://#{unique_domain}/#{unique_id}/shift_jis.csv" }
  let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }

  before { WebMock.reset! }
  after { WebMock.reset! }

  context "with auth seatch updated and deleted" do
    before { login_cms_user }

    subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
    before do
      stub_request(:get, url).
        to_return(status: 200, body: ::File.binread(csv_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = "none"
      subject.save!
    end

    it "#index" do
      visit index_path
      check "s_search_updated"
      check "s_search_deleted"
      click_button I18n.t("ss.buttons.search")
      expect(current_path).not_to eq sns_login_path
    end
  end

  context "with auth seatch updated" do
    before { login_cms_user }

    subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
    before do
      stub_request(:get, url).
        to_return(status: 200, body: ::File.binread(csv_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = "none"
      subject.save!
    end

    it "#index" do
      visit index_path
      check "s_search_updated"
      click_button I18n.t("ss.buttons.search")
      expect(current_path).not_to eq sns_login_path
    end

  end

  context "with auth seatch deleted" do
    before { login_cms_user }

    subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
    before do
      stub_request(:get, url).
        to_return(status: 200, body: ::File.binread(csv_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = "none"
      subject.save!
    end

    it "#index" do
      visit index_path
      check "s_search_deleted"
      click_button I18n.t("ss.buttons.search")
      expect(current_path).not_to eq sns_login_path
    end

  end

end

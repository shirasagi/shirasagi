require 'spec_helper'

describe "cms_translate_access_logs", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_translate_access_logs_path site.id }
  let(:download_path) { download_cms_translate_access_logs_path site.id }

  let!(:item1) { create :translate_access_log }
  let!(:item2) do
    Timecop.travel(1.days.before) do
      create :translate_access_log
    end
  end
  let!(:item3) do
    Timecop.travel(60.days.before) do
      create :translate_access_log
    end
  end
  let!(:item4) do
    Timecop.travel(1.years.before) do
      create :translate_access_log
    end
  end

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.path
        expect(page).to have_link item2.path
        expect(page).to have_link item3.path
        expect(page).to have_link item4.path
      end
    end
  end

  context "download" do
    before { login_cms_user }

    it "#download" do
      visit download_path
      click_on I18n.t("ss.links.download")
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 1
        expect(csv_table[0]["#{Translate::AccessLog.t(:path)}"]).to eq item1.path
      end
    end

    it "#download" do
      visit download_path
      select I18n.t("ss.options.duration.1_day"), from: "item[save_term]"
      click_on I18n.t("ss.links.download")
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 1
        expect(csv_table[0]["#{Translate::AccessLog.t(:path)}"]).to eq item1.path
      end
    end

    it "#download" do
      visit download_path
      select I18n.t("ss.options.duration.1_month"), from: "item[save_term]"
      click_on I18n.t("ss.links.download")
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        expect(csv_table[0]["#{Translate::AccessLog.t(:path)}"]).to eq item2.path
        expect(csv_table[1]["#{Translate::AccessLog.t(:path)}"]).to eq item1.path
      end
    end

    it "#download" do
      visit download_path
      select I18n.t("ss.options.duration.1_year"), from: "item[save_term]"
      click_on I18n.t("ss.links.download")
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 3
        expect(csv_table[0]["#{Translate::AccessLog.t(:path)}"]).to eq item3.path
        expect(csv_table[1]["#{Translate::AccessLog.t(:path)}"]).to eq item2.path
        expect(csv_table[2]["#{Translate::AccessLog.t(:path)}"]).to eq item1.path
      end
    end
  end
end

require 'spec_helper'

describe Opendata::Dataset::ResourcePreviewReportsController, type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset, cur_site: site) }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }

  let(:now) { Time.zone.now.beginning_of_minute }
  let(:last_year) { now - 1.year - 1.month }
  let!(:report1) do
    create(:opendata_resource_preview_report, cur_site: site, dataset_id: rand(10..20), resource_id: rand(10..20))
  end
  let!(:report2) do
    create(
      :opendata_resource_preview_report, cur_site: site, deleted: now, dataset_id: rand(30..40), resource_id: rand(30..40)
    )
  end
  let!(:report3) do
    create(
      :opendata_resource_preview_report, cur_site: site, year_month: last_year.year * 100 + last_year.month,
      dataset_id: rand(30..40), resource_id: rand(30..40)
    )
  end

  before { login_cms_user }

  describe "#index" do
    it do
      visit opendata_dataset_report_previews_path(site: site, cid: node)
      expect(page).to have_css("tr[data-dataset-id='#{report1.dataset_id}']", text: report1.dataset_name)
      expect(page).to have_css("tr[data-resource-id='#{report1.resource_id}']", text: report1.resource_name)
      expect(page).to have_css("tr[data-dataset-id='#{report2.dataset_id}']", text: report2.dataset_name)
      expect(page).to have_css("tr[data-resource-id='#{report2.resource_id}']", text: report2.resource_name)
      expect(page).to have_no_css("tr[data-dataset-id='#{report3.dataset_id}']", text: report3.dataset_name)
      expect(page).to have_no_css("tr[data-resource-id='#{report3.resource_id}']", text: report3.resource_name)

      within "form.search" do
        fill_in "s[keyword]", with: report1.dataset_name
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css("tr[data-dataset-id='#{report1.dataset_id}']", text: report1.dataset_name)
      expect(page).to have_css("tr[data-resource-id='#{report1.resource_id}']", text: report1.resource_name)
      expect(page).to have_no_css("tr[data-dataset-id='#{report2.dataset_id}']", text: report2.dataset_name)
      expect(page).to have_no_css("tr[data-resource-id='#{report2.resource_id}']", text: report2.resource_name)
      expect(page).to have_no_css("tr[data-dataset-id='#{report3.dataset_id}']", text: report3.dataset_name)
      expect(page).to have_no_css("tr[data-resource-id='#{report3.resource_id}']", text: report3.resource_name)

      within "form.search" do
        select "#{last_year.year}#{I18n.t('datetime.prompts.year')}", from: "s[start_year]"
        select "#{last_year.month}#{I18n.t('datetime.prompts.month')}", from: "s[start_month]"
        select "#{last_year.year}#{I18n.t('datetime.prompts.year')}", from: "s[end_year]"
        select "#{last_year.month}#{I18n.t('datetime.prompts.month')}", from: "s[end_month]"
        fill_in "s[keyword]", with: ""
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css("tr[data-dataset-id='#{report1.dataset_id}']", text: report1.dataset_name)
      expect(page).to have_no_css("tr[data-resource-id='#{report1.resource_id}']", text: report1.resource_name)
      expect(page).to have_no_css("tr[data-dataset-id='#{report2.dataset_id}']", text: report2.dataset_name)
      expect(page).to have_no_css("tr[data-resource-id='#{report2.resource_id}']", text: report2.resource_name)
      expect(page).to have_css("tr[data-dataset-id='#{report3.dataset_id}']", text: report3.dataset_name)
      expect(page).to have_css("tr[data-resource-id='#{report3.resource_id}']", text: report3.resource_name)
    end
  end

  describe "#download" do
    it do
      visit opendata_dataset_report_previews_path(site: site, cid: node)
      click_on I18n.t("ss.links.download")

      expect(page.response_headers["Transfer-Encoding"]).to eq "chunked"
      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")

      table = ::CSV.parse(csv, headers: true)
      expect(table.headers[0]).to eq Opendata::Dataset.t("no")
      expect(table.headers[1]).to be_blank
      expect(table.headers[2]).to be_blank
      expect(table.headers[3]).to eq I18n.t("ss.url")
      expect(table.headers[4]).to eq Opendata::Dataset.t("area_ids")
      expect(table.headers[5]).to eq Opendata::Dataset.t("state")
      year_month = "#{now.year}#{I18n.t('datetime.prompts.year')}#{now.month}#{I18n.t('datetime.prompts.month')}"
      expect(table.headers[6]).to eq year_month
      expect(table.headers.length).to be > 30

      expect(table.length).to eq 4

      expect(table[0][Opendata::Dataset.t("no")]).to eq report1.dataset_id.to_s
      expect(table[0][1]).to eq "[#{report1.dataset_id}] #{report1.dataset_name}"
      expect(table[0][I18n.t("ss.url")]).to eq report1.dataset_url
      expect(table[0][Opendata::Dataset.t("area_ids")]).to eq report1.dataset_areas.join("\n")
      expect(table[0][Opendata::Dataset.t("state")]).to be_blank
      expect(table[1][Opendata::Dataset.t("no")]).to be_blank
      expect(table[1][2]).to eq "[#{report1.resource_id}] #{report1.resource_name}"
      expect(table[1][I18n.t("ss.url")]).to be_blank
      expect(table[1][Opendata::Dataset.t("area_ids")]).to be_blank
      expect(table[1][Opendata::Dataset.t("state")]).to be_blank

      expect(table[2][Opendata::Dataset.t("no")]).to eq report2.dataset_id.to_s
      expect(table[2][1]).to eq "[#{report2.dataset_id}] #{report2.dataset_name}"
      expect(table[2][I18n.t("ss.url")]).to eq report2.dataset_url
      expect(table[2][Opendata::Dataset.t("area_ids")]).to eq report2.dataset_areas.join("\n")
      expect(table[2][Opendata::Dataset.t("state")]).to be_blank
      expect(table[3][Opendata::Dataset.t("no")]).to be_blank
      expect(table[3][2]).to eq "[#{report2.resource_id}] #{report2.resource_name}"
      expect(table[3][I18n.t("ss.url")]).to be_blank
      expect(table[3][Opendata::Dataset.t("area_ids")]).to be_blank
      expect(table[3][Opendata::Dataset.t("state")]).to eq "削除: #{I18n.l(report2.deleted.to_date)}"
    end
  end
end

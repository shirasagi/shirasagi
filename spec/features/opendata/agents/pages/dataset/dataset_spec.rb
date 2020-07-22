require 'spec_helper'

describe "opendata_agents_pages_dataset", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:area) { create :opendata_node_area, layout: layout, filename: "opendata_area_1" }
  let!(:node_dataset) { create :opendata_node_dataset, layout: layout }
  let!(:node_area) { create :opendata_node_area, layout: layout }
  let!(:node_search_dataset) { create :opendata_node_search_dataset, layout: layout, filename: "dataset/search" }
  let!(:page_dataset) { create(:opendata_dataset, layout: layout, cur_node: node_dataset, area_ids: [ node_area.id ]) }
  let!(:node_dataset_category) { create :opendata_node_dataset_category, layout: layout }
  let(:csv_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:license) { create(:opendata_license, cur_site: site) }

  context "public" do
    before do
      # a resource
      @rs1 = page_dataset.resources.new
      @rs1.license = license
      @rs1.name = "shift_jis.csv"
      @rs1.text = "resource1"
      Fs::UploadedFile.create_from_file(csv_path, basename: "spec") do |file|
        file.original_filename = "shift_jis.csv"

        @rs1.in_file = file
        @rs1.save!
      end

      # a resource referencing other site's resource
      @rs2 = page_dataset.resources.new
      @rs2.license = license
      @rs2.name = "shift_jis.csv"
      @rs2.source_url = unique_url
      @rs2.text = "resource2"
      file = tmp_ss_file(contents: csv_path, site: site, model: "opendata/resource", owner_item: page_dataset)
      @rs2.file_id = file.id
      @rs2.filename = "shift_jis.csv"
      @rs2.format = "CSV"
      @rs2.save!

      # a url resource
      @urs1 = page_dataset.url_resources.new
      @urs1.license = license
      @urs1.name = "shift_jis.csv"
      @urs1.original_url = unique_url
      @urs1.crawl_update = "none"
      @urs1.text = "resource3"
      Fs::UploadedFile.create_from_file(csv_path, basename: "spec") do |file|
        file.original_filename = "shift_jis.csv"

        @urs1.in_file = file
        @urs1.format = "CSV"
        @urs1.save!
      end

      page_dataset.reload
      expect(page_dataset.resources.count).to eq 2
      expect(page_dataset.url_resources.count).to eq 1

      Fs.rm_rf page_dataset.path
    end

    it "#index" do
      visit page_dataset.full_url

      within "div#dataset-tabs-#{node_dataset.id}" do
        within "article#cms-tab-#{node_dataset.id}-0-view" do
          within ".resource[data-uuid='#{@rs1.uuid}']" do
            expect(page).to have_css(".info .name", text: "#{@rs1.name} (#{@rs1.format} #{@rs1.size.to_s(:human_size)})")
            expect(page).to have_css(".info .download-count", text: "0#{I18n.t("opendata.labels.time")}")
            expect(page).to have_css(".icons .license img[src=\"#{@rs1.license.file.url}\"]")
            expect(page).to have_css(".icons .content-wrap a.content", text: I18n.t("opendata.labels.preview"))
            # シラサギ・ハーベストは data-url が指す URL からリソースをダウンロードする。
            #
            # そして、シラサギ・ハーベスト以外のすべての利用時はダウンロード履歴を残すが、
            # シラサギ・ハーベスの場合はダウンロード履歴を残したくない。
            #
            # そこで data-url には "/fs/" で始まる URL が設定されている必要がある。
            label = I18n.t("opendata.labels.downloaded")
            href = "#{node_dataset.url}#{::File.basename(page_dataset.filename, ".*")}/resource/#{@rs1.id}/#{@rs1.filename}"
            data_url = @rs1.file.full_url
            expect(page).to have_css(".icons .download-wrap a.download[href='#{href}']", text: label)
            expect(page).to have_css(".icons .download-wrap a.download[data-url='#{data_url}']", text: label)
            expect(page).to have_css(".icons .clipboard-wrap a.ss-clipboard-copy", text: I18n.t("opendata.links.copy_url"))
            expect(page).to have_css(".text", text: @rs1.text)
          end

          within ".resource[data-uuid='#{@rs2.uuid}']" do
            name = "#{@rs2.name} (#{@rs2.format} #{I18n.t("opendata.labels.external_link")})"
            expect(page).to have_css(".info .name", text: name)
            expect(page).to have_css(".info .download-count", text: "0#{I18n.t("opendata.labels.time")}")
            expect(page).to have_css(".icons .license img[src=\"#{@rs2.license.file.url}\"]")
            expect(page).to have_no_css(".icons .content-wrap")
            # シラサギ・ハーベストは data-url が指す URL からリソースをダウンロードする。
            # シラサギ・ハーベストが自リソースなのか外部リソースなのかを正しく判断できるように
            # data-url には外部 URL が設定されている必要がある。
            label = I18n.t("opendata.labels.downloaded")
            href = "#{node_dataset.url}#{::File.basename(page_dataset.filename, ".*")}/resource/#{@rs2.id}/source-url"
            data_url = @rs2.source_url
            expect(page).to have_css(".icons .download-wrap a.download[href='#{href}']", text: label)
            expect(page).to have_css(".icons .download-wrap a.download[data-url='#{data_url}']", text: label)
            expect(page).to have_css(".icons .clipboard-wrap a.ss-clipboard-copy", text: I18n.t("opendata.links.copy_url"))
            expect(page).to have_css(".text", text: @rs2.text)
          end

          within ".url-resource[data-uuid='#{@urs1.uuid}']" do
            name = "#{@urs1.name} (#{@urs1.format} #{@urs1.size.to_s(:human_size)})"
            expect(page).to have_css(".info .name", text: name)
            expect(page).to have_no_css(".info .download-count")
            expect(page).to have_css(".icons .license img[src=\"#{@urs1.license.file.url}\"]")
            expect(page).to have_css(".icons .content-wrap a.content", text: I18n.t("opendata.labels.preview"))
            # シラサギ・ハーベストは data-url が指す URL からリソースをダウンロードする。
            # シラサギ・ハーベストが自リソースなのか外部リソースなのかを正しく判断できるように
            # data-url には外部 URL が設定されている必要がある。
            label = I18n.t("opendata.labels.downloaded")
            href = "#{node_dataset.url}#{::File.basename(page_dataset.filename, ".*")}/url_resource/#{@urs1.id}/#{@urs1.filename}"
            data_url = @urs1.original_url
            expect(page).to have_css(".icons .download-wrap a.download[href='#{href}']", text: label)
            expect(page).to have_css(".icons .download-wrap a.download[data-url='#{data_url}']", text: label)
            expect(page).to have_css(".icons .clipboard-wrap a.ss-clipboard-copy", text: I18n.t("opendata.links.copy_url"))
            expect(page).to have_css(".text", text: @urs1.text)
          end
        end
      end

      # Download resource1
      visit page_dataset.full_url

      now = Time.zone.now.beginning_of_minute
      Timecop.freeze(now) do
        within ".resource[data-uuid='#{@rs1.uuid}']" do
          click_on I18n.t("opendata.labels.downloaded")
        end
      end

      wait_for_download
      expect(::File.binread(downloads.first)).to eq ::File.binread(csv_path)

      expect(Opendata::ResourceDownloadHistory.count).to eq 1
      Opendata::ResourceDownloadHistory.first.tap do |history|
        expect(history.dataset_id).to eq page_dataset.id
        expect(history.dataset_name).to eq page_dataset.name
        expect(history.dataset_areas).to eq [ node_area.name ]
        expect(history.dataset_categories).to be_blank
        expect(history.dataset_estat_categories).to be_blank
        expect(history.resource_id).to eq @rs1.id
        expect(history.resource_name).to eq @rs1.name
        expect(history.resource_filename).to eq @rs1.filename
        expect(history.resource_format).to eq @rs1.format
        expect(history.resource_source_url).to eq @rs1.source_url
        expect(history.full_url).to eq page_dataset.full_url
        expect(history.remote_addr).to be_present
        expect(history.user_agent).to be_present
        expect(history.downloaded).to eq now
        expect(history.downloaded_by).to eq "single"
      end

      # Download resource2
      visit page_dataset.full_url
      Timecop.freeze(now) do
        within ".resource[data-uuid='#{@rs2.uuid}']" do
          click_on I18n.t("opendata.labels.downloaded")
        end
      end
      # a new history is created
      expect(Opendata::ResourceDownloadHistory.count).to eq 2
      expect(Opendata::ResourceDownloadHistory.where(resource_id: @rs2.id).count).to eq 1

      # Download url resource1
      visit page_dataset.full_url
      Timecop.freeze(now) do
        within ".url-resource[data-uuid='#{@urs1.uuid}']" do
          click_on I18n.t("opendata.labels.downloaded")
        end
      end
      # no histories are created for url resources
      expect(Opendata::ResourceDownloadHistory.count).to eq 2

      # Download count is not increased because page renders with cached count
      visit page_dataset.full_url
      within ".resource[data-uuid='#{@rs1.uuid}']" do
        expect(page).to have_css(".info .download-count", text: "0#{I18n.t("opendata.labels.time")}")
      end
      within ".resource[data-uuid='#{@rs2.uuid}']" do
        expect(page).to have_css(".info .download-count", text: "0#{I18n.t("opendata.labels.time")}")
      end

      Timecop.freeze(now + Opendata::Resource::DOWNLOAD_CACHE_LIFETIME + 1.minute) do
        # time passes and then download count cache is expired. so, download count is increased
        visit page_dataset.full_url
        within ".resource[data-uuid='#{@rs1.uuid}']" do
          expect(page).to have_css(".info .download-count", text: "1#{I18n.t("opendata.labels.time")}")
        end
        within ".resource[data-uuid='#{@rs2.uuid}']" do
          expect(page).to have_css(".info .download-count", text: "1#{I18n.t("opendata.labels.time")}")
        end
      end
    end
  end
end

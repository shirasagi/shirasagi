require 'spec_helper'

describe "opendata_url_resource", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let(:csv_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv").to_s }
  let(:csv_path2) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis-2.csv").to_s }
  let(:name) { "name-#{unique_id}" }
  let(:filename) { "file-#{unique_id}.csv" }
  let(:original_url) { "http://#{unique_domain}/#{filename}" }
  let(:text) { "text-#{unique_id}" }
  let(:now) { Time.zone.now.beginning_of_hour }

  def download_url_resource(path = nil)
    clear_downloads

    visit opendata_dataset_path(site: site, cid: node, id: dataset)
    within "#addon-opendata-agents-addons-url_resource" do
      click_button I18n.t("opendata.manage_url_resources")
    end
    click_on name
    click_on ::File.basename(filename)

    wait_for_download

    path ||= csv_path
    expect(::File.binread(downloads.first)).to eq ::File.binread(path)
  end

  def visit_url_resource
    visit opendata_dataset_path(site: site, cid: node, id: dataset)
    within "#addon-opendata-agents-addons-url_resource" do
      click_button I18n.t("opendata.manage_url_resources")
    end
  end

  def stub_url_resource(path, last_modified)
    WebMock.reset!

    headers = {
      "Content-Type" => "text/csv",
      "Content-Disposition" => "attachment; filename=\"#{filename}\"",
      "Last-Modified" => last_modified.utc.httpdate
    }
    stub_request(:get, original_url).to_return(status: 200, body: ::File.binread(path), headers: headers)
  end

  context "basic crud" do
    before do
      stub_url_resource(csv_path, now)
      login_cms_user
    end

    after { WebMock.reset! }

    it do
      expect(dataset.url_resources.count).to eq 0
      expect(SS::File.where(filename: filename).count).to eq 0

      # validation
      visit_url_resource
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[original_url]", with: original_url
        select  license.name, from: "item_license_id"
        select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#errorExplanation', text: I18n.t("errors.messages.blank"))

      dataset.reload
      expect(dataset.url_resources.count).to eq 0
      expect(SS::File.where(filename: filename).count).to eq 0

      # create
      visit_url_resource
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[original_url]", with: original_url
        fill_in "item[name]", with: name
        select  license.name, from: "item_license_id"
        select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      dataset.reload
      expect(dataset.url_resources.count).to eq 1
      expect(SS::File.where(filename: filename).count).to eq 1
      SS::File.where(filename: filename).first.tap do |file|
        expect(file.name).to eq filename
        expect(file.filename).to eq filename
        expect(file.content_type).to eq "text/csv"
        expect(file.size).to eq ::File.size(csv_path)
        expect(file.read).to eq ::File.binread(csv_path)
        expect(file.owner_item_id).to eq dataset.id
      end

      download_url_resource

      # update
      visit_url_resource
      click_on name
      click_on I18n.t("ss.links.edit")

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
      expect(SS::File.where(filename: filename).count).to eq 1
      SS::File.where(filename: filename).first.tap do |file|
        expect(file.name).to eq filename
        expect(file.filename).to eq filename
        expect(file.content_type).to eq "text/csv"
        expect(file.size).to eq ::File.size(csv_path)
        expect(file.read).to eq ::File.binread(csv_path)
        expect(file.owner_item_id).to eq dataset.id
      end

      download_url_resource

      # Delete
      visit_url_resource
      click_on name
      click_on I18n.t("ss.links.delete")

      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      dataset.reload
      expect(dataset.url_resources.count).to eq 0
      expect(SS::File.where(filename: filename).count).to eq 0
    end
  end

  context "do crawl" do
    after { WebMock.reset! }

    it do
      Timecop.travel(now) do
        login_cms_user

        stub_url_resource(csv_path, now)

        expect(dataset.url_resources.count).to eq 0
        expect(SS::File.where(filename: filename).count).to eq 0

        # create
        visit_url_resource
        click_on I18n.t("ss.links.new")

        within "form#item-form" do
          fill_in "item[original_url]", with: original_url
          fill_in "item[name]", with: name
          select  license.name, from: "item_license_id"
          select  I18n.t("opendata.crawl_update.auto"), from: "item_crawl_update"
          click_button I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        dataset.reload
        expect(dataset.url_resources.count).to eq 1
        expect(SS::File.where(filename: filename).count).to eq 1
        SS::File.where(filename: filename).first.tap do |file|
          expect(file.name).to eq filename
          expect(file.filename).to eq filename
          expect(file.content_type).to eq "text/csv"
          expect(file.size).to eq ::File.size(csv_path)
          expect(file.read).to eq ::File.binread(csv_path)
          expect(file.owner_item_id).to eq dataset.id
        end

        download_url_resource

        # do crawl
        stub_url_resource(csv_path2, now)
        dataset.url_resources.each(&:do_crawl)

        dataset.reload
        expect(dataset.url_resources.count).to eq 1
        expect(SS::File.where(filename: filename).count).to eq 1
        SS::File.where(filename: filename).first.tap do |file|
          expect(file.name).to eq filename
          expect(file.filename).to eq filename
          expect(file.content_type).to eq "text/csv"
          expect(file.size).to eq ::File.size(csv_path)
          expect(file.read).to eq ::File.binread(csv_path)
          expect(file.owner_item_id).to eq dataset.id
        end

        download_url_resource
      end

      Timecop.travel(now.tomorrow) do
        login_cms_user

        stub_url_resource(csv_path2, now.tomorrow)
        dataset.url_resources.each(&:do_crawl)

        dataset.reload
        expect(dataset.url_resources.count).to eq 1
        expect(SS::File.where(filename: filename).count).to eq 1
        SS::File.where(filename: filename).first.tap do |file|
          expect(file.name).to eq filename
          expect(file.filename).to eq filename
          expect(file.content_type).to eq "text/csv"
          expect(file.size).to eq ::File.size(csv_path2)
          expect(file.read).to eq ::File.binread(csv_path2)
          expect(file.owner_item_id).to eq dataset.id
        end

        download_url_resource(csv_path2)
      end
    end
  end
end

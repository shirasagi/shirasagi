require 'spec_helper'

describe "gws_histories", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:item) { create :gws_schedule_plan, cur_site: site }
  let(:now) { Time.zone.now }

  before { login_gws_user }

  context "basic crud" do
    it do
      visit gws_histories_path(site: site)
      expect(page).to have_css(".list-item", text: item.name)

      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      within "form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.headers).to include(Gws::History.t(:id), Gws::History.t(:session_id), Gws::History.t(:severity))
          expect(csv_table.length).to be > 1
          expect(csv_table[0][Gws::History.t(:id)]).to be_present
          expect(csv_table[0][Gws::History.t(:session_id)]).to be_present
          expect(csv_table[0][Gws::History.t(:request_id)]).to be_present
          expect(csv_table[0][Gws::History.t(:severity)]).to be_present
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/histories"
        expect(history.path).to eq download_gws_daily_histories_path(site: site, ymd: "-")
        expect(history.action).to eq "download"
      end
    end
  end
end

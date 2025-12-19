require 'spec_helper'

describe "gws_histories", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }

    it do
      visit new_gws_schedule_plan_path(site: site)
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item = Gws::Schedule::Plan.first
      expect(item.site_id).to eq site.id
      expect(item.name).to eq name

      visit gws_histories_path(site: site)
      expect(page).to have_css(".list-item", text: 'gws/schedule/plans#create')

      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.headers).to include(Gws::History.t(:id), Gws::History.t(:session_id), Gws::History.t(:severity))
          expect(csv_table.length).to be > 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Gws::History.t(:id)]).to be_present
            expect(csv_row[Gws::History.t(:session_id)]).to be_present
            expect(csv_row[Gws::History.t(:request_id)]).to be_present
            expect(csv_row[Gws::History.t(:severity)]).to be_present
          end
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).to_a.tap do |histories|
        histories[0].tap do |history|
          expect(history.severity).to eq "info"
          expect(history.controller).to eq 'gws/schedule/plans'
          expect(history.path).to eq gws_schedule_plans_path(site: site) + '/events.json'
          expect(history.action).to eq "events"
        end
      end
    end
  end
end

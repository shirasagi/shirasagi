require 'spec_helper'

describe "gws_facility_usage", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "with usual case" do
    let!(:cate1) { create :gws_facility_category, cur_site: site, order: 1 }
    let!(:cate2) { create :gws_facility_category, cur_site: site, order: 2 }
    let!(:facility1) { create :gws_facility_item, cur_site: site, order: 1, category: cate1 }
    let!(:facility2) { create :gws_facility_item, cur_site: site, order: 2, category: cate2 }

    let(:now) { Time.zone.now.beginning_of_minute }
    let(:prev_month) { now.beginning_of_month - 1.month }
    # 2 plans at same day
    let!(:facility1_plan1) do
      start_at = prev_month.change(day: 16, hour: 10)
      end_at = start_at + 2.hours
      create(:gws_schedule_plan, start_at: start_at, end_at: end_at, facility_ids: [ facility1.id ])
    end
    let!(:facility1_plan2) do
      start_at = prev_month.change(day: 16, hour: 15)
      end_at = start_at + 3.hours
      create(:gws_schedule_plan, start_at: start_at, end_at: end_at, facility_ids: [ facility1.id ])
    end
    # plan over day-end
    let!(:facility2_plan1) do
      start_on = prev_month.change(day: 9)
      end_on = start_on + 2.days
      create(
        :gws_schedule_plan, allday: "allday", start_on: start_on.to_date, end_on: end_on.to_date, facility_ids: [ facility2.id ]
      )
    end

    it do
      visit gws_facility_usage_main_path(site: site)
      within ".gws-facility-usage-monthly .index" do
        expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
        expect(page).to have_css("#facility-#{facility1.id}-hours .day-16", text: "5.0")
        expect(page).to have_css("#facility-#{facility1.id}-times .day-16", text: "2")
        expect(page).to have_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
        expect(page).to have_css("#facility-#{facility2.id}-hours .day-9", text: "24.0")
        expect(page).to have_css("#facility-#{facility2.id}-times .day-9", text: "1")
        expect(page).to have_css("#facility-#{facility2.id}-hours .day-10", text: "24.0")
        expect(page).to have_css("#facility-#{facility2.id}-times .day-10", text: "1")
        expect(page).to have_css("#facility-#{facility2.id}-hours .day-11", text: "24.0")
        expect(page).to have_css("#facility-#{facility2.id}-times .day-11", text: "1")
      end

      # change category, year and month
      within ".gws-facility-usage-monthly form.search" do
        select cate1.name, from: "s[category]"
        select "#{now.year - 1}#{I18n.t('datetime.prompts.year')}", from: "s[year]"
        select "#{now.month}#{I18n.t('datetime.prompts.month')}", from: "s[month]"
        click_on I18n.t("ss.buttons.search")
      end

      within ".gws-facility-usage-monthly .index" do
        expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
        expect(page).to have_no_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
      end

      # revert changes
      within ".gws-facility-usage-monthly form.search" do
        click_on I18n.t("ss.buttons.reset")
      end

      within ".gws-facility-usage-monthly .index" do
        expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
        expect(page).to have_css("#facility-#{facility1.id}-hours .day-16", text: "5.0")
        expect(page).to have_css("#facility-#{facility1.id}-times .day-16", text: "2")
        expect(page).to have_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
        expect(page).to have_css("#facility-#{facility2.id}-hours .day-9", text: "24.0")
        expect(page).to have_css("#facility-#{facility2.id}-times .day-9", text: "1")
      end

      # download
      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
      expect(csv.length).to eq 4
      expect(csv[0][Gws::Facility::Item.t(:name)]).to eq facility1.name
      expect(csv[0][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.hours')
      expect(csv[0]["16#{I18n.t('datetime.prompts.day')}"]).to eq "5.0"
      expect(csv[1][Gws::Facility::Item.t(:name)]).to eq facility1.name
      expect(csv[1][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.times')
      expect(csv[1]["16#{I18n.t('datetime.prompts.day')}"]).to eq "2"
      expect(csv[2][Gws::Facility::Item.t(:name)]).to eq facility2.name
      expect(csv[2][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.hours')
      expect(csv[2]["9#{I18n.t('datetime.prompts.day')}"]).to eq "24.0"
      expect(csv[2]["10#{I18n.t('datetime.prompts.day')}"]).to eq "24.0"
      expect(csv[2]["11#{I18n.t('datetime.prompts.day')}"]).to eq "24.0"
      expect(csv[3][Gws::Facility::Item.t(:name)]).to eq facility2.name
      expect(csv[3][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.times')
      expect(csv[3]["9#{I18n.t('datetime.prompts.day')}"]).to eq "1"
      expect(csv[3]["10#{I18n.t('datetime.prompts.day')}"]).to eq "1"
      expect(csv[3]["11#{I18n.t('datetime.prompts.day')}"]).to eq "1"
    end
  end

  describe "year selection works with site's schedule_max_years" do
    # 設備仕様率の選択「年」は、組織情報のスケジュールの入力可能期間と連動する
    it do
      site.update(schedule_max_years: 10)

      visit gws_facility_usage_main_path(site: site)
      within "form.search" do
        expect(page).to have_css("select[name='s[year]'] option[value='#{Time.zone.now.year + 9}']")
      end
    end
  end
end

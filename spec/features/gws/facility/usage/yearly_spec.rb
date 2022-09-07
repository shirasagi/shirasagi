require 'spec_helper'

describe "gws_facility_usage", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:cate1) { create :gws_facility_category, cur_site: site, order: 1 }
  let!(:cate2) { create :gws_facility_category, cur_site: site, order: 2 }
  let!(:facility1) { create :gws_facility_item, cur_site: site, order: 1, category: cate1 }
  let!(:facility2) { create :gws_facility_item, cur_site: site, order: 2, category: cate2 }

  let(:now) { Time.zone.now.change(month: 9, day: 17).beginning_of_minute }
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
  # plan over month-end
  let!(:facility2_plan1) do
    start_on = prev_month.end_of_month.beginning_of_day
    end_on = start_on + 2.days
    create(
      :gws_schedule_plan, allday: "allday", start_on: start_on.to_date, end_on: end_on.to_date, facility_ids: [ facility2.id ]
    )
  end

  around do |example|
    travel_to(now) do
      example.run
    end
  end

  before { login_gws_user }

  it do
    visit gws_facility_usage_main_path(site: site)
    within ".gws-facility-usage-monthly form.search" do
      select I18n.t("ads.yearly"), from: "s[month]"
      click_on I18n.t("ss.buttons.search")
    end

    within ".gws-facility-usage-yearly .index" do
      expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
      expect(page).to have_css("#facility-#{facility1.id}-hours .month-#{prev_month.month}", text: "5.0")
      expect(page).to have_css("#facility-#{facility1.id}-times .month-#{prev_month.month}", text: "2")
      expect(page).to have_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
      expect(page).to have_css("#facility-#{facility2.id}-hours .month-#{prev_month.month}", text: "24.0")
      expect(page).to have_css("#facility-#{facility2.id}-times .month-#{prev_month.month}", text: "1")
      expect(page).to have_css("#facility-#{facility2.id}-hours .month-#{now.month}", text: "48.0")
      expect(page).to have_css("#facility-#{facility2.id}-times .month-#{now.month}", text: "1")
    end

    # change category
    within ".gws-facility-usage-yearly form.search" do
      select cate1.name, from: "s[category]"
      click_on I18n.t("ss.buttons.search")
    end
    within ".gws-facility-usage-yearly .index" do
      expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
      expect(page).to have_no_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
    end

    # change year
    within ".gws-facility-usage-yearly form.search" do
      select I18n.t('gws/facility.facility'), from: "s[category]"
      select "#{now.year - 1}#{I18n.t('datetime.prompts.year')}", from: "s[year]"
      click_on I18n.t("ss.buttons.search")
    end
    within ".gws-facility-usage-yearly .index" do
      expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
      expect(page).to have_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
    end

    # revert changes
    within ".gws-facility-usage-yearly form.search" do
      click_on I18n.t("ss.buttons.reset")
    end
    within ".gws-facility-usage-monthly form.search" do
      select I18n.t("ads.yearly"), from: "s[month]"
      click_on I18n.t("ss.buttons.search")
    end

    within ".gws-facility-usage-yearly .index" do
      expect(page).to have_css("#facility-#{facility1.id}-hours .name", text: facility1.name)
      expect(page).to have_css("#facility-#{facility1.id}-hours .month-#{prev_month.month}", text: "5.0")
      expect(page).to have_css("#facility-#{facility1.id}-times .month-#{prev_month.month}", text: "2")
      expect(page).to have_css("#facility-#{facility2.id}-hours .name", text: facility2.name)
      expect(page).to have_css("#facility-#{facility2.id}-hours .month-#{prev_month.month}", text: "24.0")
      expect(page).to have_css("#facility-#{facility2.id}-times .month-#{prev_month.month}", text: "1")
      expect(page).to have_css("#facility-#{facility2.id}-hours .month-#{now.month}", text: "48.0")
      expect(page).to have_css("#facility-#{facility2.id}-times .month-#{now.month}", text: "1")
    end

    # download
    click_on I18n.t("ss.links.download")
    wait_for_download

    I18n.with_locale(I18n.default_locale) do
      csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
      expect(csv.length).to eq 4
      expect(csv[0][Gws::Facility::Item.t(:name)]).to eq facility1.name
      expect(csv[0][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.hours')
      expect(csv[0]["#{prev_month.month}#{I18n.t('datetime.prompts.month')}"]).to eq "5.0"
      expect(csv[1][Gws::Facility::Item.t(:name)]).to eq facility1.name
      expect(csv[1][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.times')
      expect(csv[1]["#{prev_month.month}#{I18n.t('datetime.prompts.month')}"]).to eq "2"
      expect(csv[2][Gws::Facility::Item.t(:name)]).to eq facility2.name
      expect(csv[2][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.hours')
      expect(csv[2]["#{prev_month.month}#{I18n.t('datetime.prompts.month')}"]).to eq "24.0"
      expect(csv[2]["#{now.month}#{I18n.t('datetime.prompts.month')}"]).to eq "48.0"
      expect(csv[3][Gws::Facility::Item.t(:name)]).to eq facility2.name
      expect(csv[3][I18n.t('gws/facility.usage.type')]).to eq I18n.t('gws/facility.usage.times')
      expect(csv[3]["#{prev_month.month}#{I18n.t('datetime.prompts.month')}"]).to eq "1"
      expect(csv[3]["#{now.month}#{I18n.t('datetime.prompts.month')}"]).to eq "1"
    end
  end
end

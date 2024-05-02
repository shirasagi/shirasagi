require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:new_path) { new_gws_schedule_plan_path site }

  before { login_gws_user }

  context "when no repeat entered" do
    let(:repeat_start) { Time.zone.today }
    let(:repeat_end) { repeat_start.advance(months: 1) }
    let(:plan_dates) { (repeat_start..repeat_end).to_a }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates
    end
  end

  context "when repeat start entered" do
    let(:repeat_start) { Time.zone.today }
    let(:repeat_end) { repeat_start }
    let(:plan_dates) { [repeat_start] }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        fill_in_date "item[repeat_start]", with: repeat_start
        expect(page).to have_field("item[repeat_end]", with: I18n.l(repeat_start, format: :picker))
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates
    end
  end

  context "when repeat end entered" do
    let(:repeat_end) { Time.zone.today }
    let(:plan_dates) { [repeat_end] }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        fill_in_date "item[repeat_end]", with: repeat_end
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates
    end
  end

  context "when repeat start and end entered" do
    let(:repeat_start) { Time.zone.today }
    let(:repeat_end) { repeat_start.advance(days: 7) }
    let(:plan_dates) { (repeat_start..repeat_end).to_a }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        fill_in_date "item[repeat_start]", with: repeat_start
        fill_in_date "item[repeat_end]", with: repeat_end
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates
    end
  end
end

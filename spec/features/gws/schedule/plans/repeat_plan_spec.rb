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
      wait_for_notice I18n.t('ss.notice.saved')

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
      wait_for_notice I18n.t('ss.notice.saved')

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
      wait_for_notice I18n.t('ss.notice.saved')

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
      wait_for_notice I18n.t('ss.notice.saved')

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates
    end
  end

  context "when repeat plan edit" do
    let(:repeat_start) { Time.zone.today }
    let(:repeat_end) { repeat_start.advance(months: 1) }
    let(:plan_dates) { (repeat_start..repeat_end).to_a }

    it do
      visit new_path
      enable_confirm_unloading
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        select I18n.t("gws/schedule.options.repeat_type.daily"), from: "item[repeat_type]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      plans = Gws::Schedule::Plan.site(site).to_a
      expect(plans.count).to eq plan_dates.count

      dates = plans.map { |plan| plan.start_at.to_date }
      expect(dates).to eq plan_dates

      dates = plans.map { |plan| plan.end_at.to_date }
      expect(dates).to eq plan_dates

      target_plan = plans.sample
      visit edit_gws_schedule_plan_path(site: site, id: target_plan)
      enable_confirm_unloading
      within "form#item-form" do
        fill_in "item[name]", with: "name2"
        wait_for_cbox_opened { click_on I18n.t('ss.buttons.save') }
      end
      within_cbox do
        click_on I18n.t('gws/schedule.buttons.delete_one')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Gws::Schedule::Plan.find(target_plan.id).tap do |modified_plan|
        expect(modified_plan.name).to eq "name2"
      end
      plans.reject { |plan| plan == target_plan }.each do |plan|
        Gws::Schedule::Plan.find(plan.id).tap do |not_modified_plan|
          expect(not_modified_plan.name).to eq "name"
        end
      end
    end
  end
end

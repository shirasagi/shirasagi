require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "repeated schedule", js: true do
    let(:site) { gws_site }
    let(:index_path) { gws_schedule_plans_path site }
    let(:name) { unique_id }

    before { login_gws_user }

    context "every day" do
      let(:repeat_start_text) { "2016/04/15" }
      let(:repeat_start) { Date.parse(repeat_start_text) }
      let(:repeat_end_text) { "2017/04/15" }
      let(:repeat_end) { Date.parse(repeat_end_text) }
      let(:start_at_text) { "#{repeat_start_text} 19:15" }
      let(:start_at) { Time.zone.parse(start_at_text) }
      let(:end_at_text) { "#{repeat_start_text} 19:30" }
      let(:end_at) { Time.zone.parse(end_at_text) }
      let(:repeat_type) { "daily" }
      let(:repeat_type_label) { I18n.t("gws/schedule.options.repeat_type.#{repeat_type}") }
      let(:text) { unique_id }
      let(:interval) { 3 }

      it do
        visit index_path
        click_on I18n.t("gws/schedule.links.add_plan")

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at
          select repeat_type_label, from: "item[repeat_type]"
          select interval.to_s, from: "item[interval]"
          fill_in_date "item[repeat_start]", with: repeat_start
          fill_in_date "item[repeat_end]", with: repeat_end
          fill_in "item[text]", with: text

          click_on I18n.t('ss.buttons.save')
        end

        wait_for_js_ready
        expect(page).to have_css("aside#notice div", text: I18n.t('ss.notice.saved'))

        # gws_schedule_repeat_plans
        expect(Gws::Schedule::RepeatPlan.count).to eq 1
        Gws::Schedule::RepeatPlan.first.tap do |item|
          expect(item.repeat_type).to eq repeat_type
          expect(item.interval).to eq interval
          expect(item.repeat_start).to eq repeat_start
          expect(item.repeat_end).to eq repeat_end
          expect(item.repeat_base).to eq 'date'
          expect(item.wdays).to eq []
        end

        # gws_schedule_plans
        expect(Gws::Schedule::Plan.count).to eq 122
        Gws::Schedule::Plan.first.tap do |item|
          expect(item.state).to eq 'public'
          expect(item.name).to eq name
          expect(item.start_on).to be_nil
          expect(item.end_on).to be_nil
          expect(item.start_at).to eq start_at
          expect(item.end_at).to eq end_at
          expect(item.allday).to be_nil
          expect(item.repeat_plan_id).not_to be_nil
          expect(item.text).to eq text
        end
      end
    end

    context "set every month plan on 5th monday" do
      let(:repeat_start_text) { "2016/05/30" }
      let(:repeat_start) { Date.parse(repeat_start_text) }
      let(:repeat_end_text) { "2017/05/29" }
      let(:repeat_end) { Date.parse(repeat_end_text) }
      let(:start_at_text) { "#{repeat_start_text} 13:00" }
      let(:start_at) { Time.zone.parse(start_at_text) }
      let(:end_at_text) { "#{repeat_start_text} 14:00" }
      let(:end_at) { Time.zone.parse(end_at_text) }
      let(:repeat_type) { "monthly" }
      let(:repeat_type_label) { I18n.t("gws/schedule.options.repeat_type.#{repeat_type}") }
      let(:repeat_base) { "wday" }
      let(:interval) { 1 }

      it do
        visit index_path
        click_on I18n.t("gws/schedule.links.add_plan")

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[start_at]", with: start_at
          fill_in_datetime "item[end_at]", with: end_at
          select repeat_type_label, from: "item[repeat_type]"
          select interval.to_s, from: "item[interval]"
          choose "item_repeat_base_#{repeat_base}"
          fill_in_date "item[repeat_start]", with: repeat_start
          fill_in_date "item[repeat_end]", with: repeat_end

          click_on I18n.t('ss.buttons.save')
        end

        wait_for_js_ready
        expect(page).to have_css("aside#notice div", text: I18n.t('ss.notice.saved'))

        # gws_schedule_repeat_plans
        expect(Gws::Schedule::RepeatPlan.count).to eq 1
        Gws::Schedule::RepeatPlan.first.tap do |item|
          expect(item.repeat_type).to eq repeat_type
          expect(item.interval).to eq interval
          expect(item.repeat_start).to eq repeat_start
          expect(item.repeat_end).to eq repeat_end
          expect(item.repeat_base).to eq 'wday'
          expect(item.wdays).to eq []
        end

        # gws_schedule_plans
        expect(Gws::Schedule::Plan.count).to eq 13
        Gws::Schedule::Plan.first.tap do |item|
          expect(item.state).to eq 'public'
          expect(item.name).to eq name
          expect(item.start_on).to be_nil
          expect(item.end_on).to be_nil
          expect(item.start_at).to eq start_at
          expect(item.end_at).to eq end_at
          expect(item.allday).to be_nil
          expect(item.repeat_plan_id).not_to be_nil
          expect(item.text).to be_nil
        end
      end
    end
  end
end

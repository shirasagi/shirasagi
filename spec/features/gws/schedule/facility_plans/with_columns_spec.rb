require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:facility) { create :gws_facility_item }
  let!(:column1) { create :gws_column_text_field, cur_form: facility, input_type: "text" }

  context "basic crud with columns" do
    let(:name) { unique_id }
    let(:start_at) { Time.zone.now.tomorrow.change(hour: 10, minute: 0, second: 0) }
    let(:end_at) { start_at + 3.hours }
    let(:name2) { unique_id }
    let(:column_value1) { unique_id }
    let(:column_value1_2) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create
      #
      visit gws_schedule_facility_plans_path(site: site, facility: facility)
      click_on I18n.t("gws/schedule.links.add_plan")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[start_at]", with: I18n.l(start_at, format: :picker) + "\n"
        fill_in "item[end_at]", with: I18n.l(end_at, format: :picker) + "\n"
        fill_in "item[facility_column_values][#{column1.id}]", with: column_value1
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css(".fc-title", text: name)

      expect(Gws::Schedule::Plan.all.count).to eq 1
      plan = Gws::Schedule::Plan.all.first
      expect(plan.name).to eq name
      expect(plan.facility_column_values.count).to eq 1
      expect(plan.facility_column_values.first.value).to eq column_value1

      #
      # Update
      #
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: plan)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[facility_column_values][#{column1.id}]", with: column_value1_2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css(".fc-title", text: name2)

      expect(Gws::Schedule::Plan.all.count).to eq 1
      plan.reload
      expect(plan.name).to eq name2
      expect(plan.facility_column_values.count).to eq 1
      expect(plan.facility_column_values.first.value).to eq column_value1_2

      #
      # Soft Delete
      #
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: plan)
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Schedule::Plan.all.count).to eq 1
      plan.reload
      expect(plan.deleted).to be_present
    end
  end
end

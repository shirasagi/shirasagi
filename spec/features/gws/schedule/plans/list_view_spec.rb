require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  context "list view" do
    let(:site) { gws_site }
    let(:now) { Time.zone.now.change(hour: 9) }

    let!(:item1) do
      create :gws_schedule_plan, start_at: now, category_id: category1.id, facility_ids: [facility1.id]
    end
    let!(:item2) do
      create :gws_schedule_plan, start_at: now.advance(days: 1), category_id: category2.id, facility_ids: [facility2.id]
    end
    let!(:item3) do
      create :gws_schedule_plan, start_at: now.advance(weeks: 1), category_id: category3.id, facility_ids: [facility3.id]
    end
    let!(:category1) { create :gws_schedule_category }
    let!(:category2) { create :gws_schedule_category }
    let!(:category3) { create :gws_schedule_category }
    let!(:facility1) { create :gws_facility_item }
    let!(:facility2) { create :gws_facility_item }
    let!(:facility3) { create :gws_facility_item }

    let(:index_path) { gws_schedule_plans_path site }

    before { login_gws_user }

    it "#index" do
      visit index_path
      within "#calendar" do
        click_on I18n.t("gws/schedule.calendar.buttonText.listMonth")
      end
      within ".fc-list-format" do
        expect(page).to have_text(item1.name)
        expect(page).to have_text(category1.name)
        expect(page).to have_text(facility1.name)

        expect(page).to have_text(item2.name)
        expect(page).to have_text(category2.name)
        expect(page).to have_text(facility2.name)

        expect(page).to have_text(item3.name)
        expect(page).to have_text(category3.name)
        expect(page).to have_text(facility3.name)
        click_on I18n.t("gws/schedule.options.interval.weekly").downcase
      end
      within ".fc-list-format" do
        expect(page).to have_text(item1.name)
        expect(page).to have_text(category1.name)
        expect(page).to have_text(facility1.name)

        expect(page).to have_text(item2.name)
        expect(page).to have_text(category2.name)
        expect(page).to have_text(facility2.name)

        expect(page).to have_no_text(item3.name)
        expect(page).to have_no_text(category3.name)
        expect(page).to have_no_text(facility3.name)
        click_on I18n.t("gws/schedule.options.interval.daily").downcase
      end
      within ".fc-list-format" do
        expect(page).to have_text(item1.name)
        expect(page).to have_text(category1.name)
        expect(page).to have_text(facility1.name)

        expect(page).to have_no_text(item2.name)
        expect(page).to have_no_text(category2.name)
        expect(page).to have_no_text(facility2.name)

        expect(page).to have_no_text(item3.name)
        expect(page).to have_no_text(category3.name)
        expect(page).to have_no_text(facility3.name)
      end
    end
  end
end

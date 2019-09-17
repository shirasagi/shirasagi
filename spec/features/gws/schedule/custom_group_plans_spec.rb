require 'spec_helper'

describe "gws_schedule_custom_group_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:custom_group) { create :gws_custom_group }
  let!(:item) { create :gws_schedule_plan }

  context "#index" do
    before { login_gws_user }

    context "when schedule_custom_group_extra_state is set to blank" do
      before do
        site.schedule_custom_group_extra_state = ""
        site.save!
      end

      it do
        visit gws_schedule_custom_group_plans_path(site: site, group: custom_group)
        within ".gws-schedule-box" do
          expect(page).to have_css("h2", text: custom_group.name)
          expect(page).to have_no_css(".group-creator", text: custom_group.user_long_name)
          expect(page).to have_css(".calendar-name", text: gws_user.long_name)
          expect(page).to have_css(".fc-title", text: item.name)
        end
      end
    end

    context "when schedule_custom_group_extra_state is set to 'creator_name'" do
      before do
        site.schedule_custom_group_extra_state = "creator_name"
        site.save!
      end

      it do
        visit gws_schedule_custom_group_plans_path(site: site, group: custom_group)
        within ".gws-schedule-box" do
          expect(page).to have_css("h2", text: custom_group.name)
          expect(page).to have_css(".group-creator", text: custom_group.user_long_name)
          expect(page).to have_css(".calendar-name", text: gws_user.long_name)
          expect(page).to have_css(".fc-title", text: item.name)
        end
      end
    end
  end
end

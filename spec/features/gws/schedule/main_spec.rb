require 'spec_helper'

describe "gws_schedule_main", type: :feature, dbscope: :example do
  let(:user) { gws_user }
  let(:site) { gws_site }
  let!(:custom_group) { create :gws_custom_group, member_ids: [user.id] }
  let(:facility) { create :gws_facility_item }
  let!(:item) { create :gws_schedule_facility_plan, facility_ids: [facility.id] }
  let(:index_path) { gws_schedule_main_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      site.update_attributes(
        schedule_personal_tab_state: 'hide',
        schedule_group_tab_state: 'hide',
        schedule_group_all_tab_state: 'hide',
        schedule_custom_group_tab_state: 'hide',
        schedule_facility_tab_state: 'hide'
      )
      # if @cur_user.gws_role_permit_any?(@cur_site, :use_private_gws_facility_plans) && @cur_site.schedule_facility_tab_visible?

      visit index_path
      expect(page).to have_content('404 Not Found')

      site.update_attributes(schedule_facility_tab_state: 'show')
      visit index_path
      wait_for_ajax
      expect(page).to have_css('.calendar-multiple-header', text: item.facilities.first.name)

      site.update_attributes(schedule_group_all_tab_state: 'show')
      visit index_path
      wait_for_ajax
      expect(current_path).to include gws_schedule_all_groups_path(site: site)

      site.update_attributes(schedule_custom_group_tab_state: 'show')
      visit index_path
      wait_for_ajax
      expect(page).to have_css('.calendar.multiple', text: item.name)

      site.update_attributes(schedule_group_tab_state: 'show')
      visit index_path
      wait_for_ajax
      expect(page).to have_css('.calendar.multiple', text: item.name)

      sleep 1

      site.update_attributes(schedule_personal_tab_state: 'show')
      visit index_path
      wait_for_ajax
      expect(page).to have_css('.calendar', text: item.name)

      visit "#{index_path}?calendar[path]=#{index_path}"
      wait_for_ajax do
        expect(page).to have_css('.calendar', text: item.name)
      end
    end
  end
end

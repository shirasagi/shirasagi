require 'spec_helper'

describe 'gws_presence_users', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:index_path) { gws_presence_users_path site }
    let!(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
    let!(:plan) { unique_id }
    let!(:memo) { unique_id }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".editable-users" do
        wait_for_all_turbo_frames

        click_on gws_user.name
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])

        find(".presence-plan .editicon").click
        wait_for_all_turbo_frames
        within "form" do
          fill_in "item[plan]", with: plan
        end

        find(".presence-memo .editicon").click
        wait_for_all_turbo_frames
        within "form" do
          fill_in "item[memo]", with: memo
        end
      end

      within ".group-users .list-head-title" do
        find(".reload").click
        wait_for_all_turbo_frames
      end

      within ".editable-users" do
        within "tr[data-id='#{gws_user.id}']" do
          expect(page).to have_text plan
          expect(page).to have_text memo
        end
      end
      within ".group-users" do
        within "tr[data-id='#{gws_user.id}']" do
          expect(page).to have_text plan
          expect(page).to have_text memo
        end
      end
    end
  end
end

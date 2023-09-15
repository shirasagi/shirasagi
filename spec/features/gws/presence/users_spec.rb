require 'spec_helper'

describe 'gws_presence_users', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:index_path) { gws_presence_users_path site }
    let!(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".editable-users" do
        click_on gws_user.name
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])

        find(".editicon.presence-plan").click
        fill_in "presence_plan", with: "modified_plan"
        find(".editicon.presence-plan").click
        expect(page).to have_css("[data-name='presence_plan']", text: "modified_plan")

        find(".editicon.presence-memo").click
        fill_in "presence_memo", with: "modified_memo"
        find(".editicon.presence-memo").click
        expect(page).to have_css("[data-name='presence_memo']", text: "modified_memo")
      end

      within ".group-users .list-head-title" do
        find(".reload").click
      end

      within ".group-users" do
        within "tr[data-id='#{gws_user.id}']" do
          expect(page).to have_text('modified_plan')
          expect(page).to have_text('modified_memo')
        end
      end
    end
  end
end

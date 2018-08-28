require 'spec_helper'

describe 'gws_presence_users', type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:index_path) { gws_presence_users_path site }
    let!(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      find(".editable-users").click_on gws_user.name
      find('.editable-users span', text: presence_states["available"]).click
      wait_for_ajax

      find(".editable-users .editicon.presence-plan").click
      fill_in "presence_plan", with: "modified_plan\n"
      wait_for_ajax

      find(".editable-users .editicon.presence-memo").click
      fill_in "presence_memo", with: "modified_memo\n"
      wait_for_ajax

      find(".group-users .list-head-title .editicon").click
      expect(current_path).to eq index_path

      expect(page).to have_text('modified_plan')
      expect(page).to have_text('modified_memo')
    end
  end
end

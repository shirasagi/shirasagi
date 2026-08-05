require 'spec_helper'

describe 'gws_presence_user_searches', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:index_path) { gws_presence_user_searches_path site }
    let!(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within "tr[data-id='#{gws_user.id}']" do
        find('.presence-state-toggle', text: presence_states['']).click
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])

        find(".presence-memo").click
        fill_in "presence_memo", with: "new_memo"
        find(".presence-memo").click
        expect(page).to have_css("[data-name='presence_memo']", text: "new_memo")

        click_link(gws_user.gws_main_group(site).trailing_name)

        expect(page).to have_css("[data-name='presence_memo']", text: "new_memo")

        wait_cbox_open { click_link(gws_user.name) }
      end

      wait_for_cbox do
        expect(page).to have_css("dd", text: gws_user.name)
        expect(page).to have_css("dd", text: gws_user.gws_main_group(site).trailing_name)
        expect(page).to have_css("dd", text: presence_states["available"])
        expect(page).to have_css("dd", text: 'new_memo')
        click_button(I18n.t('ss.buttons.close'))
      end

      click_link(I18n.t('ss.links.edit'))

      within "tr[data-id='#{gws_user.id}']" do
        fill_in "item[#{gws_user.id}][memo]", with: "modified_memo"
        fill_in "item[#{gws_user.id}][manager_name]", with: "modified_manager_name"
        fill_in "item[#{gws_user.id}][tel_ext]", with: "modified_tel_ext"
        fill_in "item[#{gws_user.id}][department]", with: "modified_department"
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      wait_cbox_open { click_link(gws_user.name) }

      wait_for_cbox do
        expect(page).to have_css("dd", text: gws_user.name)
        expect(page).to have_css("dd", text: gws_user.gws_main_group(site).trailing_name)
        expect(page).to have_css("dd", text: presence_states["available"])
        expect(page).to have_css("dd", text: 'modified_memo')
        click_button(I18n.t('ss.buttons.close'))
      end

      expect(page).to have_css("[data-name='presence_memo']", text: "modified_memo")
      expect(page).to have_css("td", text: "modified_manager_name")
      expect(page).to have_css("td", text: "modified_tel_ext")
      expect(page).to have_css("td", text: "modified_department")
    end
  end
end

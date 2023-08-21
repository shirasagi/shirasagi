require 'spec_helper'

describe "gws_presence_user_settings", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_presence_user_setting_path site }

  context "with auth", js: true do
    let!(:item) { gws_user.groups.in_group(site).first }

    before { login_gws_user }

    it "#show" do
      visit path

      within first('#navi') do
        expect(page).to have_text I18n.t("mongoid.models.gws/user_setting")
        within first('h3.current') do
          expect(page).to have_link I18n.t("modules.gws/presence")
          click_on I18n.t("modules.gws/presence")
        end
      end

      expect(current_path).to eq path
    end

    it "#edit" do
      visit "#{path}/edit"
      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end

      within first('#navi') do
        expect(page).to have_text I18n.t("mongoid.models.gws/user_setting")
        within first('h3.current') do
          expect(page).to have_link I18n.t("modules.gws/presence")
        end
      end
    end
  end
end

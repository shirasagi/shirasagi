require 'spec_helper'

describe "gws_affair_leave_management_settings", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:year) { create(:gws_affair_capital_year) }
    let(:item) { create(:gws_affair_leave_setting, year: year, target_user: user) }
    let(:index_path) { gws_affair_leave_settings_path site.id, year }
    let(:new_path) { new_gws_affair_leave_setting_path site.id, year }
    let(:show_path) { gws_affair_leave_setting_path site.id, year, item }
    let(:edit_path) { edit_gws_affair_leave_setting_path site.id, year, item }
    let(:delete_path) { delete_gws_affair_leave_setting_path site.id, year, item }

    context "basic crud" do
      before { login_gws_user }

      it "#new" do
        visit index_path
        click_on I18n.t("ss.links.new")

        within "form#item-form" do
          within "#addon-basic" do
            wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
          end
        end
        within_cbox do
          wait_for_cbox_closed { click_on user.name }
        end

        within "form#item-form" do
          expect(page).to have_css("#addon-basic .ajax-selected [data-id='#{user.id}']", text: user.name)
          fill_in "item[count]", with: 60
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
      end

      it "#show" do
        visit show_path
        expect(page).to have_css("#addon-basic", text: user.name)
      end

      it "#edit" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[count]", with: 60
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
      end

      it "#delete" do
        visit delete_path
        within "form#item-form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t('ss.notice.deleted')
      end

      it "#new" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[count]", with: 60
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
      end
    end
  end
end

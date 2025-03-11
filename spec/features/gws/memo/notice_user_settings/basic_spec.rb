require 'spec_helper'

describe 'gws_memo_notice_user_settings', type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:show_path) { gws_memo_notice_user_settings_path site }
    let!(:edit_path) { edit_gws_memo_notice_user_settings_path site }

    before { login_gws_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in "item[send_notice_mail_addresses]", with: gws_user.email
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq show_path
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_content(gws_user.email)
    end
  end

  context "permissions" do
    let!(:site) { gws_site }
    let!(:user1) { gws_user }
    let!(:user2) { create :gws_user, group_ids: user1.group_ids }

    context "gws_user" do
      before { login_user(user1) }

      it "#show" do
        visit gws_user_profile_path(site)
        within "#navi" do
          expect(page).to have_link I18n.t('sns.profile')
          expect(page).to have_link I18n.t('modules.addons.gws/system/notice_setting')
        end

        visit gws_memo_notice_user_settings_path(site)
        expect(page).to have_no_title("403")

        visit edit_gws_memo_notice_user_settings_path(site)
        expect(page).to have_no_title("403")
      end
    end

    context "user2" do
      before { login_user(user2) }

      it "#show" do
        visit gws_user_profile_path(site)
        within "#navi" do
          expect(page).to have_link I18n.t('sns.profile')
          expect(page).to have_no_link I18n.t('modules.addons.gws/system/notice_setting')
        end

        visit gws_memo_notice_user_settings_path(site)
        expect(page).to have_title("403")

        visit edit_gws_memo_notice_user_settings_path(site)
        expect(page).to have_title("403")
      end
    end
  end
end

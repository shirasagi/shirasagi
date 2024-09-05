require 'spec_helper'

describe 'gws_memo_notice_user_settings', type: :feature, dbscope: :example do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:show_path) { gws_memo_notice_user_settings_path site }
    let!(:edit_path) { edit_gws_memo_notice_user_settings_path site }
    let!(:email) { "sample@example.jp" }
    let!(:domains1) { %w(example.jp) }
    let!(:domains2) { %w(example.com) }

    context "not set sendmail_domains " do
      before { login_gws_user }

      it "#edit" do
        visit edit_path

        within "form#item-form" do
          fill_in "item[send_notice_mail_addresses]", with: email
          click_button I18n.t('ss.buttons.save')
        end
        expect(current_path).to eq show_path
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_content(email)
      end
    end

    context "set allowed sendmail_domains" do
      before do
        site.sendmail_domains = domains1
        site.update!

        login_gws_user
      end

      it "#edit" do
        visit edit_path

        within "form#item-form" do
          fill_in "item[send_notice_mail_addresses]", with: email
          click_button I18n.t('ss.buttons.save')
        end
        expect(current_path).to eq show_path
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_content(email)
      end
    end

    context "set disallowed sendmail_domains" do
      before do
        site.sendmail_domains = domains2
        site.update!

        login_gws_user
      end

      it "#edit" do
        visit edit_path

        within "form#item-form" do
          fill_in "item[send_notice_mail_addresses]", with: email
          click_button I18n.t('ss.buttons.save')
        end
        expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.disallowed_domains",
          domains: domains2.join(",")))
      end
    end
  end
end

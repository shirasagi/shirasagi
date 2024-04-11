require 'spec_helper'

describe "sys_password_policies", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:password_limit_days) { rand(1..100) }
    let(:password_warning_days) { rand(1..password_limit_days) }
    let(:password_min_length) { rand(12..20) }
    let(:password_min_upcase_length) { rand(1..3) }
    let(:password_min_downcase_length) { rand(1..3) }
    let(:password_min_digit_length) { rand(1..3) }
    let(:password_min_symbol_length) { rand(1..3) }
    let(:password_prohibited_char) { %w(a b c d e f g h i j k l).sample(3).join }
    let(:password_min_change_char_count) { rand(1..4) }

    before { login_sys_user }

    it do
      visit sys_password_policy_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: "item[password_limit_use]"
        fill_in "item[password_limit_days]", with: password_limit_days

        select I18n.t("ss.options.state.enabled"), from: "item[password_warning_use]"
        fill_in "item[password_warning_days]", with: password_warning_days

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_use]"
        fill_in "item[password_min_length]", with: password_min_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_upcase_use]"
        fill_in "item[password_min_upcase_length]", with: password_min_upcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_upcase_use]"
        fill_in "item[password_min_upcase_length]", with: password_min_upcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_downcase_use]"
        fill_in "item[password_min_downcase_length]", with: password_min_downcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_digit_use]"
        fill_in "item[password_min_digit_length]", with: password_min_digit_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_symbol_use]"
        fill_in "item[password_min_symbol_length]", with: password_min_symbol_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_prohibited_char_use]"
        fill_in "item[password_prohibited_char]", with: password_prohibited_char

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_change_char_use]"
        fill_in "item[password_min_change_char_count]", with: password_min_change_char_count

        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      Sys::Setting.first.tap do |setting|
        expect(setting.password_limit_use).to eq "enabled"
        expect(setting.password_limit_days).to eq password_limit_days

        expect(setting.password_warning_use).to eq "enabled"
        expect(setting.password_warning_days).to eq password_warning_days

        expect(setting.password_min_use).to eq "enabled"
        expect(setting.password_min_length).to eq password_min_length

        expect(setting.password_min_upcase_use).to eq "enabled"
        expect(setting.password_min_upcase_length).to eq password_min_upcase_length

        expect(setting.password_min_downcase_use).to eq "enabled"
        expect(setting.password_min_downcase_length).to eq password_min_downcase_length

        expect(setting.password_min_digit_use).to eq "enabled"
        expect(setting.password_min_digit_length).to eq password_min_digit_length

        expect(setting.password_min_symbol_use).to eq "enabled"
        expect(setting.password_min_symbol_length).to eq password_min_symbol_length

        expect(setting.password_prohibited_char_use).to eq "enabled"
        expect(setting.password_prohibited_char).to eq password_prohibited_char

        expect(setting.password_min_change_char_use).to eq "enabled"
        expect(setting.password_min_change_char_count).to eq password_min_change_char_count
      end
    end
  end

  context "password expiration" do
    let!(:setting) do
      Sys::Setting.create(
        password_limit_use: "enabled", password_limit_days: 10,
        password_warning_use: "enabled", password_warning_days: 5
      )
    end

    before do
      login_user user
    end

    context "when password is expired" do
      context "when @ss_mode is nil" do
        let(:user) { sys_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_limit_days.days)
          visit sns_mypage_path
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_expired"), href: sns_cur_user_account_path)
          end
        end
      end

      context "when @ss_mode is cms" do
        let(:user) { cms_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_limit_days.days)
          visit cms_main_path(site: cms_site)
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_expired"), href: sns_cur_user_account_path)
          end
        end
      end

      context "when @ss_mode is gws" do
        let(:user) { gws_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_limit_days.days)
          visit gws_portal_path(site: gws_site)
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_expired"), href: gws_user_profile_path(site: gws_site))
          end
        end
      end

      context "when @ss_mode is webmail" do
        let(:user) { webmail_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_limit_days.days)
          visit webmail_main_path
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_expired"), href: sns_cur_user_account_path)
          end
        end
      end
    end

    context "when password is nearly expired" do
      context "when @ss_mode is nil" do
        let(:user) { sys_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_warning_days.days)
          visit sns_mypage_path
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_neary_expired"), href: sns_cur_user_account_path)
          end
        end
      end

      context "when @ss_mode is cms" do
        let(:user) { cms_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_warning_days.days)
          visit cms_main_path(site: cms_site)
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_neary_expired"), href: sns_cur_user_account_path)
          end
        end
      end

      context "when @ss_mode is gws" do
        let(:user) { gws_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_warning_days.days)
          visit gws_portal_path(site: gws_site)
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_neary_expired"), href: gws_user_profile_path(site: gws_site))
          end
        end
      end

      context "when @ss_mode is webmail" do
        let(:user) { webmail_user }

        it do
          user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_warning_days.days)
          visit webmail_main_path
          within "div.warning" do
            expect(page).to have_link(I18n.t("ss.warning.password_neary_expired"), href: sns_cur_user_account_path)
          end
        end
      end
    end

    context "when password is alived" do
      context "when @ss_mode is nil" do
        let(:user) { sys_user }

        it do
          visit sns_mypage_path
          expect(page).to have_no_css("div.warning")
        end
      end
    end
  end
end

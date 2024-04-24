require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example, js: true do
  context "with MFA enabled" do
    let(:application_name) { SS.config.ss.application_name }
    let(:mfa_trusted_ip_addresses) { nil }

    before do
      auth_setting = Sys::Auth::Setting.instance
      auth_setting.mfa_otp_use_state = mfa_otp_use_state
      auth_setting.mfa_trusted_ip_addresses = mfa_trusted_ip_addresses
      auth_setting.save!
    end

    after { ActiveSupport::CurrentAttributes.reset_all }

    context "when users' opt is not configured" do
      context "with 'always' as mfa_otp_use_state" do
        let(:mfa_otp_use_state) { "always" }

        context "login success" do
          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end
            expect(page).to have_css(".otp-setup")

            otp_secret = find("[name='item[otp_secret]']").value
            totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
            code = totp.now
            within "form#item-form" do
              fill_in "item[code]", with: code
              click_on I18n.t("ss.login")
            end

            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to eq otp_secret
              expect(user.mfa_otp_enabled_at.to_i).to be_within(60).of(Time.zone.now.to_i)
              expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end

        context "code verification is failed" do
          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end
            expect(page).to have_css(".otp-setup")

            otp_secret = find("[name='item[otp_secret]']").value

            within "form#item-form" do
              fill_in "item[code]", with: "000000"
              click_on I18n.t("ss.login")
            end
            wait_for_error I18n.t("mongoid.errors.messages.mfa_otp_code_verification_is_failed")
            expect(page).to have_css(".otp-setup")

            # セッションが同じ限りシークレットは同じとする。つまり、アプリの再登録は不要とする。
            # セキュリティが低下する懸念はあるが、ログインの敷居を下げたい。
            expect(find("[name='item[otp_secret]']").value).to eq otp_secret

            totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
            code = totp.now
            within "form#item-form" do
              fill_in "item[code]", with: code
              click_on I18n.t("ss.login")
            end

            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to eq otp_secret
              expect(user.mfa_otp_enabled_at.to_i).to be_within(60).of(Time.zone.now.to_i)
              expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end
      end

      context "with 'untrusted' as mfa_otp_use_state" do
        let(:mfa_otp_use_state) { "untrusted" }
        let(:mfa_trusted_ip_addresses) { "192.168.32.0/24" }
        let(:rack_proxy_app) do
          source_ip_bind = source_ip
          Class.new do
            cattr_accessor :source_ip
            self.source_ip = source_ip_bind

            def initialize(app)
              @app = app
            end

            def call(env)
              env["HTTP_X_REAL_IP"] = self.class.source_ip
              @app.call(env)
            end
          end
        end

        before do
          Sns::LoginController.middleware_stack.use rack_proxy_app
          Sns::MFALoginController.middleware_stack.use rack_proxy_app
        end

        after do
          Sns::LoginController.middleware_stack.delete rack_proxy_app
          Sns::MFALoginController.middleware_stack.delete rack_proxy_app
        end

        context "with trusted source-ip" do
          let(:source_ip) { "192.168.32.76" }

          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end

            # このケースではOTP認証は不要
            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to be_blank
              expect(user.mfa_otp_enabled_at).to be_blank
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end

        context "with untrusted source-ip" do
          let(:source_ip) { "192.168.33.54" }

          context "login success" do
            it do
              visit sns_login_path(ref: sns_cur_user_account_path)

              within "form" do
                fill_in "item[email]", with: sys_user.email
                fill_in "item[password]", with: "pass"
                click_on I18n.t("ss.login")
              end
              expect(page).to have_css(".otp-setup")

              otp_secret = find("[name='item[otp_secret]']").value
              totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
              code = totp.now
              within "form#item-form" do
                fill_in "item[code]", with: code
                click_on I18n.t("ss.login")
              end

              expect(current_path).to eq sns_cur_user_account_path
              expect(page).to have_css("nav.user .user-name", text: sys_user.name)

              SS::User.find(sys_user.id).tap do |user|
                expect(user.mfa_otp_secret).to eq otp_secret
                expect(user.mfa_otp_enabled_at.to_i).to be_within(60).of(Time.zone.now.to_i)
                expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
              end

              I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
                # do logout
                within ".user-navigation" do
                  wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                  click_on I18n.t("ss.logout")
                end
              end

              # confirm a login form has been shown
              expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
              expect(current_path).to eq sns_login_path
            end
          end

          context "code verification is failed" do
            it do
              visit sns_login_path(ref: sns_cur_user_account_path)

              within "form" do
                fill_in "item[email]", with: sys_user.email
                fill_in "item[password]", with: "pass"
                click_on I18n.t("ss.login")
              end
              expect(page).to have_css(".otp-setup")

              otp_secret = find("[name='item[otp_secret]']").value

              within "form#item-form" do
                fill_in "item[code]", with: "000000"
                click_on I18n.t("ss.login")
              end
              wait_for_error I18n.t("mongoid.errors.messages.mfa_otp_code_verification_is_failed")
              expect(page).to have_css(".otp-setup")

              # セッションが同じ限りシークレットは同じとする。つまり、アプリの再登録は不要とする。
              # セキュリティが低下する懸念はあるが、ログインの敷居を下げたい。
              expect(find("[name='item[otp_secret]']").value).to eq otp_secret

              totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
              code = totp.now
              within "form#item-form" do
                fill_in "item[code]", with: code
                click_on I18n.t("ss.login")
              end

              expect(current_path).to eq sns_cur_user_account_path
              expect(page).to have_css("nav.user .user-name", text: sys_user.name)

              SS::User.find(sys_user.id).tap do |user|
                expect(user.mfa_otp_secret).to eq otp_secret
                expect(user.mfa_otp_enabled_at.to_i).to be_within(60).of(Time.zone.now.to_i)
                expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
              end

              I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
                # do logout
                within ".user-navigation" do
                  wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                  click_on I18n.t("ss.logout")
                end
              end

              # confirm a login form has been shown
              expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
              expect(current_path).to eq sns_login_path
            end
          end
        end
      end
    end

    context "when users' opt is already configured" do
      let(:otp_secret) { ROTP::Base32.random }
      let(:now) { Time.zone.now.change(usec: 0) }

      before do
        SS::User.find(sys_user.id).tap do |user|
          user.set(mfa_otp_secret: otp_secret, mfa_otp_enabled_at: now)
        end
      end

      context "with 'always' as mfa_otp_use_state" do
        let(:mfa_otp_use_state) { "always" }

        context "login success" do
          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end
            expect(page).to have_css(".otp-login")

            totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
            code = totp.now
            within "form#item-form" do
              fill_in "item[code]", with: code
              click_on I18n.t("ss.login")
            end

            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to eq otp_secret
              expect(user.mfa_otp_enabled_at.in_time_zone).to eq now
              expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end

        context "code verification is failed" do
          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end
            expect(page).to have_css(".otp-login")

            within "form#item-form" do
              fill_in "item[code]", with: "000000"
              click_on I18n.t("ss.login")
            end
            wait_for_error I18n.t("mongoid.errors.messages.mfa_otp_code_verification_is_failed")
            expect(page).to have_css(".otp-login")

            totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
            code = totp.now
            within "form#item-form" do
              fill_in "item[code]", with: code
              click_on I18n.t("ss.login")
            end

            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to eq otp_secret
              expect(user.mfa_otp_enabled_at.in_time_zone).to eq now
              expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end
      end

      context "with 'untrusted' as mfa_otp_use_state" do
        let(:mfa_otp_use_state) { "untrusted" }
        let(:mfa_trusted_ip_addresses) { "192.168.32.0/24" }
        let(:rack_proxy_app) do
          source_ip_bind = source_ip
          Class.new do
            cattr_accessor :source_ip
            self.source_ip = source_ip_bind

            def initialize(app)
              @app = app
            end

            def call(env)
              env["HTTP_X_REAL_IP"] = self.class.source_ip
              @app.call(env)
            end
          end
        end

        before do
          Sns::LoginController.middleware_stack.use rack_proxy_app
          Sns::MFALoginController.middleware_stack.use rack_proxy_app
        end

        after do
          Sns::LoginController.middleware_stack.delete rack_proxy_app
          Sns::MFALoginController.middleware_stack.delete rack_proxy_app
        end

        context "with trusted source-ip" do
          let(:source_ip) { "192.168.32.76" }

          it do
            visit sns_login_path(ref: sns_cur_user_account_path)

            within "form" do
              fill_in "item[email]", with: sys_user.email
              fill_in "item[password]", with: "pass"
              click_on I18n.t("ss.login")
            end

            # このケースではOTP認証は不要
            expect(current_path).to eq sns_cur_user_account_path
            expect(page).to have_css("nav.user .user-name", text: sys_user.name)

            SS::User.find(sys_user.id).tap do |user|
              expect(user.mfa_otp_secret).to eq otp_secret
              expect(user.mfa_otp_enabled_at.in_time_zone).to eq now
              expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
            end

            I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
              # do logout
              within ".user-navigation" do
                wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                click_on I18n.t("ss.logout")
              end
            end

            # confirm a login form has been shown
            expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
            expect(current_path).to eq sns_login_path
          end
        end

        context "with untrusted source-ip" do
          let(:source_ip) { "192.168.33.54" }

          context "login success" do
            it do
              visit sns_login_path(ref: sns_cur_user_account_path)

              within "form" do
                fill_in "item[email]", with: sys_user.email
                fill_in "item[password]", with: "pass"
                click_on I18n.t("ss.login")
              end
              expect(page).to have_css(".otp-login")

              totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
              code = totp.now
              within "form#item-form" do
                fill_in "item[code]", with: code
                click_on I18n.t("ss.login")
              end

              expect(current_path).to eq sns_cur_user_account_path
              expect(page).to have_css("nav.user .user-name", text: sys_user.name)

              SS::User.find(sys_user.id).tap do |user|
                expect(user.mfa_otp_secret).to eq otp_secret
                expect(user.mfa_otp_enabled_at.in_time_zone).to eq now
                expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
              end

              I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
                # do logout
                within ".user-navigation" do
                  wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                  click_on I18n.t("ss.logout")
                end
              end

              # confirm a login form has been shown
              expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
              expect(current_path).to eq sns_login_path
            end
          end

          context "code verification is failed" do
            it do
              visit sns_login_path(ref: sns_cur_user_account_path)

              within "form" do
                fill_in "item[email]", with: sys_user.email
                fill_in "item[password]", with: "pass"
                click_on I18n.t("ss.login")
              end
              expect(page).to have_css(".otp-login")

              within "form#item-form" do
                fill_in "item[code]", with: "000000"
                click_on I18n.t("ss.login")
              end
              wait_for_error I18n.t("mongoid.errors.messages.mfa_otp_code_verification_is_failed")
              expect(page).to have_css(".otp-login")

              totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
              code = totp.now
              within "form#item-form" do
                fill_in "item[code]", with: code
                click_on I18n.t("ss.login")
              end

              expect(current_path).to eq sns_cur_user_account_path
              expect(page).to have_css("nav.user .user-name", text: sys_user.name)

              SS::User.find(sys_user.id).tap do |user|
                expect(user.mfa_otp_secret).to eq otp_secret
                expect(user.mfa_otp_enabled_at.in_time_zone).to eq now
                expect(user.updated.in_time_zone).to eq sys_user.updated.in_time_zone
              end

              I18n.with_locale(sys_user.lang.try { |lang| lang.to_sym } || I18n.default_locale) do
                # do logout
                within ".user-navigation" do
                  wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
                  click_on I18n.t("ss.logout")
                end
              end

              # confirm a login form has been shown
              expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
              expect(current_path).to eq sns_login_path
            end
          end
        end
      end
    end
  end
end

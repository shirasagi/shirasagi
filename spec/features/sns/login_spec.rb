require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example, js: true do
  it "invalid login" do
    visit sns_login_path
    within "form" do
      fill_in "item[email]", with: "wrong@example.jp"
      fill_in "item[password]", with: "wrong_pass"
      click_button I18n.t("ss.login")
    end
    expect(current_path).not_to eq sns_mypage_path
  end

  context "with sys_user" do
    context "with email" do
      it 'valid login' do
        visit sns_login_path
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).to have_no_css(".login-box")
        I18n.with_locale(sys_user.lang.to_sym) do
          within ".user-navigation" do
            wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
            expect(page).to have_link(I18n.t("ss.logout"), href: sns_logout_path)
            click_on I18n.t("ss.logout")
          end
        end

        expect(current_path).to eq sns_login_path
      end
    end

    context "when internal path is given at `ref` parameter" do
      it do
        visit sns_login_path(ref: sns_cur_user_profile_path)
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end

        expect(current_path).to eq sns_cur_user_profile_path
        expect(page).to have_no_css(".login-box")
        I18n.with_locale(sys_user.lang.to_sym) do
          within ".user-navigation" do
            wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
            expect(page).to have_link(I18n.t("ss.logout"), href: sns_logout_path)
            click_on I18n.t("ss.logout")
          end
        end
        expect(current_path).to eq sns_login_path
      end
    end

    context "when internal url is given at `ref` parameter" do
      let(:capybara_server) { Capybara.current_session.server }
      let(:ref) { sns_cur_user_profile_url(host: "#{capybara_server.host}:#{capybara_server.port}") }

      it do
        visit sns_login_path(ref: ref)
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end

        expect(current_path).to eq sns_cur_user_profile_path
        expect(page).to have_no_css(".login-box")
        I18n.with_locale(sys_user.lang.to_sym) do
          within ".user-navigation" do
            wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
            expect(page).to have_link(I18n.t("ss.logout"), href: sns_logout_path)
            click_on I18n.t("ss.logout")
          end
        end
        expect(current_path).to eq sns_login_path
      end
    end

    context "when external url is given at `ref` parameter" do
      before do
        @save_url_type = SS.config.sns.url_type
        SS.config.replace_value_at(:sns, :url_type, "restricted")
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      after do
        SS.config.replace_value_at(:sns, :url_type, @save_url_type)
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      it do
        visit sns_login_path(ref: "https://www.google.com/")
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end

        expect(current_path).to eq sns_mypage_path
        expect(page).to have_no_css(".login-box")
        I18n.with_locale(sys_user.lang.to_sym) do
          within ".user-navigation" do
            wait_event_to_fire("turbo:frame-load") { click_on sys_user.name }
            expect(page).to have_link(I18n.t("ss.logout"), href: sns_logout_path)
            click_on I18n.t("ss.logout")
          end
        end
        expect(current_path).to eq sns_login_path
      end
    end
  end

  context "with cms user" do
    context "with email" do
      subject { cms_user }
      it "valid login" do
        visit sns_login_path
        within "form" do
          fill_in "item[email]", with: subject.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).to have_no_css(".login-box")
      end
    end

    context "with uid" do
      subject { cms_user }
      it "valid login" do
        visit sns_login_path
        within "form" do
          fill_in "item[email]", with: subject.name
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).to have_no_css(".login-box")
      end
    end

    context "with organization_uid" do
      subject { cms_user }
      it "invalid login" do
        visit sns_login_path
        within "form" do
          fill_in "item[email]", with: subject.organization_uid
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end
        expect(current_path).not_to eq sns_mypage_path
      end

      context "with cms_group domains" do
        let(:domain) { 'www.example.com' }
        let(:rack_proxy_app) do
          domain_bind = domain
          Class.new do
            cattr_accessor :domain
            self.domain = domain_bind

            def initialize(app)
              @app = app
            end

            def call(env)
              env["HTTP_X_FORWARDED_HOST"] = self.class.domain
              @app.call(env)
            end
          end
        end

        before do
          cms_group.set(domains: [domain])
          Sns::LoginController.middleware_stack.use rack_proxy_app
        end

        after do
          Sns::LoginController.middleware_stack.delete rack_proxy_app
        end

        it "valid login" do
          visit sns_login_path
          within "form" do
            fill_in "item[email]", with: subject.organization_uid
            fill_in "item[password]", with: "pass"
            click_button I18n.t("ss.login")
          end
          expect(current_path).to eq sns_mypage_path
          expect(page).to have_no_css(".login-box")
        end
      end
    end
  end

  context "with ldap user", ldap: true do
    let(:base_dn) { "dc=example,dc=jp" }
    let(:group) { create(:cms_group, name: unique_id, ldap_dn: base_dn) }
    let(:user_dn) { "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass" }
    subject { create(:cms_ldap_user, ldap_dn: user_dn, group: group) }

    it "valid login" do
      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: subject.name
        fill_in "item[password]", with: password
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_no_css(".login-box")
    end
  end

  context "when email/password get parameters is given" do
    let(:role) { sys_role }
    let(:user) { create(:sys_user, in_password: "pass", sys_role_ids: [role.id]) }
    # bookmark support
    it "valid login" do
      visit sns_login_path(email: user.email)
      expect(find("#item_email").value).to eq(user.email)
      within "form" do
        fill_in "item[password]", with: user.in_password
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_no_css(".login-box")
    end
  end

  describe "#redirect" do
    context "with internal path" do
      it do
        visit sns_redirect_path(ref: cms_main_path(site: cms_site))
        expect(current_path).to eq sns_login_path
      end
    end

    context "with external url" do
      before do
        @save_url_type = SS.config.sns.url_type
        SS.config.replace_value_at(:sns, :url_type, "restricted")
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      after do
        SS.config.replace_value_at(:sns, :url_type, @save_url_type)
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      it do
        visit sns_redirect_path(ref: "https://www.google.com/")
        expect(current_path).to eq sns_redirect_path
        expect(page).to have_link("https://www.google.com/", href: "https://www.google.com/")
      end
    end

    context "with japanese in url's path" do
      before do
        @save_url_type = SS.config.sns.url_type
        SS.config.replace_value_at(:sns, :url_type, "restricted")
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      after do
        SS.config.replace_value_at(:sns, :url_type, @save_url_type)
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      it do
        visit sns_redirect_path(ref: "https://sns.example.jp/fs/日本語.pdf")
        expect(current_path).to eq sns_redirect_path
        expect(page).to have_link("https://sns.example.jp/fs/日本語.pdf", href: "https://sns.example.jp/fs/日本語.pdf")
      end
    end
  end
end

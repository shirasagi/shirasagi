require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example do
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
        expect(find('#head .logout')[:href]).to eq sns_logout_path

        find('#head .logout').click
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
        expect(find('#head .logout')[:href]).to eq sns_logout_path

        find('#head .logout').click
        expect(current_path).to eq sns_login_path
      end
    end

    context "when internal url is given at `ref` parameter" do
      it do
        visit sns_login_path(ref: sns_cur_user_profile_url)
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end

        expect(current_path).to eq sns_cur_user_profile_path
        expect(page).to have_no_css(".login-box")
        expect(find('#head .logout')[:href]).to eq sns_logout_path

        find('#head .logout').click
        expect(current_path).to eq sns_login_path
      end
    end

    context "when external url is given at `ref` parameter" do
      it do
        visit sns_login_path(ref: "https://www.google.com/")
        within "form" do
          fill_in "item[email]", with: sys_user.email
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end

        expect(current_path).to eq sns_mypage_path
        expect(page).to have_no_css(".login-box")
        expect(find('#head .logout')[:href]).to eq sns_logout_path

        find('#head .logout').click
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
        before do
          cms_group.set(domains: ['www.example.com'])
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
      expect(status_code).to eq 200
      expect(find("#item_email").value).to eq(user.email)
      within "form" do
        fill_in "item[password]", with: user.in_password
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_no_css(".login-box")
    end
  end

  context 'loggedin status' do
    it do
      visit sns_login_status_path
      expect(status_code).to eq 403

      login_sys_user
      visit sns_login_status_path
      expect(status_code).to eq 200
    end
  end

  describe "#redirect" do
    context "with internal path" do
      it do
        visit sns_redirect_path(ref: cms_main_path(site: cms_site))
        expect(status_code).to eq 200
        expect(current_path).to eq sns_login_path
      end
    end

    context "with external url" do
      it do
        visit sns_redirect_path(ref: "https://www.google.com/")
        expect(status_code).to eq 200
        expect(current_path).to eq sns_redirect_path
        expect(page).to have_link("https://www.google.com/", href: "https://www.google.com/")
      end
    end
  end
end

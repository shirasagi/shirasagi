require 'spec_helper'

describe "sns_login", dbscope: :example do
  it "invalid login" do
    visit sns_login_path
    within "form" do
      fill_in "item[email]", with: "wrong@example.jp"
      fill_in "item[password]", with: "wrong_pass"
      click_button "ログイン"
    end
    expect(current_path).not_to eq sns_mypage_path
  end

  context "with sys_user" do
    it "valid login" do
      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: sys_user.email
        fill_in "item[password]", with: "pass"
        click_button "ログイン"
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).not_to have_css(".login-box")
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
          click_button "ログイン"
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).not_to have_css(".login-box")
      end
    end

    context "with uid" do
      subject { cms_user }
      it "valid login" do
        visit sns_login_path
        within "form" do
          # fill in hidden field tag
          fill_in "item[email]", with: subject.name
          fill_in "item[password]", with: "pass"
          click_button "ログイン"
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).not_to have_css(".login-box")
      end
    end
  end

  context "with ldap user", ldap: true do
    let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
    let(:group) { create(:cms_group, name: unique_id, ldap_dn: base_dn) }
    let(:user_dn) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject { create(:cms_ldap_user, ldap_dn: user_dn, group: group) }

    it "valid login" do
      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: subject.name
        fill_in "item[password]", with: "user1"
        click_button "ログイン"
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).not_to have_css(".login-box")
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
        click_button "ログイン"
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).not_to have_css(".login-box")
    end
  end
end

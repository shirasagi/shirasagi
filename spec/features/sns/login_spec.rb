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
      it "valid login" do
        visit sns_login_path
        within "form" do
          fill_in "item[email]", with: cms_user.email
          fill_in "item[password]", with: "pass"
          click_button "ログイン"
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).not_to have_css(".login-box")
      end
    end

    context "with uid" do
      it "valid login" do
        visit sns_login_path
        within "form" do
          # fill in hidden field tag
          find(:xpath, "//input[@id='item_in_group']").set cms_group.name
          fill_in "item[email]", with: cms_user.name
          fill_in "item[password]", with: "pass"
          click_button "ログイン"
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).not_to have_css(".login-box")
      end
    end
  end
end

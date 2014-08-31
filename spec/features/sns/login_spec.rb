# coding: utf-8
require 'spec_helper'

describe "sns_login" do
  let!(:user) { create(:sys_user) }

  specify "login" do
    visit sns_login_path
    within "form" do
      fill_in "item[email]", with: "sys@example.jp"
      fill_in "item[password]", with: "pass"
      click_button "ログイン"
    end
    #dump "#{status_code} #{current_path}"
    #expect(page.status_code).to eq 200
    #expect(page).not_to have_css(".login-box")
  end
end

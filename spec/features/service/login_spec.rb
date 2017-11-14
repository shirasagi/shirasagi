require 'spec_helper'

describe "service_accounts", type: :feature, dbscope: :example do
  let!(:user) { create :service_account }
  let(:index_path) { service_accounts_path }

  it "invalid login" do
    visit service_login_path
    within "form" do
      fill_in "item[account]", with: "wrong_account"
      fill_in "item[password]", with: "wrong_pass"
      click_button "ログイン"
    end
    expect(current_path).to eq service_login_path
  end

  it "valid login" do
    visit service_login_path
    within "form" do
      fill_in "item[account]", with: user.account
      fill_in "item[password]", with: user.in_password
      click_button "ログイン"
    end
    expect(current_path).to eq service_my_accounts_path

    find('#head .logout').click
    expect(current_path).to eq service_login_path
  end
end

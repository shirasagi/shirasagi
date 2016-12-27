require 'spec_helper'

describe "sns_cur_user_accounts", dbscope: :example do
  let!(:show_path) { sns_cur_user_account_path }
  let!(:edit_path) { edit_sns_cur_user_account_path }

  context "with auth" do
    before { login_ss_user }

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in "item[email]", with: "modify@example.jp"
        fill_in "item[in_password]", with: "abc123"
        fill_in "item[tel]", with: "000-000-0000"
        fill_in "item[tel_ext]", with: "000-000-0000"
        click_button "保存"
      end
      expect(current_path).to eq show_path

      user = SS::User.first
      expect(user.name).to eq "modify"
      expect(user.email).to eq "modify@example.jp"
      expect(user.tel).to eq "000-000-0000"
      expect(user.tel_ext).to eq "000-000-0000"
      expect(SS::User.authenticate("modify@example.jp", "abc123")).to be_truthy
    end
  end
end

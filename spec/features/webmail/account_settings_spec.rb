require 'spec_helper'

describe "webmail_account_settings", type: :feature, dbscope: :example do
  let(:show_path) { webmail_account_setting_path }
  let(:edit_path) { "#{show_path}/edit" }

  context "with auth" do
    before { login_ss_user }

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit edit_path
      expect(status_code).to eq 200
    end
  end
end

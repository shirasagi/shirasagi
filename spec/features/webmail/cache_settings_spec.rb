require 'spec_helper'

describe "webmail_cache_settings", type: :feature, dbscope: :example do
  let(:show_path) { webmail_cache_setting_path }

  context "with auth" do
    before { login_ss_user }

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
    end
  end
end

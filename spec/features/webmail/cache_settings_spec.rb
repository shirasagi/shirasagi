require 'spec_helper'

describe "webmail_cache_settings", type: :feature, dbscope: :example do
  let(:show_path) { webmail_cache_setting_path }

  context "with auth", js: true do
    before { login_ss_user }

    it "#show" do
      visit show_path
      expect(status_code).to eq 200

      find("#item-form1 .save").click
      page.accept_confirm

      #find("#item-form2 .save").click
      #page.accept_confirm

      find("#item-form3 .save").click
      page.accept_confirm

      #find("#item-form4 .save").click
      #page.accept_confirm
    end
  end
end

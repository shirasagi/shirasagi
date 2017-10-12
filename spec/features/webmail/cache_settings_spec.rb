require 'spec_helper'

describe "webmail_cache_settings", type: :feature, dbscope: :example do
  let(:show_path) { webmail_cache_setting_path(account: 0) }

  context "with auth", js: true do
    before { login_ss_user }

    it "#show" do
      visit show_path

      page.accept_confirm do
        find("#item-form1 .save").click
      end

      #page.accept_confirm do
      #  find("#item-form2 .save").click
      #end

      page.accept_confirm do
        find("#item-form3 .save").click
      end

      #page.accept_confirm do
      #  find("#item-form4 .save").click
      #end
    end
  end
end

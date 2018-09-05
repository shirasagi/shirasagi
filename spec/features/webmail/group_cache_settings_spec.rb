require 'spec_helper'

describe "webmail_group_cache_settings", type: :feature, dbscope: :example do
  let(:group) { create :webmail_group }
  let(:show_path) { webmail_group_cache_setting_path(group: group) }

  context "with auth", js: true do
    before { login_ss_user }

    it "#show" do
      visit show_path

      page.accept_confirm do
        find("#item-form1 .save").click
      end

      page.accept_confirm do
        find("#item-form3 .save").click
      end
    end
  end
end

require 'spec_helper'

describe "webmail_cache_settings", type: :feature, dbscope: :example do
  shared_examples "webmail cache settings flow" do
    context "with auth", js: true do
      before { login_webmail_user }

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

  describe "webmail_mode is account" do
    let(:show_path) { webmail_cache_setting_path(account: 0) }

    it_behaves_like 'webmail cache settings flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:show_path) { webmail_cache_setting_path(account: group.id, webmail_mode: :group) }

    before { webmail_user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail cache settings flow'
  end
end

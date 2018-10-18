require 'spec_helper'

describe "webmail_mailboxes", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:item_title) { "rspec-#{unique_id}" }

  shared_examples "webmail mailboxes flow" do
    context "with auth" do
      before { login_user(user) }

      it "#index" do
        visit index_path
        expect(current_path).to eq index_path

        # new
        click_link I18n.t('ss.links.new')
        within "form#item-form" do
          fill_in "item[name]", with: item_title
        end
        click_button I18n.t('ss.buttons.save')
        expect(current_path).to eq index_path

        # edit
        click_link item_title
        click_link I18n.t('ss.links.edit')
        within "form#item-form" do
          fill_in "item[name]", with: "#{item_title}2"
        end
        click_button I18n.t('ss.buttons.save')

        # delete
        click_link item_title
        click_link I18n.t('ss.links.delete')
        click_button I18n.t('ss.buttons.delete')

        # reload
        click_link I18n.t('webmail.links.reload_mailboxes')
        click_button I18n.t('webmail.buttons.sync')

        expect(current_path).to eq index_path
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mailboxes_path(account: 0) }

    it_behaves_like 'webmail mailboxes flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mailboxes_path(account: group.id, webmail_mode: :group) }

    before { user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail mailboxes flow'
  end
end

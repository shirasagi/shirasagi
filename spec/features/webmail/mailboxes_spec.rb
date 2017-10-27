require 'spec_helper'

describe "webmail_mailboxes", type: :feature, dbscope: :example, imap: true do
  let(:user) { create :webmail_user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_mailboxes_path(account: 0) }

  context "with auth" do
    before { login_user(user) }

    it "#index", js: true do
      visit index_path
      expect(status_code).to eq 200

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

      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end

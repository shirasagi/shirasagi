require 'spec_helper'

describe "webmail_group_mails", type: :feature, dbscope: :example, imap: true do
  let(:group) { create :webmail_group }
  let(:user) { create :webmail_user, group_ids: [group.id] }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_group_mails_path(group: group) }

  context "with auth" do
    before { login_user(user) }

    it "#index", js: true do
      visit index_path

      find(".webmail-navi-mailboxes a.reload").click
      find(".webmail-navi-mailboxes .mailboxes a.inbox-draft").click
      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click
      find(".webmail-navi-mailboxes .mailboxes a.inbox-trash").click
    end

    it "#show", js: true do
      visit index_path
      click_link I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in "to", with: user.email + "\n"
        fill_in "item[subject]", with: item_title
        fill_in "item[text]", with: "message\n" * 2
      end
      click_button I18n.t('ss.buttons.send')
      sleep 1
      expect(current_path).to eq index_path

      # reply
      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click
      click_link item_title
      click_link I18n.t('webmail.links.reply')
      click_button I18n.t('ss.buttons.send')

      # reply_all
      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click
      click_link item_title
      click_link I18n.t('webmail.links.reply_all')
      within "form#item-form" do
        fill_in "to", with: user.email + "\n"
      end
      click_button I18n.t('ss.buttons.send')

      # forward
      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click
      click_link item_title
      click_link I18n.t('webmail.links.forward')
      within "form#item-form" do
        fill_in "to", with: user.email + "\n"
      end
      click_button I18n.t('ss.buttons.send')

      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click
      click_link item_title, match: :first

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(current_path).to eq webmail_group_mails_path(group: group, mailbox: "INBOX.Sent")
    end
  end
end

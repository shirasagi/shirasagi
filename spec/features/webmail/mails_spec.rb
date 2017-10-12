require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true do
  let(:user) { create :webmail_user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_mails_path(account: 0) }

  context "with auth" do
    before { login_user(user) }

    it "#index", js: true do
      visit index_path
      expect(status_code).to eq 200

      find(".webmail-navi-mailboxes .inbox-sent").click
      find(".webmail-navi-mailboxes .inbox-draft").click
      find(".webmail-navi-mailboxes .inbox-trash").click
      find(".webmail-navi-mailboxes .reload").click
      find(".webmail-navi-quota .reload").click
    end

    it "#show" do
      # new/create
      visit index_path
      click_link I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in "item[to_text]", with: user.email
        fill_in "item[subject]", with: item_title
        fill_in "item[text]", with: "message\n" * 2
      end
      click_button I18n.t('ss.buttons.send')
      sleep 1
      expect(current_path).to eq index_path

      # reply
      click_link item_title
      click_link I18n.t('webmail.links.reply')
      click_button I18n.t('ss.buttons.send')

      # reply_all
      click_link item_title
      click_link I18n.t('webmail.links.reply_all')
      within "form#item-form" do
        fill_in "item[to_text]", with: user.email
      end
      click_button I18n.t('ss.buttons.send')

      # forward
      click_link item_title
      click_link I18n.t('webmail.links.forward')
      within "form#item-form" do
        fill_in "item[to_text]", with: user.email
      end
      click_button I18n.t('ss.buttons.send')

      click_link item_title

      # seen
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.unset_seen')
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.set_seen')
#
      # # star
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.set_star')
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.unset_star')
#
      # # etc
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.header_view')
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.source_view')
      # find("#menu > .nav-menu > .dropdown > a").click
      # click_link I18n.t('webmail.links.download')

      # delete
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(current_path).to eq index_path
    end
  end
end

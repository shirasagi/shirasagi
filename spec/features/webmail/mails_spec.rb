require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:item_title) { "rspec-#{unique_id}" }

  shared_examples "webmail mails flow" do
    context "with auth" do
      before { login_user(user) }

      it "#index" do
        visit index_path

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
          fill_in "to", with: user.email + "\n"
          fill_in "item[subject]", with: item_title
          fill_in "item[text]", with: "message\n" * 2
        end
        click_button I18n.t('ss.buttons.send')
        sleep 1
        expect(current_path).to eq index_path

        if Webmail::Mailer.delivery_method == :test
          pending "delivery_method is :test"
        end

        # reload mails
        first(".webmail-navi-mailboxes .reload").click

        # reply
        click_link item_title
        click_link I18n.t('webmail.links.reply')
        click_button I18n.t('ss.buttons.send')

        # reply_all
        click_link item_title
        click_link I18n.t('webmail.links.reply_all')
        within "form#item-form" do
          fill_in "to", with: user.email + "\n"
        end
        click_button I18n.t('ss.buttons.send')

        # forward
        click_link item_title
        click_link I18n.t('webmail.links.forward')
        within "form#item-form" do
          fill_in "to", with: user.email + "\n"
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

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mails_path(account: 0) }

    it_behaves_like 'webmail mails flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

    before { user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail mails flow'
  end
end

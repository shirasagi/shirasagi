require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when bcc is given" do
    let(:user) { webmail_imap }
    let(:user2) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:user3) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:user4) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails send with bcc flow" do
      before do
        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        # save as draft
        visit index_path
        click_on I18n.t('ss.links.new')
        within "form#item-form" do
          click_on I18n.t("webmail.links.show_cc_bcc")

          fill_in "to", with: user2.email + "\n"
          fill_in "cc", with: user3.email + "\n"
          fill_in "bcc", with: user4.email + "\n"
          fill_in "item[subject]", with: item_subject
          fill_in "item[text]", with: item_texts.join("\n")

          click_on I18n.t('ss.buttons.draft_save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_css(".address-field", text: user2.email)
        expect(page).to have_css(".address-field", text: user3.email)
        expect(page).to have_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)

        # send
        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          click_on I18n.t('ss.buttons.send')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq address
          expect(mail.to.first).to eq user2.email
          expect(mail.cc.first).to eq user3.email
          expect(mail.bcc.first).to eq user4.email
          expect(mail.subject).to eq item_subject
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end

        # confirm sent box
        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.sent")
        end
        click_on item_subject
        expect(page).to have_css(".address-field", text: user2.email)
        expect(page).to have_css(".address-field", text: user3.email)
        expect(page).to have_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)

        # confirm to remove draft main in draft box
        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        expect(page).to have_no_content(item_subject)
        expect(page).to have_no_css(".list-item")

        # reply to all
        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.sent")
        end
        click_on item_subject
        within "#menu" do
          # drop down "reply"
          first(".webmail-dropdown a").click
          click_on I18n.t("webmail.links.reply_all")
        end
        expect(page).to have_css(".webmail-mail-form-address.to", text: user2.email)
        expect(page).to have_css(".webmail-mail-form-address.cc", text: user3.email)
        expect(page).to have_no_css(".webmail-mail-form-address.bcc", text: user4.email)
        within "form#item-form" do
          click_on I18n.t('ss.buttons.send')
        end

        expect(ActionMailer::Base.deliveries).to have(2).items
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq address
          expect(mail.to.first).to eq user2.email
          expect(mail.cc.first).to eq user3.email
          expect(mail.bcc).to be_blank
        end
      end
    end

    shared_examples "webmail/mails account and group flow" do
      before do
        @save = SS.config.webmail.store_mails
        SS.config.replace_value_at(:webmail, :store_mails, store_mails)
      end

      after do
        SS.config.replace_value_at(:webmail, :store_mails, @save)
      end

      describe "webmail_mode is account" do
        let(:index_path) { webmail_mails_path(account: 0) }
        let(:address) { user.email }

        it_behaves_like "webmail/mails send with bcc flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails send with bcc flow"
      end
    end

    context "when store_mails is false" do
      let(:store_mails) { false }

      it_behaves_like "webmail/mails account and group flow"
    end

    context "when store_mails is true" do
      let(:store_mails) { true }

      it_behaves_like "webmail/mails account and group flow"
    end
  end
end

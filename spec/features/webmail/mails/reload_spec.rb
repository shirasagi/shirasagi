require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when mail is reloaded" do
    let(:user) { webmail_imap }
    let(:item_from) { "from-#{unique_id}@example.jp" }
    let(:item_tos) { Array.new(rand(1..10)) { "to-#{unique_id}@example.jp" } }
    let(:item_ccs) { Array.new(rand(1..10)) { "cc-#{unique_id}@example.jp" } }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails reload flow" do
      let(:item) do
        Mail.new(from: item_from, to: item_tos + [ address ], cc: item_ccs, subject: item_subject, body: item_texts.join("\n"))
      end

      before do
        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        visit index_path
        expect { Webmail::Mail.find_by(subject: item_subject) }.to raise_error Mongoid::Errors::DocumentNotFound

        webmail_import_mail(user, item)

        # reload mails
        first(".webmail-navi-mailboxes .reload").click
        # visit index_path
        expect(page).to have_css(".webmail-mails", text: item_subject)

        expect { Webmail::Mail.find_by(subject: item_subject) }.not_to raise_error
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

        it_behaves_like 'webmail/mails reload flow'
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like 'webmail/mails reload flow'
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

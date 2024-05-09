require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true do
  context "when mail is deleted" do
    let(:user) { webmail_imap }
    let(:item_from) { "from-#{unique_id}@example.jp" }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails delete flow" do
      let(:item) { Mail.new(from: item_from, to: address, subject: item_subject, body: item_texts.join("\n")) }

      before do
        webmail_import_mail(user, item)
        Webmail.imap_pool.disconnect_all

        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        # delete
        visit index_path
        expect { Webmail::Mail.find_by(subject: item_subject) }.not_to raise_error

        click_on item_subject
        click_on I18n.t('ss.links.delete')
        click_on I18n.t('ss.buttons.delete')
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

        expect { Webmail::Mail.find_by(subject: item_subject) }.to raise_error Mongoid::Errors::DocumentNotFound
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

        it_behaves_like 'webmail/mails delete flow'
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like 'webmail/mails delete flow'
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

require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true do
  context "when inlined content disposition is given" do
    let(:user) { webmail_imap }
    let(:item) do
      mail = Mail.read(Rails.root.join("spec/fixtures/webmail/inlined_content_disposition.eml"))
      mail.subject = "#{mail.subject} - #{unique_id}"
      mail
    end

    shared_examples "webmail/mails inlined content-disposition flow" do
      before do
        webmail_import_mail(user, item)

        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        visit index_path
        click_on item.subject
        expect(page).to have_css("#addon-basic .body--text", text: "test")
        expect(page).to have_css("#mail-attachments .file", text: "テストあいう.txt")
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

        it_behaves_like "webmail/mails inlined content-disposition flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails inlined content-disposition flow"
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

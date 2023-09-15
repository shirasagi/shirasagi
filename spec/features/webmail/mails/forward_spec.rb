require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when mail is forwarded" do
    let(:user) { webmail_imap }
    let(:item_from) { "from-#{unique_id}@example.jp" }
    let(:item_tos) { Array.new(rand(1..10)) { "to-#{unique_id}@example.jp" } }
    let(:item_ccs) { Array.new(rand(1..10)) { "cc-#{unique_id}@example.jp" } }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails forward flow" do
      let(:item) do
        Mail.new(from: item_from, to: item_tos + [ address ], cc: item_ccs, subject: item_subject, body: item_texts.join("\n"))
      end

      before do
        webmail_import_mail(user, item)

        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        # forward
        visit index_path
        wait_for_js_ready
        click_link item_subject
        wait_for_js_ready
        new_window = window_opened_by { click_link I18n.t('webmail.links.forward') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "to", with: user.email + "\n"
          end
          click_button I18n.t('ss.buttons.send')
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq address
          expect(mail.to).to have(1).items
          expect(mail.to.first).to eq user.email
          expect(mail.cc).to be_nil
          expect(mail.subject).to eq "Fw: #{item_subject}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.map { |t| "> #{t}" }.join("\r\n"))
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

        it_behaves_like "webmail/mails forward flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails forward flow"
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

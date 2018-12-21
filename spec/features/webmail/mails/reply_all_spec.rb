require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true do
  context "when mail is replied to all" do
    let(:user) { webmail_imap }
    let(:item_from) { "from-#{unique_id}@example.jp" }
    let(:item_tos) { Array.new(rand(1..10)) { "to-#{unique_id}@example.jp" } }
    let(:item_ccs) { Array.new(rand(1..10)) { "cc-#{unique_id}@example.jp" } }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails replay_all flow" do
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

      it "#show" do
        # reply_all
        visit index_path
        click_link item_subject
        click_link I18n.t('webmail.links.reply_all')
        within "form#item-form" do
          fill_in "to", with: user.email + "\n"
        end
        click_button I18n.t('ss.buttons.send')

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq address
          # to には、1) 受信メールの差出人, 2) 受信メールの宛先全員、3) ただし自分を除く、これらが設定されている
          expect(mail.to).to have(item_tos.length + 1).items
          expect(mail.to).to include(item_from)
          expect(mail.to).to include(*item_tos)
          expect(mail.to).not_to include(address)
          expect(mail.cc).to have(item_ccs.length).items
          expect(mail.cc).to include(*item_ccs)
          expect(mail.subject).to eq "Re: #{item_subject}"
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

        it_behaves_like 'webmail/mails replay_all flow'
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like 'webmail/mails replay_all flow'
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

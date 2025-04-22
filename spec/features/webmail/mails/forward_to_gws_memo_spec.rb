require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when mail is forwarded to gws/memo" do
    let!(:user) do
      gws_site
      gws_user

      webmail_imap
    end
    let(:item_from) { "from-#{unique_id}@example.jp" }
    let(:item_tos) { Array.new(rand(1..10)) { "to-#{unique_id}@example.jp" } }
    let(:item_ccs) { Array.new(rand(1..10)) { "cc-#{unique_id}@example.jp" } }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    shared_examples "webmail/mails forward to gws/memo flow" do
      let(:attachment1_name) { "logo-#{unique_id}.png" }
      let(:attachment2_name) { "shirasagi-#{unique_id}.pdf" }
      let(:item) do
        Mail.new do |m|
          m.from = item_from
          m.to = item_tos + [ address ]
          m.cc = item_ccs
          m.subject = item_subject
          m.body = item_texts.join("\n")
          m.add_file(filename: attachment1_name, content: File.binread("#{Rails.root}/spec/fixtures/ss/logo.png"))
          m.add_file(filename: attachment2_name, content: File.binread("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"))
        end
      end

      before do
        webmail_import_mail(user, item)
        Webmail.imap_pool.disconnect_all

        ActionMailer::Base.deliveries.clear
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        # forward to gws/memo
        login_user(user, to: index_path)
        wait_for_js_ready
        click_link item_subject
        wait_for_js_ready
        new_window = window_opened_by { click_link I18n.t('webmail.links.forward_gws_message') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            wait_for_cbox_opened { click_on I18n.t("gws.organization_addresses") }
          end
          within_cbox do
            wait_for_cbox_closed { click_on gws_user.name }
          end
          page.accept_confirm I18n.t("ss.confirm.send") do
            within "form#item-form" do
              expect(page).to have_css("[data-id='#{gws_user.id}']", text: gws_user.name)
              click_on I18n.t('ss.buttons.send')
            end
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |memo_message|
          expect(memo_message.site_id).to eq gws_site.id
          expect(memo_message.user_id).to eq user.id
          expect(memo_message.subject).to eq item_subject
          expect(memo_message.text).to eq item_texts.join("\r\n")
          expect(memo_message.user_settings).to have(1).items
          expect(memo_message.user_settings).to include({ 'user_id' => gws_user.id, 'path' => 'INBOX' })
          expect(memo_message.to_member_name).to eq gws_user.long_name
          expect(memo_message.from_member_name).to eq user.long_name
          expect(memo_message.member_ids).to eq [ gws_user.id ]
          expect(memo_message.to_member_ids).to eq [ gws_user.id ]
          expect(memo_message.cc_member_ids).to be_blank
          expect(memo_message.bcc_member_ids).to be_blank
          expect(memo_message.to_webmail_address_group_ids).to be_blank
          expect(memo_message.cc_webmail_address_group_ids).to be_blank
          expect(memo_message.bcc_webmail_address_group_ids).to be_blank
          expect(memo_message.to_shared_address_group_ids).to be_blank
          expect(memo_message.cc_shared_address_group_ids).to be_blank
          expect(memo_message.bcc_shared_address_group_ids).to be_blank
          expect(memo_message.files.count).to eq 2
          memo_message.files.where(name: attachment1_name).first.tap do |file|
            expect(file.user_id).to eq user.id
            expect(file.filename).to eq attachment1_name
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
            expect(file.owner_item_id).to eq memo_message.id
            expect(file.owner_item_type).to eq memo_message.class.name
          end
          memo_message.files.where(name: attachment2_name).first.tap do |file|
            expect(file.user_id).to eq user.id
            expect(file.filename).to eq attachment2_name
            expect(file.content_type).to eq "application/pdf"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
            expect(file.owner_item_id).to eq memo_message.id
            expect(file.owner_item_type).to eq memo_message.class.name
          end
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

        it_behaves_like "webmail/mails forward to gws/memo flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails forward to gws/memo flow"
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

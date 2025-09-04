require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when mail is sent with new file" do
    let(:user) { webmail_imap }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }
    let(:content) { Rails.root.join("spec/fixtures/ss/shirasagi.pdf") }

    shared_examples "webmail/mails send with new file flow" do
      before do
        @save_file_upload_dialog = SS.file_upload_dialog
        SS.file_upload_dialog = :v2

        ActionMailer::Base.deliveries.clear
      end

      after do
        SS.file_upload_dialog = @save_file_upload_dialog

        ActionMailer::Base.deliveries.clear
      end

      it do
        # send
        login_user user, to: index_path
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "to", with: user.email + "\n"
            fill_in "item[subject]", with: item_subject
            fill_in "item[text]", with: item_texts.join("\n")

            ss_upload_file content, addon: "#addon-webmail-agents-addons-mail_file"

            expect(page).to have_css(".file-view", text: File.basename(content))
          end
        end

        # 中間ファイルが作成されているはず
        expect(SS::File.unscoped.count).to eq 1
        intermediate_file = SS::File.unscoped.first
        expect(intermediate_file.name).to eq File.basename(content)
        expect(intermediate_file.filename).to eq File.basename(content)
        expect(intermediate_file.content_type).to eq "application/pdf"
        expect(intermediate_file.size).to eq File.size(content)
        expect(intermediate_file.model).to eq "ss/temp_file"
        expect(intermediate_file.site_id).to be_blank
        expect(intermediate_file.user_id).to eq user.id
        expect(intermediate_file.owner_item_id).to be_blank
        expect(intermediate_file.owner_item_type).to be_blank

        within_window new_window do
          within "form#item-form" do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq address
          expect(mail.to.first).to eq user.email
          expect(mail_subject(mail)).to eq item_subject
          expect(mail.multipart?).to be_truthy
          expect(mail.content_type).to include("multipart/mixed")
          expect(mail.parts.length).to eq 2
          expect(mail.parts[0].body.raw_source).to include(item_texts.join("\r\n"))
          expect(mail.parts[1].content_type).to eq "application/pdf; filename=#{File.basename(content)}"
        end

        # 送信後、中間ファイルは削除されているはず。
        expect { intermediate_file.reload }.to raise_error Mongoid::Errors::DocumentNotFound
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

        it_behaves_like "webmail/mails send with new file flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails send with new file flow"
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

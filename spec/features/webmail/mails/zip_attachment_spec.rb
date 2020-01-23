require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when a zip file is attached" do
    let(:user) { webmail_imap }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }
    let(:content) { Rails.root.join("spec/fixtures/webmail/mail-2.zip") }
    let!(:file) do
      tmp_ss_file(contents: content, user: user, content_type: "application/zip")
    end

    shared_examples "a zip file is attached flow" do
      before do
        ActionMailer::Base.deliveries.clear
        login_user(user)

        file.name = "#{unique_id}.zip"
        file.filename = file.name
        file.save!
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        # send
        visit index_path
        click_link I18n.t('ss.links.new')
        within "form#item-form" do
          fill_in "to", with: user.email + "\n"
          fill_in "item[subject]", with: item_subject
          fill_in "item[text]", with: item_texts.join("\n")

          click_on I18n.t("ss.links.upload")
        end
        wait_for_cbox do
          click_on file.name
        end
        within "form#item-form" do
          click_on I18n.t('ss.buttons.send')
        end

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq address
          expect(mail.to.first).to eq user.email
          expect(mail.subject).to eq item_subject
          expect(mail.multipart?).to be_truthy
          expect(mail.parts.length).to eq 2
          expect(mail.parts[0].body.raw_source).to include(item_texts.join("\r\n"))
          expect(mail.parts[1].content_type).to include("application/zip")
          expect(mail.parts[1].content_type).to include(file.filename)
          expect(mail.parts[1].content_transfer_encoding).to eq "base64"
          expect(mail.parts[1].content_disposition).to include("attachment")
          expect(mail.parts[1].content_disposition).to include(file.filename)
          expect(mail.parts[1].body.raw_source).to eq Base64.encode64(::File.binread(content))
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

        it_behaves_like "a zip file is attached flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
        let(:address) { group.contact_email }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "a zip file is attached flow"
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

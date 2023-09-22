require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when html mail is given" do
    let(:user) { webmail_imap }
    let(:item) do
      mail = Mail.read(Rails.root.join("spec/fixtures/webmail/mail-3.eml"))
      mail.subject = "#{mail.subject} - #{unique_id}"
      mail
    end

    shared_examples "webmail/mails html mail flow" do
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
        wait_for_js_ready
        click_on item.subject
        wait_for_js_ready
        expect(page).to have_css("#addon-basic .body--html", text: "test")

        new_window = window_opened_by do
          within first(".nav-menu .dropdown") do
            # click_on I18n.t("ss.links.reply")
            first("a").click
            # click_on I18n.t("ss.links.reply")
            first("li").click
          end
        end
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            click_on I18n.t("ss.buttons.send")
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.subject).to eq "Re: #{item.subject}"
          expect(mail.content_type).to include("text/html")
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include("<b>test</b>")
        end

        visit index_path
        wait_for_js_ready
        click_on item.subject
        wait_for_js_ready

        new_window = window_opened_by { click_on I18n.t("webmail.links.forward") }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "to", with: user.email + "\n"
            click_on I18n.t("ss.buttons.send")
          end
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.sent"))

        expect(ActionMailer::Base.deliveries).to have(2).items
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.subject).to eq "Fw: #{item.subject}"
          expect(mail.content_type).to include("text/html")
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include("<b>test</b>")
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

        it_behaves_like "webmail/mails html mail flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails html mail flow"
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

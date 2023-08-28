require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "when all email fields are blank" do
    let(:user) { webmail_imap }
    let(:msg) { File.read(Rails.root.join("spec/fixtures/webmail/all_fields_blank.eml")) }

    shared_examples "webmail/mails all email fields are blank flow" do
      before do
        webmail_import_mail(user, msg)

        ActionMailer::Base.deliveries.clear
        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        visit index_path
        wait_for_js_ready
        first("li.list-item").click
        wait_for_js_ready
        expect(page).to have_css("#addon-basic .subject", text: I18n.t("webmail.no_subjects"))
        expect(page).to have_css("#addon-basic .body--text", text: "message-47ma7vziwcu")

        click_on I18n.t("ss.links.delete")
        wait_for_js_ready
        expect(page).to have_css("#addon-basic", text: I18n.t("webmail.no_subjects"))
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

        it_behaves_like "webmail/mails all email fields are blank flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails all email fields are blank flow"
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

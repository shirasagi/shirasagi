require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "mail with space separated address with DN" do
    let(:user) { webmail_imap }
    let(:msg) { File.read(Rails.root.join("spec/fixtures/webmail/space-separated-address-with-dn.eml")) }

    shared_examples "webmail/mails with space separated address with DN flow" do
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
        first("li.list-item").click
        expect(page).to have_css("#addon-basic .subject", text: "たちつてと")
        expect(page).to have_css("#addon-basic .body--text", text: "なにぬねの")
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

        it_behaves_like "webmail/mails with space separated address with DN flow"
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like "webmail/mails with space separated address with DN flow"
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

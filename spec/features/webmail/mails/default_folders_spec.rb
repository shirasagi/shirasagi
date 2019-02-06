require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "confirms that there are default folders" do
    let(:user) { webmail_imap }

    shared_examples "webmail mails flow" do
      context "with auth" do
        before do
          ActionMailer::Base.deliveries.clear
          login_user(user)
        end

        after do
          ActionMailer::Base.deliveries.clear
        end

        it "#index" do
          visit index_path

          find(".webmail-navi-mailboxes .inbox-sent").click
          find(".webmail-navi-mailboxes .inbox-draft").click
          find(".webmail-navi-mailboxes .inbox-trash").click
          find(".webmail-navi-mailboxes .reload").click
          find(".webmail-navi-quota .reload").click
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

        it_behaves_like 'webmail mails flow'
      end

      describe "webmail_mode is group" do
        let(:group) { create :webmail_group }
        let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

        before { user.add_to_set(group_ids: [ group.id ]) }

        it_behaves_like 'webmail mails flow'
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

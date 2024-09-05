require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  context "confirms that there are default folders" do
    let(:user) { webmail_imap }

    shared_examples "webmail mails flow" do
      context do
        before do
          ActionMailer::Base.deliveries.clear
          login_user(user)
        end

        after do
          ActionMailer::Base.deliveries.clear
        end

        it do
          visit index_path

          find(".webmail-navi-mailboxes .inbox-sent").click
          expect(page).to have_css(".webmail-navi-mailboxes .inbox-sent.current", text: I18n.t("webmail.box.sent"))

          find(".webmail-navi-mailboxes .inbox-draft").click
          expect(page).to have_css(".webmail-navi-mailboxes .inbox-draft.current", text: I18n.t("webmail.box.draft"))

          find(".webmail-navi-mailboxes .inbox-trash").click
          expect(page).to have_css(".webmail-navi-mailboxes .inbox-trash.current", text: I18n.t("webmail.box.trash"))

          find(".webmail-navi-mailboxes .reload").click
          wait_for_notice I18n.t("webmail.notice.no_recent_mail")

          find(".webmail-navi-quota .reload").click
          quota_label = "#{0.to_fs(:human_size)}/#{(10 * 1_024 * 1_024).to_fs(:human_size)}"
          expect(page).to have_css(".webmail-navi-quota .ss-quota-bar .label", text: quota_label)
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

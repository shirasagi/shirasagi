require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:draft_path) { webmail_mails_path(account: 0, mailbox: "INBOX.Draft") }
  let(:sent_path) { webmail_mails_path(account: 0, mailbox: "INBOX.Sent") }

  let(:draft_subject) { "subject-#{unique_id}" }
  let(:item_subject) { "subject-#{unique_id}" }

  before do
    @save_webmail_auto_save = SS.config.webmail.auto_save
    # keep_interval を 0 にすると、定期送信を実行しない
    SS.config.replace_value_at(:webmail, :auto_save, { first_interval: 0, keep_interval: 0 })
  end

  after do
    SS.config.replace_value_at(:webmail, :auto_save, @save_webmail_auto_save)
  end

  context "auto save when editing a draft message" do
    before do
      login_user(user)
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    context "send" do
      it do
        # save draft
        visit draft_path

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "item[subject]", with: draft_subject
          end
          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        # edit
        visit draft_path
        click_on draft_subject

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.edit') }

        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready

          click_on I18n.t("webmail.links.show_cc_bcc")
          expect(page).to have_css("#cc")
          expect(page).to have_css("#bcc")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "temporary"

          within "form#item-form" do
            fill_in "to", with: user.email
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          within "form#item-form" do
            fill_in "item[subject]", with: item_subject
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          click_on I18n.t('ss.buttons.send')
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "discarded"

        visit draft_path
        expect(Webmail::AutoSave.count).to eq 0

        expect(page).to have_selector(".list-item", count: 0)
        expect(page).to have_no_css(".icon-auto-save")
        expect(page).to have_no_link(item_subject)

        visit sent_path
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_no_css(".icon-auto-save")
        expect(page).to have_link(item_subject)
        click_on item_subject
        expect(page).to have_text(user.email)
      end
    end

    context "save draft" do
      it do
        # save draft
        visit draft_path

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "item[subject]", with: draft_subject
          end
          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        # edit
        visit draft_path
        click_on draft_subject

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.edit') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready

          click_on I18n.t("webmail.links.show_cc_bcc")
          expect(page).to have_css("#cc")
          expect(page).to have_css("#bcc")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "temporary"

          within "form#item-form" do
            fill_in "to", with: user.email
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          within "form#item-form" do
            fill_in "item[subject]", with: item_subject
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "discarded"

        visit draft_path
        expect(Webmail::AutoSave.count).to eq 0

        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_no_css(".icon-auto-save")
        expect(page).to have_link(item_subject)
        click_on item_subject
        expect(page).to have_text(user.email)

        visit sent_path
        expect(page).to have_selector(".list-item", count: 0)
        expect(page).to have_no_css(".icon-auto-save")
        expect(page).to have_no_link(item_subject)
      end
    end

    context "close window" do
      it do
        # save draft
        visit draft_path

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "item[subject]", with: draft_subject
          end
          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        # edit
        visit draft_path
        click_on draft_subject

        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.edit') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready

          click_on I18n.t("webmail.links.show_cc_bcc")
          expect(page).to have_css("#cc")
          expect(page).to have_css("#bcc")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "temporary"

          within "form#item-form" do
            fill_in "to", with: user.email
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          within "form#item-form" do
            fill_in "item[subject]", with: item_subject
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"

          page.driver.browser.close
        end

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "ready"

        visit draft_path
        expect(Webmail::AutoSave.count).to eq 0

        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".icon-auto-save")
        expect(page).to have_link(draft_subject)
        expect(page).to have_link(item_subject)
        click_on item_subject
        expect(page).to have_text(user.email)

        visit sent_path
        expect(page).to have_selector(".list-item", count: 0)
        expect(page).to have_no_css(".icon-auto-save")
        expect(page).to have_no_link(item_subject)
      end
    end
  end
end

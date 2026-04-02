require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let!(:user) { webmail_imap }
  let!(:draft_path) { webmail_mails_path(account: 0, mailbox: "INBOX.Draft") }

  let!(:draft_subject) { "subject-#{unique_id}" }
  let!(:draft_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", user: user) }

  let!(:item_email1) { "#{unique_id}@example.jp" }
  let!(:item_email2) { "#{unique_id}@example.jp" }
  let!(:item_email3) { "#{unique_id}@example.jp" }
  let!(:item_subject) { "subject-#{unique_id}" }
  let!(:item_text) { "message-#{unique_id}" }
  let!(:item_link) { "http://sample.example.jp" }
  let!(:item_html) { "<p><a href=\"#{item_link}\">#{item_link}</a></p>" }
  let!(:item_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user) }

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

    context "edit text mail" do
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
            ss_select_file draft_file, addon: "#addon-webmail-agents-addons-mail_file"
          end
          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

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

          # auto save "to"
          within "form#item-form" do
            fill_in "to", with: item_email1
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to be_blank
          expect(auto_save.bcc).to be_blank
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "cc"
          within "form#item-form" do
            fill_in "cc", with: item_email2
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to be_blank
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "bcc"
          within "form#item-form" do
            fill_in "bcc", with: item_email3
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"2\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "subject"
          within "form#item-form" do
            fill_in "item[subject]", with: item_subject
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"3\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "text"
          within "form#item-form" do
            fill_in "item[text]", with: item_text
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"4\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to eq item_text
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "file_ids"
          ss_select_file item_file, addon: "#addon-webmail-agents-addons-mail_file"
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"5\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "text"
          expect(auto_save.text).to eq item_text
          expect(auto_save.file_ids).to eq [item_file.id]
          expect(auto_save.draft_ref_file_ids).to be_present

          page.driver.browser.close
        end

        visit draft_path
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".icon-auto-save")
        click_on item_subject

        within "#addon-basic" do
          expect(page).to have_text(item_subject)
          expect(page).to have_text(item_email1)
          expect(page).to have_text(item_email2)
          expect(page).to have_text(item_email3)
          expect(page).to have_text(item_text)
          expect(page).to have_link(item_file.filename)
          expect(page).to have_link(draft_file.filename)
        end
        expect(Webmail::AutoSave.count).to eq 0
      end
    end

    context "edit html mail" do
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
            ss_select_file draft_file, addon: "#addon-webmail-agents-addons-mail_file"
          end
          click_on I18n.t('ss.buttons.draft_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

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

          # auto save "to"
          within "form#item-form" do
            fill_in "to", with: item_email1
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to be_blank
          expect(auto_save.bcc).to be_blank
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.html).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "cc"
          within "form#item-form" do
            fill_in "cc", with: item_email2
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to be_blank
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.html).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "bcc"
          within "form#item-form" do
            fill_in "bcc", with: item_email3
            fill_in "item[subject]", with: ""
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"2\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to be_blank
          expect(auto_save.format).to eq "text"
          expect(auto_save.html).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "subject"
          within "form#item-form" do
            fill_in "item[subject]", with: item_subject
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"3\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "text"
          expect(auto_save.html).to be_blank
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "html"
          within "form#item-form" do
            select "HTML", from: "item[format]"
            wait_for_ckeditor_ready find(:fillable_field, "item[html]")
            fill_in_ckeditor "item[html]", with: item_html
          end
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"4\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "html"
          expect(auto_save.html).to eq item_html
          expect(auto_save.file_ids).to be_blank
          expect(auto_save.draft_ref_file_ids).to be_present

          # auto save "file_ids"
          ss_select_file item_file, addon: "#addon-webmail-agents-addons-mail_file"
          page.execute_script("window.WEBMAIL_AutoSave();")
          expect(page).to have_css(".webmail-auto-save-notice[data-count=\"5\"]")

          expect(Webmail::AutoSave.count).to eq 1
          auto_save = Webmail::AutoSave.first
          expect(auto_save.state).to eq "ready"
          expect(auto_save.draft_uid).to be_present
          expect(auto_save.to).to eq [item_email1]
          expect(auto_save.cc).to eq [item_email2]
          expect(auto_save.bcc).to eq [item_email3]
          expect(auto_save.subject).to eq item_subject
          expect(auto_save.format).to eq "html"
          expect(auto_save.html).to eq item_html
          expect(auto_save.file_ids).to eq [item_file.id]
          expect(auto_save.draft_ref_file_ids).to be_present

          page.driver.browser.close
        end

        visit draft_path
        expect(page).to have_selector(".list-item", count: 2)
        expect(page).to have_css(".icon-auto-save")
        click_on item_subject

        within "#addon-basic" do
          expect(page).to have_text(item_subject)
          expect(page).to have_text(item_email1)
          expect(page).to have_text(item_email2)
          expect(page).to have_text(item_email3)
          expect(page).to have_link(item_link)
          expect(page).to have_link(item_file.filename)
          expect(page).to have_link(draft_file.filename)
        end
        expect(Webmail::AutoSave.count).to eq 0
      end
    end
  end
end

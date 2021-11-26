require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  describe "when all recipients is removed" do
    let(:index_path) { webmail_mails_path(account: 0) }

    let(:user) { webmail_imap }
    let(:user2) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:user3) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:user4) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:item_subject) { "subject-#{unique_id}" }
    let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

    before do
      ActionMailer::Base.deliveries.clear
      login_user(user)
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    context "within to" do
      it do
        visit index_path
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            fill_in "to", with: user2.email + "\n"
            fill_in "to", with: user3.email + "\n"
            fill_in "to", with: user4.email + "\n"
            fill_in "item[subject]", with: item_subject
            fill_in "item[text]", with: item_texts.join("\n")

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_css(".address-field", text: user2.email)
        expect(page).to have_css(".address-field", text: user3.email)
        expect(page).to have_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)

        # remove all addresses within to
        new_window = window_opened_by { click_on I18n.t("ss.links.edit") }
        within_window new_window do
          within "form#item-form" do
            within "dl.webmail-mail-form-address.to" do
              3.times do
                first(".deselect").click
              end
            end

            expect(page).to have_no_css(".address-field", text: user2.email)
            expect(page).to have_no_css(".address-field", text: user3.email)
            expect(page).to have_no_css(".address-field", text: user4.email)

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_no_css(".address-field", text: user2.email)
        expect(page).to have_no_css(".address-field", text: user3.email)
        expect(page).to have_no_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)
      end
    end

    context "within cc" do
      it do
        visit index_path
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")

            fill_in "cc", with: user2.email + "\n"
            fill_in "cc", with: user3.email + "\n"
            fill_in "cc", with: user4.email + "\n"
            fill_in "item[subject]", with: item_subject
            fill_in "item[text]", with: item_texts.join("\n")

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_css(".address-field", text: user2.email)
        expect(page).to have_css(".address-field", text: user3.email)
        expect(page).to have_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)

        # remove all addresses within to
        new_window = window_opened_by { click_on I18n.t("ss.links.edit") }
        within_window new_window do
          within "form#item-form" do
            within "dl.webmail-mail-form-address.cc" do
              3.times do
                first(".deselect").click
              end
            end

            expect(page).to have_no_css(".address-field", text: user2.email)
            expect(page).to have_no_css(".address-field", text: user3.email)
            expect(page).to have_no_css(".address-field", text: user4.email)

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_no_css(".address-field", text: user2.email)
        expect(page).to have_no_css(".address-field", text: user3.email)
        expect(page).to have_no_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)
      end
    end

    context "within bcc" do
      it do
        visit index_path
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          within "form#item-form" do
            click_on I18n.t("webmail.links.show_cc_bcc")

            fill_in "bcc", with: user2.email + "\n"
            fill_in "bcc", with: user3.email + "\n"
            fill_in "bcc", with: user4.email + "\n"
            fill_in "item[subject]", with: item_subject
            fill_in "item[text]", with: item_texts.join("\n")

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_css(".address-field", text: user2.email)
        expect(page).to have_css(".address-field", text: user3.email)
        expect(page).to have_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)

        # remove all addresses within to
        new_window = window_opened_by { click_on I18n.t("ss.links.edit") }
        within_window new_window do
          within "form#item-form" do
            within "dl.webmail-mail-form-address.bcc" do
              3.times do
                first(".deselect").click
              end
            end

            expect(page).to have_no_css(".address-field", text: user2.email)
            expect(page).to have_no_css(".address-field", text: user3.email)
            expect(page).to have_no_css(".address-field", text: user4.email)

            click_on I18n.t('ss.buttons.draft_save')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        within ".webmail-navi-mailboxes" do
          click_on I18n.t("webmail.box.draft")
        end
        click_on item_subject
        expect(page).to have_no_css(".address-field", text: user2.email)
        expect(page).to have_no_css(".address-field", text: user3.email)
        expect(page).to have_no_css(".address-field", text: user4.email)
        expect(page).to have_css(".body--text", text: item_texts.first)
      end
    end
  end
end
